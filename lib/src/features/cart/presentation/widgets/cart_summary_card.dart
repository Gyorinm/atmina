import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/cart_controller.dart';

enum DiscountType { percentage, fixed }

class CartSummaryCard extends StatefulWidget {
  const CartSummaryCard({
    super.key,
    required this.totals,
    required this.onCheckout,
  });

  final CartTotals totals;
  final ValueChanged<double> onCheckout;

  @override
  State<CartSummaryCard> createState() => _CartSummaryCardState();
}

class _CartSummaryCardState extends State<CartSummaryCard> {
  late final TextEditingController _discountController;
  late final TextEditingController _receivedController;
  DiscountType _discountType = DiscountType.percentage;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController();
    _receivedController = TextEditingController();
    _discountController.addListener(_onFieldChanged);
    _receivedController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _discountController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _receivedController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  double get _discountValue => _parseNumber(_discountController.text);

  double get _receivedValue => _parseNumber(_receivedController.text);

  double get _discountAmount {
    if (_discountType == DiscountType.percentage) {
      final percentage = _discountValue.clamp(0, 100);
      return widget.totals.subtotal * (percentage / 100);
    }

    return _discountValue.clamp(0, widget.totals.subtotal);
  }

  double get _finalPayable => math.max(0, widget.totals.subtotal - _discountAmount);

  double get _changeDue => _receivedValue - _finalPayable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
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
            'حاسبة الدفع',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          _SummaryRow(label: 'عدد الأصناف', value: '${widget.totals.itemsCount}'),
          _SummaryRow(
            label: 'إجمالي الكميات',
            value: '${widget.totals.totalQuantity}',
          ),
          _SummaryRow(
            label: 'المجموع الفرعي',
            value: widget.totals.subtotal.toCurrency(),
          ),
          const SizedBox(height: 12),
          Text(
            'نوع الخصم',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          SegmentedButton<DiscountType>(
            segments: const [
              ButtonSegment<DiscountType>(
                value: DiscountType.percentage,
                label: Text('نسبة %'),
              ),
              ButtonSegment<DiscountType>(
                value: DiscountType.fixed,
                label: Text('مبلغ ثابت'),
              ),
            ],
            selected: {_discountType},
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.white.withValues(alpha: 0.08);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.navy;
                }
                return Colors.white;
              }),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Colors.white24),
              ),
            ),
            onSelectionChanged: (selection) {
              setState(() {
                _discountType = selection.first;
              });
            },
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _discountController,
            label: _discountType == DiscountType.percentage
                ? 'قيمة الخصم (%)'
                : 'قيمة الخصم (MAD)',
            icon: _discountType == DiscountType.percentage
                ? Icons.percent_rounded
                : Icons.discount_rounded,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'قيمة الخصم',
            value: _discountAmount.toCurrency(),
          ),
          const Divider(color: Colors.white24, height: 28),
          _SummaryRow(
            label: 'السعر النهائي',
            value: _finalPayable.toCurrency(),
            emphasized: true,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _receivedController,
            label: 'المبلغ المستلم (MAD)',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'الباقي',
            value: _changeDue.toCurrency(),
            valueColor: _changeDue < 0 ? Colors.amberAccent : Colors.white,
          ),
          if (_changeDue < 0) ...[
            const SizedBox(height: 8),
            Text(
              'المبلغ المستلم أقل من السعر النهائي.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amberAccent,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _changeDue < 0
                  ? null
                  : () => widget.onCheckout(_finalPayable),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('إنهاء البيع'),
            ),
          ),
        ],
      ),
    );
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  double _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: emphasized ? Colors.white : Colors.white70,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style?.copyWith(color: valueColor ?? style.color),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
