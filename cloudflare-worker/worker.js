export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const parts = url.pathname.split('/').filter(Boolean);

    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Store-Secret',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: cors });
    }

    // ===== صفحة إعادة التوجيه لروابط المشاركة (طلبية / متجر) =====
    // نستخدم نطاق هذا الـ Worker بدل صفحات GitHub Pages الشخصية حتى لا
    // يظهر اسم حساب GitHub لأي زبون أو تاجر يفتح الرابط. الصفحة تقرأ
    // الجزء بعد # في المتصفح (لا يصل هذا الجزء للخادم إطلاقًا، يبقى في
    // المتصفح فقط) وتحاول فتح التطبيق عبر مخطط الرابط الداخلي atmina://.
    if (url.pathname === '/l') {
      return new Response(REDIRECT_PAGE_HTML, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    // ===== قائمة كل المتاجر التي حدّدت موقعها الجغرافي =====
    // تُستخدم من شاشة "المتاجر القريبة" عند الزبون لعرض كل المتاجر على
    // خريطة واحدة. لا تُرجع أي بيانات حساسة (لا سر، ولا قائمة منتجات
    // كاملة) بل فقط الحد الأدنى اللازم لرسم علامة على الخريطة.
    if (url.pathname === '/stores' && request.method === 'GET') {
      return handleStoresListRequest(env, cors);
    }

    // ===== البحث الشامل عن منتج عبر كل المتاجر =====
    // يستخدمه الزبون لمعرفة أي حانوت يوفر منتجًا معيّنًا، دون الحاجة
    // لتصفح كل متجر على حدة.
    if (url.pathname === '/search' && request.method === 'GET') {
      const q = (url.searchParams.get('q') || '').trim();
      return handleProductSearchRequest(env, cors, q);
    }

    if (parts[0] !== 'store' || !parts[1]) {
      return new Response(JSON.stringify({ error: 'not_found' }), {
        status: 404,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const code = parts[1];

    // ===== مسارات صور عائلات المنتجات: /store/{code}/images/{familyId} =====
    if (parts[2] === 'images' && parts[3]) {
      return handleImageRequest(request, env, cors, code, parts[3]);
    }

    // ===== مسارات بيانات المتجر (الكتالوج) كما كانت =====
    if (request.method === 'GET') {
      const raw = await env.STORES.get(code);
      if (!raw) {
        return new Response(JSON.stringify({ error: 'not_found' }), {
          status: 404,
          headers: { ...cors, 'Content-Type': 'application/json' },
        });
      }
      const data = JSON.parse(raw);
      delete data.secret;
      return new Response(JSON.stringify(data), {
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    if (request.method === 'PUT') {
      const providedSecret = request.headers.get('X-Store-Secret') || '';
      const existingRaw = await env.STORES.get(code);

      if (existingRaw) {
        const existing = JSON.parse(existingRaw);
        if (existing.secret && existing.secret !== providedSecret) {
          return new Response(JSON.stringify({ error: 'forbidden' }), {
            status: 403,
            headers: { ...cors, 'Content-Type': 'application/json' },
          });
        }
      }

      let body;
      try {
        body = await request.json();
      } catch (e) {
        return new Response(JSON.stringify({ error: 'invalid_body' }), {
          status: 400,
          headers: { ...cors, 'Content-Type': 'application/json' },
        });
      }

      body.secret = providedSecret;
      await env.STORES.put(code, JSON.stringify(body));

      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'method_not_allowed' }), {
      status: 405,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  },
};

/// يجمع قائمة مختصرة (الاسم + الإحداثيات + الرمز) لكل متجر سبق أن حدّد
/// موقعه الجغرافي، لعرضها دفعة واحدة على خريطة الزبون. نتجاهل مفاتيح
/// الصور (img:...) ونتجاهل أي متجر لم يسجّل إحداثيات بعد.
async function handleStoresListRequest(env, cors) {
  const stores = [];
  let cursor;
  let page;
  do {
    page = await env.STORES.list({ cursor });
    cursor = page.cursor;
    for (const key of page.keys) {
      if (key.name.startsWith('img:')) continue;
      try {
        const raw = await env.STORES.get(key.name);
        if (!raw) continue;
        const data = JSON.parse(raw);
        if (typeof data.latitude === 'number' && typeof data.longitude === 'number') {
          stores.push({
            store_code: data.store_code || key.name,
            store_name: data.store_name || '',
            latitude: data.latitude,
            longitude: data.longitude,
          });
        }
      } catch (e) {
        // نتجاهل أي إدخال تالف بدل فشل الطلب بالكامل
      }
    }
  } while (!page.list_complete && cursor);

  return new Response(JSON.stringify({ stores }), {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

/// يبحث عن كلمة q ضمن أسماء المنتجات في كل المتاجر المنشورة، ويعيد قائمة
/// بأول 40 نتيجة مطابقة مع بيانات الحانوت المختصرة (الاسم والإحداثيات)
/// حتى يمكن للزبون معرفة أي حانوت يوفر المنتج وترتيبه حسب القرب.
async function handleProductSearchRequest(env, cors, query) {
  if (!query || query.length < 2) {
    return new Response(JSON.stringify({ results: [] }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
  const needle = query.toLocaleLowerCase();
  const results = [];
  let cursor;
  let page;
  do {
    page = await env.STORES.list({ cursor });
    cursor = page.cursor;
    for (const key of page.keys) {
      if (key.name.startsWith('img:')) continue;
      if (results.length >= 40) break;
      try {
        const raw = await env.STORES.get(key.name);
        if (!raw) continue;
        const data = JSON.parse(raw);
        const items = Array.isArray(data.items) ? data.items : [];
        for (const item of items) {
          if (results.length >= 40) break;
          const name = (item.name || '').toLocaleLowerCase();
          if (name.includes(needle)) {
            results.push({
              store_code: data.store_code || key.name,
              store_name: data.store_name || '',
              latitude: typeof data.latitude === 'number' ? data.latitude : null,
              longitude: typeof data.longitude === 'number' ? data.longitude : null,
              item_name: item.name,
              price: item.price,
              stock_quantity: item.stock_quantity,
              category: item.category,
            });
          }
        }
      } catch (e) {
        // نتجاهل أي إدخال تالف بدل فشل الطلب بالكامل
      }
    }
  } while (!page.list_complete && cursor && results.length < 40);

  return new Response(JSON.stringify({ results }), {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

/// يتحقق من أن السر المُرسل يطابق سر المتجر المسجّل، بنفس منطق
/// التحقق المستخدم أصلًا في PUT /store/{code}.
async function verifyStoreSecret(env, code, providedSecret) {
  const existingRaw = await env.STORES.get(code);
  if (!existingRaw) return false;
  const existing = JSON.parse(existingRaw);
  if (!existing.secret) return true; // متجر بلا سر مسجّل بعد (حالة نادرة)
  return existing.secret === providedSecret;
}

/// يعالج GET (عرض) / PUT (رفع) / DELETE (حذف) لصورة عائلة منتج واحدة.
/// الصور تُخزَّن كبايتات خام (وليس Base64) داخل نفس STORES namespace
/// تحت مفتاح منفصل بصيغة img:{code}:{familyId}، لتفادي إنشاء KV
/// namespace إضافي وللحفاظ على البساطة.
async function handleImageRequest(request, env, cors, code, familyId) {
  const imageKey = `img:${code}:${familyId}`;

  if (request.method === 'GET') {
    const stored = await env.STORES.get(imageKey, { type: 'arrayBuffer' });
    if (!stored) {
      return new Response(JSON.stringify({ error: 'not_found' }), {
        status: 404,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }
    return new Response(stored, {
      headers: {
        ...cors,
        'Content-Type': 'image/jpeg',
        'Cache-Control': 'public, max-age=604800',
      },
    });
  }

  if (request.method === 'PUT') {
    const providedSecret = request.headers.get('X-Store-Secret') || '';
    const authorized = await verifyStoreSecret(env, code, providedSecret);
    if (!authorized) {
      return new Response(JSON.stringify({ error: 'forbidden' }), {
        status: 403,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    let body;
    try {
      body = await request.json();
    } catch (e) {
      return new Response(JSON.stringify({ error: 'invalid_body' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const base64Image = body.image_base64;
    if (!base64Image || typeof base64Image !== 'string') {
      return new Response(JSON.stringify({ error: 'missing_image' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const binary = base64ToArrayBuffer(base64Image);
    // حد أقصى احترازي 2 ميغابايت لكل صورة (صورنا المضغوطة عادة أقل من 50 كيلوبايت).
    if (binary.byteLength > 2 * 1024 * 1024) {
      return new Response(JSON.stringify({ error: 'image_too_large' }), {
        status: 413,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    await env.STORES.put(imageKey, binary);

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }

  if (request.method === 'DELETE') {
    const providedSecret = request.headers.get('X-Store-Secret') || '';
    const authorized = await verifyStoreSecret(env, code, providedSecret);
    if (!authorized) {
      return new Response(JSON.stringify({ error: 'forbidden' }), {
        status: 403,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    await env.STORES.delete(imageKey);

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ error: 'method_not_allowed' }), {
    status: 405,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

function base64ToArrayBuffer(base64) {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

const REDIRECT_PAGE_HTML = `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>فتح في تطبيق Atmina</title>
<style>
  body { font-family: -apple-system, "Segoe UI", Roboto, sans-serif; background:#0B1F3A; color:#fff; display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; text-align:center; padding:24px; box-sizing:border-box; }
  .card { max-width:420px; }
  h1 { font-size:22px; margin-bottom:12px; }
  p { color:#c7d2e3; line-height:1.6; }
  a.btn { display:inline-block; margin-top:20px; background:#fff; color:#0B1F3A; padding:14px 28px; border-radius:14px; text-decoration:none; font-weight:700; }
</style>
</head>
<body>
  <div class="card">
    <h1>جارٍ فتح تطبيق Atmina...</h1>
    <p id="msg">إذا لم يفتح التطبيق تلقائيًا خلال ثوانٍ، اضغط الزر بالأسفل. تأكد أن تطبيق Atmina مثبّت على هاتفك.</p>
    <a class="btn" id="openBtn" href="#">فتح التطبيق الآن</a>
  </div>
<script>
  (function () {
    var hash = window.location.hash.replace('#', '');
    var slashIndex = hash.indexOf('/');
    var type = slashIndex === -1 ? '' : hash.substring(0, slashIndex);
    var payload = slashIndex === -1 ? '' : hash.substring(slashIndex + 1);
    var openBtn = document.getElementById('openBtn');
    var msg = document.getElementById('msg');
    if ((type === 'store' || type === 'order') && payload) {
      var target = 'atmina://' + type + '/' + payload;
      openBtn.href = target;
      window.location.href = target;
    } else {
      msg.textContent = 'الرابط غير صالح.';
      openBtn.style.display = 'none';
    }
  })();
</script>
</body>
</html>
`;
