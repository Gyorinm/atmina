import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/products_providers.dart';
import '../../domain/models/create_product_input.dart';
import 'barcode_scanner_sheet.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({
    super.key,
    required this.existingCategories,
  });

  final List<String> existingCategories;

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _categoryController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'إضافة منتج جديد',
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogTextField(
                  controller: _nameController,
                  label: 'اسم المنتج',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المنتج.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _barcodeController,
                  label: 'الباركود',
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixIcon: IconButton(
                    onPressed: _isSaving ? null : _onScanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'تشغيل ماسح الباركود',
                  ),
                  helperText:
                      'يمكنك كتابة الباركود يدويًا أو استخدام زر المسح.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الباركود.';
                    }
                    if (value.trim().length < 4) {
                      return 'الباركود قصير جدًا.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _categoryController,
                  label: 'التصنيف',
                  textInputAction: TextInputAction.next,
                  helperText: widget.existingCategories.isEmpty
                      ? 'أدخل التصنيف المناسب.'
                      : 'تصنيفات موجودة: ${widget.existingCategories.join(' - ')}',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال التصنيف.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _priceController,
                  label: 'السعر بالدرهم (MAD)',
                  textInputAction: TextInputAction.next,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    final parsed = _parseDouble(value);
                    if (parsed == null || parsed <= 0) {
                      return 'أدخل سعرًا صحيحًا أكبر من صفر.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _stockController,
                  label: 'الكمية الأولية',
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    if (parsed == null || parsed < 0) {
                      return 'أدخل كمية صحيحة تساوي صفر أو أكثر.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProduct,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ المنتج'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final input = CreateProductInput(
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        category: _categoryController.text.trim(),
        price: _parseDouble(_priceController.text.trim())!,
        stockQuantity: int.parse(_stockController.text.trim()),
      );

      final product =
          await ref.read(productsControllerProvider.notifier).addProduct(input);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(product);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _onScanBarcode() async {
    final scannedBarcode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const Directionality(
          textDirection: TextDirection.rtl,
          child: BarcodeScannerSheet(),
        ),
      ),
    );

    if (!mounted || scannedBarcode == null || scannedBarcode.isEmpty) {
      return;
    }

    _barcodeController.text = scannedBarcode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم التقاط الباركود: $scannedBarcode'),
      ),
    );
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.').trim());
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.suffixIcon,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
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
}
