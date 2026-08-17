import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/moroccan_grocery_presets.dart';

/// شاشة سفلية (Bottom Sheet) لاختيار منتج جاهز من قائمة منتجات
/// البقالة المغربية الشائعة، مع بحث نصي وفلترة حسب التصنيف.
///
/// عند اختيار المستخدم لمنتج، تُغلق الشاشة وتُعيد [GroceryPresetItem]
/// المختار إلى المستدعي.
class PresetProductPickerSheet extends StatefulWidget {
  const PresetProductPickerSheet({super.key});

  static Future<GroceryPresetItem?> show(BuildContext context) {
    return showModalBottomSheet<GroceryPresetItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PresetProductPickerSheet(),
    );
  }

  @override
  State<PresetProductPickerSheet> createState() => _PresetProductPickerSheetState();
}

class _PresetProductPickerSheetState extends State<PresetProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryPresetItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    return moroccanGroceryPresets.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesQuery = query.isEmpty || item.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filteredItems;

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
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'قائمة منتجات البقالة الجاهزة',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج... (مثال: زيت، جافيل، حليب)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _categoryChip(label: 'الكل', value: null),
                    ...moroccanGroceryCategories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _categoryChip(label: c, value: c),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج مطابقة.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(item.category, style: const TextStyle(color: AppColors.textMuted)),
                            trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.navy),
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryChip({required String label, required String? value}) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = value),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
        ),
      ),
    );
  }
}
