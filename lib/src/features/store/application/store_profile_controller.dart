import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_service.dart';

const String _storeCodeKey = 'atmina_store_code';
const String _storeNameKey = 'atmina_store_name';
const String _storeWhatsappKey = 'atmina_store_whatsapp';

class StoreProfile {
  const StoreProfile({
    required this.storeCode,
    required this.storeName,
    required this.whatsappNumber,
  });

  final String storeCode;
  final String storeName;
  final String whatsappNumber;

  StoreProfile copyWith({String? storeName, String? whatsappNumber}) => StoreProfile(
        storeCode: storeCode,
        storeName: storeName ?? this.storeName,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      );
}

final storeProfileControllerProvider =
    AsyncNotifierProvider<StoreProfileController, StoreProfile>(StoreProfileController.new);

class StoreProfileController extends AsyncNotifier<StoreProfile> {
  @override
  Future<StoreProfile> build() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(_storeCodeKey);
    if (code == null || code.isEmpty) {
      code = StoreService.generateStoreCode();
      await prefs.setString(_storeCodeKey, code);
    }
    final name = prefs.getString(_storeNameKey) ?? '';
    final whatsapp = prefs.getString(_storeWhatsappKey) ?? '';
    return StoreProfile(storeCode: code, storeName: name, whatsappNumber: whatsapp);
  }

  Future<void> updateProfile({String? storeName, String? whatsappNumber}) async {
    final current = state.valueOrNull ?? await build();
    final prefs = await SharedPreferences.getInstance();
    if (storeName != null) await prefs.setString(_storeNameKey, storeName);
    if (whatsappNumber != null) await prefs.setString(_storeWhatsappKey, whatsappNumber);
    state = AsyncData(current.copyWith(storeName: storeName, whatsappNumber: whatsappNumber));
  }
}
