import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastStoreKey = 'atmina_customer_last_store';

final customerSessionControllerProvider =
    AsyncNotifierProvider<CustomerSessionController, String?>(CustomerSessionController.new);

class CustomerSessionController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastStoreKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> saveLastStore(String encodedPayload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStoreKey, encodedPayload);
    state = AsyncData(encodedPayload);
  }

  Future<void> clearLastStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastStoreKey);
    state = const AsyncData(null);
  }
}
