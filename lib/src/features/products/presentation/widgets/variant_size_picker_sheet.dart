import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/product_family.dart';

class VariantSizeEntry {
  const VariantSizeEntry({required this.sizeLabel, required this.price, required this.stockQuantity});

  /// نص الحجم كما كتبه التاجر بنفسه (مثال: "1"، "2.5") متبوعًا
  /// بوحدة القياس تلقائيًا عند العرض.
  final String sizeLabel;
  final double price;
  final int stockQuantity;
}

class _SizeRow {
  _SizeRow()
      : sizeController = TextEditingController(),
        priceController = TextEditingController(),
        stockController = TextEditingController(text: '1');

  final TextEditingController sizeController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  void dispose() {
    sizeController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

/// نافذة تسمح للتاجر بإضافة الأحجام المتوفرة عنده فعليًا لمنتج قابل
/// للقياس (سائل باللتر أو مادة بالكيلوغرام)، بالضغط على زر "+" لكل
/// حجم يكتبه بنفسه (1، 2، 1.5...)، مع السعر والكمية لكل حجم.
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
  final _formKey = GlobalKey<FormState>();
  final List<_SizeRow> _rows = [];

  String get _unitLabel => widget.family.measurementUnit.unitLabel;

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(_SizeRow()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _confirm() {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف حجمًا واحدًا على الأقل بالضغط على "+".')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final entries = _rows
        .map(
          (row) => VariantSizeEntry(
            sizeLabel: _formatSize(row.sizeController.text.trim()),
            price: double.parse(row.priceController.text.replaceAll(',', '.').trim()),
            stockQuantity: int.parse(row.stockController.text.trim()),
          ),
        )
        .toList();

    Navigator.of(context).pop(entries);
  }

  String _formatSize(String raw) {
    final normalized = raw.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return raw;
    // يحذف الأصفار الزائدة بعد الفاصلة (2.0 -> 2، 1.50 -> 1.5).
    final text = value == value.roundToDouble() ? value.toInt().toString() : value.toString();
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
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
                      'اضغط "+" وزيد كل حجم ($_unitLabel) كاين عندك، وحط الثمن والكمية ديالو.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                controller: row.sizeController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: _unitLabel,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final n = double.tryParse((v ?? '').replaceAll(',', '.').trim());
                                  return n == null || n <= 0 ? 'مطلوب' : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: row.priceController,
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
                              width: 80,
                              child: TextFormField(
                                controller: row.stockController,
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
                              onPressed: _rows.length > 1 ? () => _removeRow(index) : null,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('زيد حجم آخر'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.navy),
                    foregroundColor: AppColors.navy,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.save_outlined),
                  label: Text('حفظ ${_rows.length} ${_rows.length == 1 ? "حجم" : "أحجام"} كمنتجات'),
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
