import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_controller.dart';
import '../../products/application/products_providers.dart';
import '../data/backup_service.dart';
import '../domain/models/backup_outcome.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

/// Tracks whether a backup or restore operation is currently running.
final backupControllerProvider =
    NotifierProvider<BackupController, bool>(BackupController.new);

class BackupController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<BackupResult> createBackup() async {
    if (state) {
      return const BackupResult.cancelled();
    }

    state = true;
    try {
      return await ref.read(backupServiceProvider).exportBackup();
    } finally {
      state = false;
    }
  }

  Future<RestoreResult> restoreBackup() async {
    if (state) {
      return const RestoreResult.cancelled();
    }

    state = true;
    try {
      final result = await ref.read(backupServiceProvider).importBackup();

      if (result.status == BackupStatus.success) {
        ref.read(cartControllerProvider.notifier).clear();
        await ref.read(productsControllerProvider.notifier).refresh();
      }

      return result;
    } finally {
      state = false;
    }
  }
}
