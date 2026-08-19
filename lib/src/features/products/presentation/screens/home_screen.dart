import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../cart/application/cart_controller.dart';
import '../../application/products_providers.dart';
import '../../domain/models/product.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/product_group_card.dart';
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
    final filteredProducts = ref.watch(filteredProductsProvider);
    final allProducts = productsState.valueOrNull ?? const <Product>[];
    final categories = allProducts.map((p) => p.category).toSet().toList()..sort();
    final outOfStock = ref.watch(outOfStockProductsProvider).valueOrNull ?? const <Product>[];
    final lowStock = ref.watch(lowStockProductsProvider).valueOrNull ?? const <Product>[];
    final cartTotals = ref.watch(cartTotalsProvider);
    final familiesById = ref.watch(productFamiliesByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atmina POS'),
        actions: [
          IconButton(
            onPressed: () => _openAddProductDialog(categories),
            tooltip: 'إضافة منتج',
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(productsControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(totalQuantity: cartTotals.totalQuantity),
                      if (outOfStock.isNotEmpty || lowStock.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InventoryAlertCard(
                          outOfStock: outOfStock,
                          lowStock: lowStock,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SearchInput(
                        controller: _searchController,
                        onChanged: (value) {
                          ref.read(productSearchQueryProvider.notifier).state = value;
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'المنتجات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              filteredProducts.when(
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
                data: (products) {
                  final groups = _groupProducts(products);
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: products.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              onClearSearch: () {
                                _searchController.clear();
                                ref.read(productSearchQueryProvider.notifier).state = '';
                              },
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final group = groups[index];
                                // منتج له أكثر من حجم/متغيّر: بطاقة واحدة موحّدة
                                // (بنفس شكل ظهورها للزبون) بدل تكرار المنتج عدة
                                // مرات، مع بقاء صلاحيات تعديل الكمية والسعر والحذف.
                                if (group.length > 1) {
                                  final familyId = group.first.familyId;
                                  final family = familyId != null ? familiesById[familyId] : null;
                                  return ProductGroupCard(
                                    products: group,
                                    family: family,
                                    onAdd: (product) => _addProduct(context, product),
                                    onUpdateStock: (product) => _updateStock(context, product),
                                    onDelete: (product) => _deleteProduct(context, product),
                                  );
                                }
                                final product = group.first;
                                final family = product.familyId != null ? familiesById[product.familyId] : null;
                                return ProductCard(
                                  product: product,
                                  familyImagePath: family?.imagePath,
                                  onAdd: () => _addProduct(context, product),
                                  onUpdateStock: () => _updateStock(context, product),
                                  onDelete: () => _deleteProduct(context, product),
                                );
                              },
                              childCount: groups.length,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// يجمع المنتجات حسب عائلتها: كل عائلة تحمل أكثر من حجم/متغيّر واحد
  /// تظهر كبطاقة واحدة موحّدة، وباقي المنتجات (بلا عائلة أو بعائلة ذات
  /// حجم واحد فقط) تظهر كل واحد في بطاقته المستقلة كما كانت. نفس منطق
  /// التجميع المعتمد في كتالوج الزبون، حتى يتطابق الشكلان.
  List<List<Product>> _groupProducts(List<Product> products) {
    final Map<int, List<Product>> byFamily = {};
    final List<List<Product>> ordered = [];

    for (final product in products) {
      if (product.familyId == null) {
        ordered.add([product]);
        continue;
      }
      final group = byFamily.putIfAbsent(product.familyId!, () {
        final newGroup = <Product>[];
        ordered.add(newGroup);
        return newGroup;
      });
      group.add(product);
    }

    return ordered;
  }

  Future<void> _openAddProductDialog(List<String> categories) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AddProductDialog(existingCategories: categories),
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ المنتج "${result.name}"')),
    );
  }

  void _addProduct(BuildContext context, Product product) {
    final added = ref.read(cartControllerProvider.notifier).addProduct(product);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن تجاوز المخزون المتاح لمنتج "${product.name}"')),
      );
    }
  }

  Future<void> _updateStock(BuildContext context, Product product) async {
    final updated = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: UpdateStockDialog(product: product),
      ),
    );
    if (!mounted || updated == null) return;
    ref.read(cartControllerProvider.notifier).syncProduct(updated);
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل تريد حذف "${product.name}" نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(productsControllerProvider.notifier).deleteProduct(product);
      ref.read(cartControllerProvider.notifier).removeProduct(product);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.totalQuantity});

  final int totalQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
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
                  'إدارة المنتجات والمبيعات بدون اتصال.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                '$totalQuantity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Text('في السلة', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryAlertCard extends StatelessWidget {
  const _InventoryAlertCard({required this.outOfStock, required this.lowStock});

  final List<Product> outOfStock;
  final List<Product> lowStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تنبيهات المخزون', style: Theme.of(context).textTheme.titleMedium),
          if (outOfStock.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'نفدت: ${outOfStock.map((p) => p.name).join('، ')}',
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          if (lowStock.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'قريبة من النفاد: ${lowStock.map((p) => p.name).join('، ')}',
              style: const TextStyle(color: AppColors.warning),
            ),
          ],
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
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
