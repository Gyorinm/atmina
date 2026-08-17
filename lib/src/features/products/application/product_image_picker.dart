import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// يلتقط/يختار صورة منتج، ثم يضغطها برمجيًا (تصغير الأبعاد + تقليل
/// جودة JPEG) قبل حفظها في مجلد التطبيق الدائم، ويعيد المسار المحلي
/// للصورة المضغوطة. يعيد null إذا ألغى المستخدم الاختيار.
///
/// الضغط يتم بالكامل بكود Dart (حزمة `image`) دون الاعتماد على أي
/// أداة نظام خارجية، فيعمل بشكل موثوق على كل الأجهزة.
class ProductImagePicker {
  ProductImagePicker._();

  /// أقصى عرض/ارتفاع للصورة الناتجة بالبكسل. كافٍ لعرض بطاقة منتج
  /// بوضوح جيد مع إبقاء حجم الملف صغيرًا جدًا (عادة أقل من 40 كيلوبايت).
  static const int _maxDimension = 480;

  /// جودة ضغط JPEG (0-100). كلما قلّت زاد الضغط وقلّ الحجم.
  static const int _jpegQuality = 70;

  static final ImagePicker _picker = ImagePicker();

  /// يعرض للمستخدم صورة من الكاميرا مباشرة.
  static Future<String?> pickFromCamera() => _pickAndCompress(ImageSource.camera);

  /// يعرض للمستخدم صورة من معرض الصور.
  static Future<String?> pickFromGallery() => _pickAndCompress(ImageSource.gallery);

  static Future<String?> _pickAndCompress(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90, // ضغط أولي خفيف من الملتقط نفسه؛ الضغط الحقيقي يتم لاحقًا يدويًا
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // تصغير الأبعاد مع الحفاظ على النسبة، فقط إذا كانت الصورة أكبر من الحد الأقصى.
    final img.Image resized = (decoded.width > _maxDimension || decoded.height > _maxDimension)
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? _maxDimension : null,
            height: decoded.height > decoded.width ? _maxDimension : null,
          )
        : decoded;

    final compressedBytes = img.encodeJpg(resized, quality: _jpegQuality);

    final directory = await getApplicationDocumentsDirectory();
    final productImagesDir = Directory(p.join(directory.path, 'product_images'));
    if (!await productImagesDir.exists()) {
      await productImagesDir.create(recursive: true);
    }

    final fileName = 'product_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outFile = File(p.join(productImagesDir.path, fileName));
    await outFile.writeAsBytes(compressedBytes, flush: true);

    return outFile.path;
  }

  /// يحذف ملف صورة منتج قديم من التخزين المحلي (عند تغيير الصورة أو حذف المنتج).
  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // تجاهل أخطاء الحذف؛ ليست حرجة.
    }
  }
}
