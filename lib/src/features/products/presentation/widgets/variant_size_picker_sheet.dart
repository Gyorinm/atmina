import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/moroccan_grocery_presets.dart' show MeasurementUnit;
import '../../domain/models/product_family.dart';

class VariantSizeEntry {
  const VariantSizeEntry({required this.size, required this.price, required this.stockQuantity});

  final int size;
  final double price;
  final int stockQuantity;
}

/// نافذة تسمح للتاجر باختيار الأحجام المتوفرة فعليًا عنده لمنتج
/// قابل للقياس (سائل باللتر أو مادة بالكيلوغرام)، عبر وضع علامة صح
/// على كل حجم من 1 إلى 100، ثم إدخال السعر والكمية لكل حجم مختار.
class VariantSizePickerSheet extends StatefulWidget {
  const VariantSizePickerSheet({super.key, required this.family});

  final ProductFamily family;

  static Future<List<VariantSizeEntry>?> show(BuildContext context, ProductFamily family) {
    return showModalBottomSheet<List<VariantSizeEntry>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VariantSizePickerSheet(family: family),
    );
  }

  @override
  State<VariantSizePickerSheet> createState() => _VariantSizePickerSheetState();
}

class _VariantSizePickerSheetState extends State<VariantSizePickerSheet> {
  final Set<int> _selectedSizes = <int>{};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _stockControllers = {};
  final _formKey = GlobalKey<FormState>();

  String get _unitLabel => widget.family.measurementUnit.unitLabel;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSize(int size) {
    setState(() {
      if (_selectedSizes.contains(size)) {
        _selectedSizes.remove(size);
        _priceControllers.remove(size)?.dispose();
        _stockControllers.remove(size)?.dispose();
      } else {
        _selectedSizes.add(size);
        _priceControllers[size] = TextEditingController();
        _stockControllers[size] = TextEditingController(text: '1');
      }
    });
  }

  void _confirm() {
    if (_selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر حجمًا واحدًا على الأقل بوضع علامة صح.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final sortedSizes = _selectedSizes.toList()..sort();
    final entries = sortedSizes.map((size) {
      final price = double.parse(_priceControllers[size]!.text.replaceAll(',', '.').trim());
      final stock = int.parse(_stockControllers[size]!.text.trim());
      return VariantSizeEntry(size: size, price: price, stockQuantity: stock);
    }).toList();

    Navigator.of(context).pop(entries);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedSelected = _selectedSizes.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأحجام المتوفرة عندك — ${widget.family.name}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ضع علامة صح على كل حجم ($_unitLabel) كاين عندك فالمحل، من 1 إلى 100.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  height: 110,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      final size = index + 1;
                      final selected = _selectedSizes.contains(size);
                      return GestureDetector(
                        onTap: () => _toggleSize(size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.navy : AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '$size $_unitLabel',
                                style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: sortedSelected.isEmpty
                    ? const Center(
                        child: Text(
                          'اختر الأحجام من فوق، وغادي تبان ليك هنا باش تحط الثمن والكمية.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedSelected.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final size = sortedSelected[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.navy,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$size $_unitLabel',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceControllers[size],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'السعر (MAD)',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final n = double.tryParse((v ?? '').replaceAll(',', '.').trim());
                                        return n == null || n <= 0 ? 'مطلوب' : null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: _stockControllers[size],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'الكمية',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final n = int.tryParse((v ?? '').trim());
                                        return n == null || n < 0 ? 'مطلوب' : null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _toggleSize(size),
                                    icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    sortedSelected.isEmpty ? 'حفظ' : 'حفظ ${sortedSelected.length} حجم كمنتجات',
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
