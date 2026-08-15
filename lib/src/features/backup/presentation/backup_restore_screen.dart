import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_controller.dart';
import '../../products/application/products_providers.dart';
import '../../products/data/datasources/app_database.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool busy = false;

  Future<void> _backup() async {
    setState(() => busy = true);
    try {
      final backup = await AppDatabase.instance.exportBackup();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));
      final path = await FilePicker.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName:
            'atmina-backup-${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل النسخ الاحتياطي: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => busy = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw const FormatException('تعذر قراءة الملف.');
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException('ملف النسخة الاحتياطية غير صالح.');
      }
      final backup = Map<String, dynamic>.from(decoded);

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('استعادة البيانات'),
          content: const Text(
            'سيتم استبدال المنتجات والمبيعات والطلبات الحالية بالنسخة الاحتياطية. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      await AppDatabase.instance.restoreBackup(backup);

      ref.read(cartControllerProvider.notifier).clear();
      await ref.read(productsControllerProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة البيانات وتحديث المنتجات والسلة.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاستعادة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'النسخة الاحتياطية تشمل المنتجات والمبيعات والطلبات المحلية. احتفظ بها في مكان آمن.',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : _backup,
                icon: const Icon(Icons.backup_outlined),
                label: Text(
                  busy ? 'جارٍ التنفيذ...' : 'إنشاء نسخة احتياطية',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : _restore,
                icon: const Icon(Icons.restore_outlined),
                label: const Text('استعادة نسخة احتياطية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
