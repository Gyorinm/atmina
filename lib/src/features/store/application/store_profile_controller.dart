import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_service.dart';

const String _storeCodeKey = 'atmina_store_code';
const String _storeSecretKey = 'atmina_store_secret';
const String _storeNameKey = 'atmina_store_name';
const String _storeWhatsappKey = 'atmina_store_whatsapp';
const String _storeLatKey = 'atmina_store_lat';
const String _storeLngKey = 'atmina_store_lng';

class StoreProfile {
  const StoreProfile({
    required this.storeCode,
    required this.secret,
    required this.storeName,
    required this.whatsappNumber,
    this.latitude,
    this.longitude,
  });

  final String storeCode;
  final String secret;
  final String storeName;
  final String whatsappNumber;

  /// موقع المتجر الجغرافي إن حدّده التاجر، يُستخدم لعرض المتجر على
  /// خريطة "المتاجر القريبة" عند الزبون.
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  StoreProfile copyWith({
    String? storeName,
    String? whatsappNumber,
    double? latitude,
    double? longitude,
  }) =>
      StoreProfile(
        storeCode: storeCode,
        secret: secret,
        storeName: storeName ?? this.storeName,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
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
    final lat = prefs.getDouble(_storeLatKey);
    final lng = prefs.getDouble(_storeLngKey);
    return StoreProfile(
      storeCode: code,
      secret: secret,
      storeName: name,
      whatsappNumber: whatsapp,
      latitude: lat,
      longitude: lng,
    );
  }

  Future<void> updateProfile({String? storeName, String? whatsappNumber}) async {
    final current = state.valueOrNull ?? await build();
    final prefs = await SharedPreferences.getInstance();
    if (storeName != null) await prefs.setString(_storeNameKey, storeName);
    if (whatsappNumber != null) await prefs.setString(_storeWhatsappKey, whatsappNumber);
    state = AsyncData(current.copyWith(storeName: storeName, whatsappNumber: whatsappNumber));
  }

  /// يحفظ موقع المتجر الجغرافي محليًا. يُستدعى عادة بعد أن يحدّد التاجر
  /// موقعه عبر GPS الهاتف في شاشة "متجري".
  Future<void> updateLocation({required double latitude, required double longitude}) async {
    final current = state.valueOrNull ?? await build();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storeLatKey, latitude);
    await prefs.setDouble(_storeLngKey, longitude);
    state = AsyncData(current.copyWith(latitude: latitude, longitude: longitude));
  }

  static String _generateSecret() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }
}
