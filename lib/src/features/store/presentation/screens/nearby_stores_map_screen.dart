import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/store_api_service.dart';
import '../../application/store_opener.dart';

/// شاشة تعرض على خريطة (OpenStreetMap، مجانية بدون مفتاح API) كل
/// المتاجر التي حدّد أصحابها موقعها الجغرافي، بالإضافة إلى موقع الزبون
/// الحالي، لمساعدته على إيجاد أقرب حانوت يستعمل تطبيق Atmina.
class NearbyStoresMapScreen extends ConsumerStatefulWidget {
  const NearbyStoresMapScreen({super.key});

  @override
  ConsumerState<NearbyStoresMapScreen> createState() => _NearbyStoresMapScreenState();
}

class _NearbyStoresMapScreenState extends ConsumerState<NearbyStoresMapScreen> {
  static const LatLng _fallbackCenter = LatLng(33.5731, -7.5898); // الدار البيضاء كموقع افتراضي

  final MapController _mapController = MapController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _stores = const [];
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadStores(), _loadUserLocation()]);
  }

  Future<void> _loadStores() async {
    try {
      final stores = await StoreApiService().fetchAllStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() => _userLocation = LatLng(position.latitude, position.longitude));
        _mapController.move(_userLocation!, 13);
      }
    } catch (_) {
      // موقع الزبون اختياري لعرض الخريطة؛ نتجاهل الخطأ بصمت هنا لأن كل
      // حالة فشل معروضة أصلًا بشكل غير مزعج عبر عدم ظهور علامة الزبون.
    }
  }

  double _distanceKm(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, a, b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _userLocation ?? _fallbackCenter;

    final sortedStores = List<Map<String, dynamic>>.from(_stores);
    if (_userLocation != null) {
      sortedStores.sort((a, b) {
        final da = _distanceKm(_userLocation!, LatLng((a['latitude'] as num).toDouble(), (a['longitude'] as num).toDouble()));
        final db = _distanceKm(_userLocation!, LatLng((b['latitude'] as num).toDouble(), (b['longitude'] as num).toDouble()));
        return da.compareTo(db);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المتاجر القريبة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('تعذر تحميل المتاجر: $_error', textAlign: TextAlign.center),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: _userLocation != null ? 13 : 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.atmina_pos',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.my_location_rounded, color: Colors.blue, size: 32),
                                ),
                              ..._stores.map((store) {
                                final lat = (store['latitude'] as num).toDouble();
                                final lng = (store['longitude'] as num).toDouble();
                                final name = (store['store_name'] as String?)?.trim();
                                final code = store['store_code'] as String? ?? '';
                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 44,
                                  height: 44,
                                  child: GestureDetector(
                                    onTap: () => _openStore(code, name),
                                    child: const Icon(Icons.storefront_rounded, color: AppColors.navy, size: 36),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_stores.isEmpty)
                      const Expanded(
                        flex: 2,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'لا توجد بعد متاجر حدّدت موقعها الجغرافي بالقرب منك.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: sortedStores.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final store = sortedStores[index];
                            final name = (store['store_name'] as String?)?.trim();
                            final code = store['store_code'] as String? ?? '';
                            final displayName = (name == null || name.isEmpty) ? code : name;
                            String? distanceLabel;
                            if (_userLocation != null) {
                              final d = _distanceKm(
                                _userLocation!,
                                LatLng((store['latitude'] as num).toDouble(), (store['longitude'] as num).toDouble()),
                              );
                              distanceLabel = d < 1 ? '${(d * 1000).round()} م' : '${d.toStringAsFixed(1)} كم';
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                leading: const Icon(Icons.storefront_rounded, color: AppColors.navy),
                                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                trailing: distanceLabel != null
                                    ? Text(distanceLabel, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted))
                                    : const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
                                onTap: () => _openStore(code, name),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Future<void> _openStore(String code, String? name) async {
    if (code.isEmpty) return;
    await openStoreByCode(context, ref, code);
  }
}
