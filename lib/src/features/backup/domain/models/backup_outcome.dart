enum BackupStatus { success, cancelled }

class BackupResult {
  const BackupResult({
    required this.status,
    required this.productCount,
    this.location,
  });

  const BackupResult.cancelled()
      : status = BackupStatus.cancelled,
        productCount = 0,
        location = null;

  final BackupStatus status;
  final int productCount;
  final String? location;
}

class RestoreResult {
  const RestoreResult({
    required this.status,
    required this.productCount,
  });

  const RestoreResult.cancelled()
      : status = BackupStatus.cancelled,
        productCount = 0;

  final BackupStatus status;
  final int productCount;
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
