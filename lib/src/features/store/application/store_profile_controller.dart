import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_service.dart';

const String _storeCodeKey = 'atmina_store_code';
const String _storeSecretKey = 'atmina_store_secret';
const String _storeNameKey = 'atmina_store_name';
const String _storeWhatsappKey = 'atmina_store_whatsapp';

class StoreProfile {
  const StoreProfile({
    required this.storeCode,
    required this.secret,
    required this.storeName,
    required this.whatsappNumber,
  });

  final String storeCode;
  final String secret;
  final String storeName;
  final String whatsappNumber;

  StoreProfile copyWith({String? storeName, String? whatsappNumber}) => StoreProfile(
        storeCode: storeCode,
        secret: secret,
        storeName: storeName ?? this.storeName,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      );
}

final storeProfileControllerProvider =
    AsyncNotifierProvider<StoreProfileController, StoreProfile>(StoreProfileController.new);

class StoreProfileController extends AsyncNotifier<StoreProfile> {
  static final Random _random = Random.secure();

  @override
  Future<StoreProfile> build() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(_storeCodeKey);
    if (code == null || code.isEmpty) {
      code = StoreService.generateStoreCode();
      await prefs.setString(_storeCodeKey, code);
    }
    var secret = prefs.getString(_storeSecretKey);
    if (secret == null || secret.isEmpty) {
      secret = _generateSecret();
      await prefs.setString(_storeSecretKey, secret);
    }
    final name = prefs.getString(_storeNameKey) ?? '';
    final whatsapp = prefs.getString(_storeWhatsappKey) ?? '';
    return StoreProfile(storeCode: code, secret: secret, storeName: name, whatsappNumber: whatsapp);
  }

  Future<void> updateProfile({String? storeName, String? whatsappNumber}) async {
    final current = state.valueOrNull ?? await build();
    final prefs = await SharedPreferences.getInstance();
    if (storeName != null) await prefs.setString(_storeNameKey, storeName);
    if (whatsappNumber != null) await prefs.setString(_storeWhatsappKey, whatsappNumber);
    state = AsyncData(current.copyWith(storeName: storeName, whatsappNumber: whatsappNumber));
  }

  static String _generateSecret() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }
}
