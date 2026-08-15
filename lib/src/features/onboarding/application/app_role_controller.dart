import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_role.dart';

const String _roleStorageKey = 'atmina_app_role';

final appRoleControllerProvider =
    AsyncNotifierProvider<AppRoleController, AppRole?>(AppRoleController.new);

class AppRoleController extends AsyncNotifier<AppRole?> {
  @override
  Future<AppRole?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppRole.fromStorageValue(prefs.getString(_roleStorageKey));
  }

  Future<void> selectRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleStorageKey, role.storageValue);
    state = AsyncData(role);
  }

  Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleStorageKey);
    state = const AsyncData(null);
  }
}
