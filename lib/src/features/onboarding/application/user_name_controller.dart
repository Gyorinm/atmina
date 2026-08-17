import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _userNameKey = 'atmina_user_name';

final userNameControllerProvider =
    AsyncNotifierProvider<UserNameController, String?>(UserNameController.new);

class UserNameController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userNameKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> saveName(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, trimmed);
    state = AsyncData(trimmed);
  }

  Future<void> clearName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    state = const AsyncData(null);
  }
}
