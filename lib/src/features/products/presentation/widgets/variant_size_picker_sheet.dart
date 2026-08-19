import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/product_family.dart';

class VariantSizeEntry {
  const VariantSizeEntry({required this.sizeLabel, required this.price, required this.stockQuantity});

  /// تسمية الحجم كاملة كما ستظهر للزبون (مثال: "1 لتر"، "صغير"،
  /// "عبوة كبيرة"). حرة تمامًا، يكتبها التاجر بنفسه أو يختارها من
  /// الاقتراحات السريعة.
  final String sizeLabel;
  final double price;
  final int stockQuantity;
}

class _SizeRow {
  _SizeRow({String initialLabel = ''})
      : labelController = TextEditingController(text: initialLabel),
        priceController = TextEditingController(),
        stockController = TextEditingController(text: '1');

  final TextEditingController labelController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

/// نافذة موحّدة تسمح للتاجر بإضافة كل الأحجام/الأنواع المتوفرة عنده
/// فعليًا لمنتج واحد (مثال: سيدي علي بأحجام صغير/متوسط/كبير وأيضًا
/// 1 لتر/2 لتر معًا في نفس الوقت) — دون إجباره على نوع واحد فقط.
/// كل صف يمثّل خيارًا واحدًا سيراه الزبون ليختار من بينها.
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

  /// اقتراحات سريعة مختلطة: كلمات وصفية دائمًا + أرقام بالوحدة
  /// المناسبة إن كان المنتج قابلًا للقياس. الضغط على أي اقتراح
  /// يضيف صفًا جديدًا مباشرة بهذه التسمية.
  List<String> get _quickSuggestions {
    final unit = widget.family.measurementUnit.unitLabel;
    final suggestions = <String>['صغير', 'متوسط', 'كبير'];
    if (unit.isNotEmpty) {
      suggestions.addAll(['1 $unit', '2 $unit', '5 $unit', '10 $unit']);
    }
    return suggestions;
  }

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

  void _addRow({String initialLabel = ''}) {
    setState(() {
      // إذا كان هناك صف فارغ تمامًا (لم يُملأ بعد)، نستخدمه بدل إضافة صف جديد فوقه.
      final emptyIndex = _rows.indexWhere((r) => r.labelController.text.trim().isEmpty);
      if (initialLabel.isNotEmpty && emptyIndex != -1) {
        _rows[emptyIndex].labelController.text = initialLabel;
      } else {
        _rows.add(_SizeRow(initialLabel: initialLabel));
      }
    });
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
        const SnackBar(content: Text('أضف خيارًا واحدًا على الأقل.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final entries = _rows
        .map(
          (row) => VariantSizeEntry(
            sizeLabel: row.labelController.text.trim(),
            price: double.parse(row.priceController.text.replaceAll(',', '.').trim()),
            stockQuantity: int.parse(row.stockController.text.trim()),
          ),
        )
        .toList();

    Navigator.of(context).pop(entries);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
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
                      'الأنواع/الأحجام المتوفرة — ${widget.family.name}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'يمكنك خلط أنواع مختلفة لنفس المنتج (صغير، كبير، 1 لتر، 2 لتر...) — كلها ستظهر للزبون كخيارات لنفس المنتج.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickSuggestions.map((label) {
                    return ActionChip(
                      label: Text(label),
                      onPressed: () => _addRow(initialLabel: label),
                      backgroundColor: AppColors.canvas,
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
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
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row.labelController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'الاسم/الحجم',
                                  hintText: 'مثال: كبير، 1 لتر',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: row.priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'السعر',
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
                              width: 70,
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
                  onPressed: () => _addRow(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('زيد خيار آخر'),
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
                  label: Text('حفظ ${_rows.length} ${_rows.length == 1 ? "خيار" : "خيارات"} كمنتجات'),
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
