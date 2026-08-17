import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/products_providers.dart';
import '../../data/moroccan_grocery_presets.dart';
import '../../domain/models/create_product_input.dart';
import 'preset_product_picker_sheet.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key, required this.existingCategories});

  final List<String> existingCategories;

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _variantController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _variantController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _variantController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickFromPresetList() async {
    final GroceryPresetItem? picked = await PresetProductPickerSheet.show(context);
    if (picked == null) return;
    setState(() {
      _nameController.text = picked.name;
      _categoryController.text = picked.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('إضافة منتج جديد'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickFromPresetList,
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('اختيار من قائمة منتجات البقالة الجاهزة'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: AppColors.navy),
                    foregroundColor: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('أو أدخل يدويًا', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 14),
                _field(_nameController, 'اسم المنتج', TextInputAction.next,
                    (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المنتج.' : null),
                const SizedBox(height: 12),
                _field(_categoryController, 'التصنيف', TextInputAction.next,
                    (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال التصنيف.' : null),
                const SizedBox(height: 12),
                _field(
                  _variantController,
                  'الحجم / الوزن (اختياري) — مثال: 1 لتر، 5 كغ، متوسط',
                  TextInputAction.next,
                  (_) => null,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اكتب الحجم كما تريد بنفسك، لتمييز نفس المنتج بأحجام مختلفة.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                _field(_priceController, 'السعر بالدرهم (MAD)', TextInputAction.next, (v) {
                  final n = _parseDouble(v);
                  return n == null || n <= 0 ? 'أدخل سعرًا صحيحًا أكبر من صفر.' : null;
                }, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]),
                const SizedBox(height: 12),
                _field(_stockController, 'الكمية الأولية', TextInputAction.done, (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n < 0 ? 'أدخل كمية صحيحة تساوي صفر أو أكثر.' : null;
                }, keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProduct,
          icon: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ المنتج'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextInputAction action,
    String? Function(String?) validator, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.canvas,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final variant = _variantController.text.trim();
      final fullName = variant.isEmpty ? _nameController.text.trim() : '${_nameController.text.trim()} - $variant';
      final product = await ref.read(productsControllerProvider.notifier).addProduct(
        CreateProductInput(
          name: fullName,
          category: _categoryController.text.trim(),
          price: _parseDouble(_priceController.text.trim())!,
          stockQuantity: int.parse(_stockController.text.trim()),
        ),
      );
      if (mounted) Navigator.of(context).pop(product);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _parseDouble(String? value) => value == null || value.trim().isEmpty
      ? null
      : double.tryParse(value.replaceAll(',', '.').trim());
}
