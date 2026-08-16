import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastStoreCodeKey = 'atmina_customer_last_store_code';
const String _lastStoreNameKey = 'atmina_customer_last_store_name';

class CustomerLastStore {
  const CustomerLastStore({required this.code, required this.name});
  final String code;
  final String name;
}

final customerSessionControllerProvider =
    AsyncNotifierProvider<CustomerSessionController, CustomerLastStore?>(CustomerSessionController.new);

class CustomerSessionController extends AsyncNotifier<CustomerLastStore?> {
  @override
  Future<CustomerLastStore?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_lastStoreCodeKey);
    if (code == null || code.isEmpty) return null;
    final name = prefs.getString(_lastStoreNameKey) ?? '';
    return CustomerLastStore(code: code, name: name);
  }

  Future<void> saveLastStore(String code, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStoreCodeKey, code);
    await prefs.setString(_lastStoreNameKey, name);
    state = AsyncData(CustomerLastStore(code: code, name: name));
  }

  Future<void> clearLastStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastStoreCodeKey);
    await prefs.remove(_lastStoreNameKey);
    state = const AsyncData(null);
  }
}
