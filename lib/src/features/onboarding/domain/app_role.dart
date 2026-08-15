enum AppRole {
  merchant,
  customer;

  String get storageValue => name;

  static AppRole? fromStorageValue(String? value) {
    if (value == null) return null;
    for (final role in AppRole.values) {
      if (role.storageValue == value) return role;
    }
    return null;
  }
}
