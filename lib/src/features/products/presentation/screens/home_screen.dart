import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../backup/application/backup_providers.dart';
import '../../../backup/domain/models/backup_outcome.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../application/products_providers.dart';
import '../../domain/models/product.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/search_input.dart';
import '../widgets/update_stock_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsControllerProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final outOfStockProducts =
        ref.watch(outOfStockProductsProvider).valueOrNull ?? const <Product>[];
    final lowStockProducts =
        ref.watch(lowStockProductsProvider).valueOrNull ?? const <Product>[];
    final cartTotals = ref.watch(cartTotalsProvider);
    final isBackupBusy = ref.watch(backupControllerProvider);
    final allProducts = productsState.valueOrNull ?? const <Product>[];
    final categories =
        allProducts.map((product) => product.category).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atmina POS'),
        actions: [
          IconButton(
            onPressed: () => _openAddProductDialog(categories),
            tooltip: 'إضافة منتج',
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            onPressed: isBackupBusy ? null : _backupData,
            tooltip: 'الاحتفاظ بنسخة احتياطية',
            icon: const Icon(Icons.backup_outlined),
          ),
          IconButton(
            onPressed: isBackupBusy ? null : _restoreData,
            tooltip: 'استعادة النسخة الاحتياطية',
            icon: const Icon(Icons.settings_backup_restore_rounded),
          ),
        ],
      ),
      drawer: _HomeDrawer(
        onAddProduct: () => _openAddProductDialog(categories),
        onSupportDeveloper: _supportDeveloper,
        onBackupData: isBackupBusy ? null : _backupData,
        onRestoreData: isBackupBusy ? null : _restoreData,
        isBackupBusy: isBackupBusy,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: CartScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.point_of_sale_rounded),
        label: Text(
          cartTotals.totalQuantity > 0
              ? 'السلة (${cartTotals.totalQuantity})'
              : 'السلة',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.navy,
          onRefresh: () =>
              ref.read(productsControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderCard(cartTotals: cartTotals),
                      const SizedBox(height: 18),
                      if (outOfStockProducts.isNotEmpty ||
                          lowStockProducts.isNotEmpty) ...[
                        _InventoryAlertsCard(
                          outOfStockProducts: outOfStockProducts,
                          lowStockProducts: lowStockProducts,
                        ),
                        const SizedBox(height: 18),
                      ],
                      SearchInput(
                        controller: _searchController,
                        onChanged: (value) {
                          ref.read(productSearchQueryProvider.notifier).state =
                              value;
                        },
                      ),
                      const SizedBox(height: 18),
                      _SectionBar(
                        onAddProduct: () => _openAddProductDialog(categories),
                        onScanTap: () => _showScanMessage(context),
                      ),
                    ],
                  ),
                ),
              ),
              productsAsync.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ProductCardSkeleton(),
                      childCount: 6,
                    ),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'تعذر تحميل المنتجات: $error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                data: (products) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: products.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(
                            onClearSearch: () {
                              _searchController.clear();
                              ref
                                  .read(productSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = products[index];
                              return ProductCard(
                                product: product,
                                onAdd: () => _addProduct(context, product),
                                onUpdateStock: () =>
                                    _openUpdateStockDialog(product),
                                onDelete: () => _confirmDeleteProduct(product),
                              );
                            },
                            childCount: products.length,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProduct(BuildContext context, Product product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المنتج "${product.name}" غير متوفر في المخزون حاليًا'),
        ),
      );
      return;
    }

    final added = ref.read(cartControllerProvider.notifier).addProduct(product);

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم الوصول إلى الحد الأقصى من المخزون لمنتج "${product.name}"'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة "${product.name}" إلى السلة'),
      ),
    );
  }

  Future<void> _openAddProductDialog(
    List<String> categories,
  ) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AddProductDialog(existingCategories: categories),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ المنتج "${result.name}" وتحديث القائمة'),
      ),
    );
  }

  Future<void> _openUpdateStockDialog(Product product) async {
    final updatedProduct = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: UpdateStockDialog(product: product),
      ),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    ref.read(cartControllerProvider.notifier).syncProduct(updatedProduct);

    _showSnackBar(
      'تم تحديث مخزون "${updatedProduct.name}" إلى ${updatedProduct.stockQuantity}',
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text(
            'هل تريد حذف "${product.name}" نهائيًا من قاعدة البيانات المحلية؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(productsControllerProvider.notifier)
          .deleteProduct(product);
      ref.read(cartControllerProvider.notifier).removeProduct(product);

      if (!mounted) {
        return;
      }

      _showSnackBar('تم حذف المنتج "${product.name}"');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.toString());
    }
  }

  Future<void> _backupData() async {
    try {
      final result =
          await ref.read(backupControllerProvider.notifier).createBackup();

      if (!mounted || result.status == BackupStatus.cancelled) {
        return;
      }

      _showSnackBar(
        'تم حفظ نسخة احتياطية تضم ${result.productCount} منتجًا في:\n${result.location}',
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar('تعذر إنشاء النسخة الاحتياطية: $error');
      }
    }
  }

  Future<void> _restoreData() async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استعادة النسخة الاحتياطية'),
          content: const Text(
            'ستحل بيانات النسخة الاحتياطية محل جميع المنتجات الحالية. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      ),
    );

    if (shouldRestore != true || !mounted) {
      return;
    }

    try {
      final result =
          await ref.read(backupControllerProvider.notifier).restoreBackup();

      if (!mounted || result.status == BackupStatus.cancelled) {
        return;
      }

      _showSnackBar('تمت استعادة ${result.productCount} منتجًا بنجاح');
    } catch (error) {
      if (mounted) {
        _showSnackBar('تعذرت استعادة النسخة الاحتياطية: $error');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showScanMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('زر المسح جاهز للربط مع كاميرا الباركود لاحقًا'),
      ),
    );
  }

  Future<void> _supportDeveloper() async {
    final uri = Uri.parse(
      'https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=brahim0619087436%40gmail.com&currency_code=MAD&item_name=Atmina%20POS%20Developer%20Support',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح رابط دعم المطور على هذا الجهاز'),
        ),
      );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.cartTotals});

  final CartTotals cartTotals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navySoft],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atmina POS',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'واجهة بيع سريعة ومصممة للمتاجر المحلية حتى في وضع عدم الاتصال.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'العناصر في السلة',
                  value: '${cartTotals.totalQuantity}',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _MetricTile(
                  label: 'وضع التشغيل',
                  value: 'Offline',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _InventoryAlertsCard extends StatelessWidget {
  const _InventoryAlertsCard({
    required this.outOfStockProducts,
    required this.lowStockProducts,
  });

  final List<Product> outOfStockProducts;
  final List<Product> lowStockProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تنبيهات المخزون',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'هذه المنتجات تحتاج متابعة قبل أن تؤثر على البيع.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          if (outOfStockProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'نفدت من المخزون',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...outOfStockProducts.map(
              (product) => _InventoryAlertTile(
                productName: product.name,
                stockLabel: 'الكمية: 0',
                accentColor: AppColors.danger,
              ),
            ),
          ],
          if (lowStockProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'قريبة من النفاد',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...lowStockProducts.map(
              (product) => _InventoryAlertTile(
                productName: product.name,
                stockLabel: 'المتبقي: ${product.stockQuantity}',
                accentColor: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InventoryAlertTile extends StatelessWidget {
  const _InventoryAlertTile({
    required this.productName,
    required this.stockLabel,
    required this.accentColor,
  });

  final String productName;
  final String stockLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              productName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            stockLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({
    required this.onScanTap,
    required this.onAddProduct,
  });

  final VoidCallback onScanTap;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'المنتجات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onAddProduct,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('منتج جديد'),
        ),
        OutlinedButton.icon(
          onPressed: onScanTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('مسح باركود'),
        ),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.onAddProduct,
    required this.onSupportDeveloper,
    required this.onBackupData,
    required this.onRestoreData,
    required this.isBackupBusy,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onSupportDeveloper;
  final VoidCallback? onBackupData;
  final VoidCallback? onRestoreData;
  final bool isBackupBusy;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atmina POS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إدارة المبيعات والمخزون محليًا مع تجربة دفع سريعة.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('إضافة منتج جديد'),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddProduct();
                },
              ),
              const Divider(height: 24),
              ListTile(
                enabled: onBackupData != null,
                leading: const Icon(Icons.backup_outlined),
                title: const Text('الاحتفاظ بنسخة احتياطية'),
                subtitle: const Text('تصدير المنتجات إلى ملف JSON'),
                trailing: isBackupBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: onBackupData == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onBackupData!();
                      },
              ),
              ListTile(
                enabled: onRestoreData != null,
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: const Text('استعادة النسخة الاحتياطية'),
                subtitle: const Text('استيراد المنتجات من ملف محفوظ'),
                onTap: onRestoreData == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onRestoreData!();
                      },
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: const Text('دعم المطور'),
                subtitle: const Text('Support App Developer'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSupportDeveloper();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد نتائج مطابقة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب كتابة جزء من الاسم أو امسح الباركود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onClearSearch,
              child: const Text('مسح البحث'),
            ),
          ],
        ),
      ),
    );
  }
}
