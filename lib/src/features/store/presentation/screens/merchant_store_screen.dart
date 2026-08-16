import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/share_links.dart';
import '../../../products/application/products_providers.dart';
import '../../application/store_api_service.dart';
import '../../application/store_profile_controller.dart';
import '../../application/store_service.dart';

class MerchantStoreScreen extends ConsumerStatefulWidget {
  const MerchantStoreScreen({super.key});

  @override
  ConsumerState<MerchantStoreScreen> createState() => _MerchantStoreScreenState();
}

class _MerchantStoreScreenState extends ConsumerState<MerchantStoreScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _whatsappController;
  bool _initialized = false;
  bool _publishing = false;
  DateTime? _lastPublishedAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _whatsappController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(storeProfileControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('متجري')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('تعذر تحميل بيانات المتجر: $error')),
        data: (profile) {
          if (!_initialized) {
            _nameController.text = profile.storeName;
            _whatsappController.text = profile.whatsappNumber;
            _initialized = true;
          }
          final link = ShareLinks.storeLink(profile.storeCode);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كود متجرك', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      SelectableText(
                        profile.storeCode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: profile.storeCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ كود المتجر')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('نسخ الكود'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'هذا الرمز والرابط ثابتان ولا يتغيران — اطلب من الزبون مسحه مرة واحدة فقط، وكل تحديث لاحق للمنتجات سيصله تلقائيًا.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(link, maxLines: 2, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: link));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ الرابط')),
                                );
                              },
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('نسخ الرابط'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(
                                  text: 'متجر ${profile.storeName.isEmpty ? profile.storeCode : profile.storeName} '
                                      'على Atmina\nتصفح المنتجات وأرسل طلبيتك من هنا:\n$link',
                                  title: 'رابط المتجر',
                                ),
                              ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('مشاركة'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المتجر (يظهر للزبون)'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم واتساب بصيغة دولية (مثال: 212612345678)',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _publishing ? null : () => _publish(profile),
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_publishing ? 'جارٍ النشر...' : 'نشر تحديث المنتجات الآن'),
                ),
                if (_lastPublishedAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'آخر تحديث: ${_lastPublishedAt!.hour.toString().padLeft(2, '0')}:${_lastPublishedAt!.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'اضغط "نشر تحديث المنتجات" بعد كل تعديل على مخزونك (إضافة منتج، تغيير سعر...) حتى يظهر التحديث فورًا عند كل الزبناء دون الحاجة لإعادة مشاركة الرابط.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _publish(StoreProfile profile) async {
    setState(() => _publishing = true);
    try {
      final name = _nameController.text.trim();
      final whatsapp = _whatsappController.text.trim();

      await ref.read(storeProfileControllerProvider.notifier).updateProfile(
            storeName: name,
            whatsappNumber: whatsapp,
          );

      final products = await ref.read(productsControllerProvider.future);
      final payload = StoreService().buildPayload(
        storeCode: profile.storeCode,
        storeName: name,
        whatsappNumber: whatsapp,
        products: products,
      );

      await StoreApiService().publishCatalog(
        storeCode: profile.storeCode,
        secret: profile.secret,
        body: payload.toMap(),
      );

      setState(() => _lastPublishedAt = DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم نشر ${payload.items.length} منتج بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }
}
