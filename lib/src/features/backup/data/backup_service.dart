import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../products/data/datasources/app_database.dart';
import '../../products/domain/models/product.dart';
import '../domain/models/backup_outcome.dart';

/// Exports and imports the local catalogue as a portable JSON backup file.
class BackupService {
  const BackupService(this._database);

  static const String appSignature = 'atmina_pos';
  static const int formatVersion = 1;

  final AppDatabase _database;

  Future<BackupResult> exportBackup() async {
    final products = await _database.getAllProducts();
    final payload = <String, Object?>{
      'app': appSignature,
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'products': products.map((product) => product.toMap()).toList(),
    };

    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final fileName = _buildFileName();

    String? savedPath;
    try {
      savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
    } on Exception {
      savedPath = null;
    }

    if (savedPath == null) {
      // The picker is unavailable or was dismissed: fall back to the app's
      // own documents directory so a backup is still produced.
      final fallbackPath = await _writeToFallbackDirectory(fileName, bytes);
      return BackupResult(
        status: BackupStatus.success,
        productCount: products.length,
        location: fallbackPath,
      );
    }

    // On desktop platforms the picker only returns a target path, so the file
    // still has to be written manually.
    final file = File(savedPath);
    if (!await file.exists() || await file.length() != bytes.length) {
      try {
        await file.writeAsBytes(bytes, flush: true);
      } on FileSystemException catch (error) {
        throw BackupException(
          'تعذر كتابة ملف النسخة الاحتياطية: ${error.message}',
        );
      }
    }

    return BackupResult(
      status: BackupStatus.success,
      productCount: products.length,
      location: savedPath,
    );
  }

  Future<RestoreResult> importBackup() async {
    FilePickerResult? selection;
    try {
      selection = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختيار ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
    } on Exception catch (error) {
      throw BackupException('تعذر فتح مستعرض الملفات: $error');
    }

    final file = selection?.files.single;
    if (file == null) {
      return const RestoreResult.cancelled();
    }

    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw const BackupException('تعذر قراءة ملف النسخة الاحتياطية.');
    }

    final products = _decodeProducts(bytes);
    await _database.replaceAllProducts(products);

    return RestoreResult(
      status: BackupStatus.success,
      productCount: products.length,
    );
  }

  List<Product> _decodeProducts(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupException('ملف النسخة الاحتياطية غير صالح.');
    }

    if (decoded is! Map<String, Object?>) {
      throw const BackupException('ملف النسخة الاحتياطية غير صالح.');
    }

    if (decoded['app'] != appSignature) {
      throw const BackupException(
        'هذا الملف لا يخص تطبيق Atmina POS.',
      );
    }

    final version = (decoded['formatVersion'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) {
      throw const BackupException(
        'النسخة الاحتياطية أُنشئت بإصدار أحدث من التطبيق.',
      );
    }

    final rawProducts = decoded['products'];
    if (rawProducts is! List) {
      throw const BackupException('ملف النسخة الاحتياطية لا يحتوي على منتجات.');
    }

    try {
      return rawProducts
          .cast<Map<String, Object?>>()
          .map(Product.fromMap)
          .map(
            (product) => product.searchTerms.isEmpty
                ? product.copyWith(
                    searchTerms: AppDatabase.buildSearchTerms(product),
                  )
                : product,
          )
          .toList(growable: false);
    } on Exception {
      throw const BackupException(
        'تعذر قراءة بيانات المنتجات من النسخة الاحتياطية.',
      );
    }
  }

  Future<String> _writeToFallbackDirectory(
    String fileName,
    List<int> bytes,
  ) async {
    Directory directory;
    try {
      directory =
          (Platform.isAndroid ? await getExternalStorageDirectory() : null) ??
              await getApplicationDocumentsDirectory();
    } on Exception catch (error) {
      throw BackupException('تعذر الوصول إلى مجلد الحفظ: $error');
    }

    final path = p.join(directory.path, fileName);
    try {
      await File(path).writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      throw BackupException(
        'تعذر كتابة ملف النسخة الاحتياطية: ${error.message}',
      );
    }

    return path;
  }

  String _buildFileName() {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'atmina_pos_backup_$timestamp.json';
  }
}
