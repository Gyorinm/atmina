import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/store_payload.dart';
import 'customer_cart_screen.dart';

class CustomerCatalogScreen extends ConsumerWidget {
  const CustomerCatalogScreen({super.key, required this.payload});

  final StorePayload payload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartTotals = ref.watch(cartTotalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(payload.storeName.isEmpty ? 'متجر ${payload.storeCode}' : payload.storeName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CustomerCartScreen(payload: payload)),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_bag_outlined),
        label: Text(cartTotals.totalQuantity > 0 ? 'الطلبية (${cartTotals.totalQuantity})' : 'الطلبية'),
      ),
      body: SafeArea(
        child: payload.items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('لا توجد منتجات متاحة حاليًا في هذا المتجر.', style: theme.textTheme.bodyLarge),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                itemCount: payload.items.length,
                itemBuilder: (context, index) {
                  final item = payload.items[index];
                  final product = _productFor(item);
                  return _CatalogItemCard(
                    item: item,
                    storeCode: payload.storeCode,
                    onAdd: () {
                      final added = ref.read(cartControllerProvider.notifier).addProduct(product);
                      if (!added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('لا يمكن تجاوز الكمية المتاحة من "${item.name}"')),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  Product _productFor(StorePayloadItem item) {
    final now = DateTime.now();
    return Product(
      name: item.name,
      price: item.price,
      barcode: item.internalCode,
      category: item.category,
      stockQuantity: item.stockQuantity,
      searchTerms: '',
      createdAt: now,
      updatedAt: now,
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({required this.item, required this.storeCode, required this.onAdd});

  final StorePayloadItem item;
  final String storeCode;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.familyId != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://atmina-store-api.o2730884.workers.dev/store/$storeCode/images/${item.familyId}',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 64,
                    height: 64,
                    color: AppColors.canvas,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(child: _buildDetails(theme)),
        ],
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(item.category, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            item.stockQuantity > 0 ? 'المتوفر: ${item.stockQuantity}' : 'نفد المخزون',
            style: theme.textTheme.bodySmall?.copyWith(
              color: item.stockQuantity > 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.price.toCurrency(),
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColors.navy),
                ),
              ),
              FilledButton.icon(
                onPressed: item.stockQuantity > 0 ? onAdd : null,
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(item.stockQuantity > 0 ? 'إضافة' : 'غير متوفر'),
              ),
            ],
          ),
        ],
      );
  }
}
