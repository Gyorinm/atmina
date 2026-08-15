import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../products/application/products_providers.dart';
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
  bool _sharing = false;

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
                  onPressed: _sharing ? null : () => _shareStoreLink(profile),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_outlined),
                  label: Text(_sharing ? 'جارٍ التجهيز...' : 'تحديث ومشاركة رابط المتجر'),
                ),
                const SizedBox(height: 12),
                Text(
                  'شارك هذا الرابط مع الزبون عبر واتساب. الزبون يفتحه أو يلصقه داخل التطبيق لتصفح منتجاتك وإرسال طلبيته مباشرة.',
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

  Future<void> _shareStoreLink(StoreProfile profile) async {
    setState(() => _sharing = true);
    try {
      final name = _nameController.text.trim();
      final whatsapp = _whatsappController.text.trim();

      await ref.read(storeProfileControllerProvider.notifier).updateProfile(
            storeName: name,
            whatsappNumber: whatsapp,
          );

      final products = ref.read(productsControllerProvider).valueOrNull ?? const [];
      final payload = StoreService().buildPayload(
        storeCode: profile.storeCode,
        storeName: name,
        whatsappNumber: whatsapp,
        products: products,
      );
      final uri = Uri(scheme: 'atmina', host: 'store', path: '/${payload.encode()}');
      await SharePlus.instance.share(
        ShareParams(
          text: 'متجر ${name.isEmpty ? profile.storeCode : name} على Atmina\n'
              'افتح هذا الرابط لتصفح المنتجات وإرسال طلبيتك:\n$uri',
          title: 'رابط المتجر',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تجهيز رابط المتجر: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
