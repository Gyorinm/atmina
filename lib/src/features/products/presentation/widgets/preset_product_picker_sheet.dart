import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/product_image_picker.dart';
import '../../application/products_providers.dart';
import '../../domain/models/product_family.dart';
import '../../data/moroccan_grocery_presets.dart' show moroccanGroceryCategories;
import '../../../store/application/store_profile_controller.dart';

enum _ImageMenuAction { camera, gallery, remove, uploadToServer }

/// شاشة سفلية (Bottom Sheet) لاختيار "عائلة منتج" من القائمة القابلة
/// للتوسيع من طرف التاجر نفسه (تبدأ مبذورة بمنتجات البقالة المغربية
/// الجاهزة). يمكن من هنا أيضًا إضافة عائلة جديدة، أو إرفاق/تغيير صورة
/// عائلة موجودة — صورة واحدة تكفي لتمثيل كل أحجام نفس المنتج.
///
/// عند اختيار المستخدم لعائلة، تُغلق الشاشة وتُعيد [ProductFamily]
/// المختارة إلى المستدعي.
class PresetProductPickerSheet extends ConsumerStatefulWidget {
  const PresetProductPickerSheet({super.key});

  static Future<ProductFamily?> show(BuildContext context) {
    return showModalBottomSheet<ProductFamily>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PresetProductPickerSheet(),
    );
  }

  @override
  ConsumerState<PresetProductPickerSheet> createState() => _PresetProductPickerSheetState();
}

class _PresetProductPickerSheetState extends ConsumerState<PresetProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String? _busyFamilyImageUpdateId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductFamily> _filtered(List<ProductFamily> families) {
    final query = _query.trim().toLowerCase();
    return families.where((family) {
      final matchesCategory = _selectedCategory == null || family.category == _selectedCategory;
      final matchesQuery = query.isEmpty || family.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _attachFamilyImage(ProductFamily family, bool fromCamera) async {
    setState(() => _busyFamilyImageUpdateId = '${family.id}');
    try {
      final path = fromCamera
          ? await ProductImagePicker.pickFromCamera()
          : await ProductImagePicker.pickFromGallery();
      if (path != null) {
        await ref.read(productFamiliesControllerProvider.notifier).updateFamilyImage(family, path);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ الصورة: $error')));
      }
    } finally {
      if (mounted) setState(() => _busyFamilyImageUpdateId = null);
    }
  }

  Future<void> _showImageSourceMenu(ProductFamily family) async {
    final action = await showModalBottomSheet<_ImageMenuAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.of(context).pop(_ImageMenuAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من المعرض'),
              onTap: () => Navigator.of(context).pop(_ImageMenuAction.gallery),
            ),
            if (family.imagePath != null) ...[
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.navy),
                title: const Text('تصدير الصورة إلى الخادم'),
                onTap: () => Navigator.of(context).pop(_ImageMenuAction.uploadToServer),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('حذف الصورة', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop(_ImageMenuAction.remove),
              ),
            ],
          ],
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case _ImageMenuAction.camera:
        await _attachFamilyImage(family, true);
      case _ImageMenuAction.gallery:
        await _attachFamilyImage(family, false);
      case _ImageMenuAction.remove:
        await _removeFamilyImage(family);
      case _ImageMenuAction.uploadToServer:
        await _uploadFamilyImageToServer(family);
    }
  }

  Future<void> _removeFamilyImage(ProductFamily family) async {
    setState(() => _busyFamilyImageUpdateId = '${family.id}');
    try {
      await ref.read(productFamiliesControllerProvider.notifier).updateFamilyImage(family, null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حذف الصورة: $error')));
      }
    } finally {
      if (mounted) setState(() => _busyFamilyImageUpdateId = null);
    }
  }

  Future<void> _uploadFamilyImageToServer(ProductFamily family) async {
    setState(() => _busyFamilyImageUpdateId = '${family.id}');
    try {
      final profile = await ref.read(storeProfileControllerProvider.future);
      await ref.read(productFamiliesControllerProvider.notifier).uploadImageToServer(
            family: family,
            storeCode: profile.storeCode,
            secret: profile.secret,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير الصورة إلى الخادم بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التصدير: $error')));
      }
    } finally {
      if (mounted) setState(() => _busyFamilyImageUpdateId = null);
    }
  }

  Future<void> _openAddFamilyDialog() async {
    final result = await showDialog<_NewFamilyResult>(
      context: context,
      builder: (context) => const _AddFamilyDialog(),
    );
    if (result == null) return;

    String? imagePath;
    if (result.attachImage) {
      imagePath = await ProductImagePicker.pickFromGallery();
    }
    await ref.read(productFamiliesControllerProvider.notifier).addFamily(
          name: result.name,
          category: result.category,
          imagePath: imagePath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final familiesState = ref.watch(productFamiliesControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
                        'قائمة المنتجات',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openAddFamilyDialog,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('منتج جديد'),
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
                    hintText: 'ابحث عن منتج... (مثال: Huile، Javel، Lait)',
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
                child: familiesState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('تعذر تحميل القائمة: $error')),
                  data: (families) {
                    final items = _filtered(families);
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'لا توجد نتائج مطابقة.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _openAddFamilyDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('إضافة هذا المنتج للقائمة'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final family = items[index];
                        final isBusy = _busyFamilyImageUpdateId == '${family.id}';
                        return ListTile(
                          leading: GestureDetector(
                            onTap: isBusy ? null : () => _showImageSourceMenu(family),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.canvas,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                    image: family.imagePath != null
                                        ? DecorationImage(image: FileImage(File(family.imagePath!)), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: isBusy
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : family.imagePath == null
                                          ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 18)
                                          : null,
                                ),
                                if (family.imagePath != null && !isBusy)
                                  Positioned(
                                    bottom: -4,
                                    left: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(
                                        family.isExportedToServer ? Icons.cloud_done_rounded : Icons.cloud_off_outlined,
                                        size: 16,
                                        color: family.isExportedToServer ? AppColors.success : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(family.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            family.isExportedToServer
                                ? '${family.category} · مُصدَّرة للخادم ✓'
                                : family.category,
                            style: TextStyle(
                              color: family.isExportedToServer ? AppColors.success : AppColors.textMuted,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.navy),
                          onTap: () => Navigator.of(context).pop(family),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'اضغط على الصورة الصغيرة بجانب أي منتج لإرفاق أو تغيير صورته. صورة واحدة تكفي لكل أحجام نفس المنتج.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
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

class _NewFamilyResult {
  const _NewFamilyResult({required this.name, required this.category, required this.attachImage});

  final String name;
  final String category;
  final bool attachImage;
}

class _AddFamilyDialog extends StatefulWidget {
  const _AddFamilyDialog();

  @override
  State<_AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends State<_AddFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _attachImageNow = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('إضافة منتج جديد للقائمة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
              validator: (v) => v == null || v.trim().isEmpty ? 'أدخل اسم المنتج.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              validator: (v) => v == null || v.trim().isEmpty ? 'أدخل التصنيف.' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _attachImageNow,
              onChanged: (v) => setState(() => _attachImageNow = v ?? false),
              title: const Text('إرفاق صورة الآن من المعرض'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              _NewFamilyResult(
                name: _nameController.text.trim(),
                category: _categoryController.text.trim(),
                attachImage: _attachImageNow,
              ),
            );
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
