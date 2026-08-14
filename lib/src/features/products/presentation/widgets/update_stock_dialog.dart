import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/products_providers.dart';
import '../../domain/models/product.dart';

class UpdateStockDialog extends ConsumerStatefulWidget {
  const UpdateStockDialog({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  ConsumerState<UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends ConsumerState<UpdateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: '${widget.product.stockQuantity}',
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('تحديث المخزون'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'الكمية الحالية: ${widget.product.stockQuantity}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) {
                    return 'أدخل كمية صحيحة تساوي صفر أو أكثر.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'الكمية الموجودة',
                  helperText: 'ضع 0 إذا نفد المنتج من المخزون.',
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_2_outlined),
          label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الكمية'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProduct = await ref
          .read(productsControllerProvider.notifier)
          .updateStock(
            widget.product,
            int.parse(_stockController.text.trim()),
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedProduct);
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
}
