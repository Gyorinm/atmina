import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/store_api_service.dart';
import '../../application/store_opener.dart';

/// شاشة "البحث الشامل": يكتب الزبون اسم منتج فيبحث عن كل الحوانيت التي
/// توفّره عبر المنصة كلها، مرتبة حسب الأقرب إليه إن كان موقعه متاحًا.
class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) setState(() => _userLocation = LatLng(position.latitude, position.longitude));
    } catch (_) {
      // موقع الزبون اختياري لترتيب النتائج فقط.
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await StoreApiService().searchProducts(query);
      if (_userLocation != null) {
        results.sort((a, b) {
          final da = _distanceKm(a);
          final db = _distanceKm(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      }
      if (mounted) {
        setState(() {
          _results = results;
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

  double? _distanceKm(Map<String, dynamic> result) {
    final lat = result['latitude'];
    final lng = result['longitude'];
    if (_userLocation == null || lat is! num || lng is! num) return null;
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, _userLocation!, LatLng(lat.toDouble(), lng.toDouble()));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('البحث الشامل عن منتج')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'اكتب اسم المنتج (مثال: حليب، سكر...)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر البحث: $_error', textAlign: TextAlign.center)))
                      : _results.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _controller.text.trim().length < 2
                                      ? 'اكتب اسم منتج للبحث عنه في كل المتاجر.'
                                      : 'لم يتم العثور على هذا المنتج في أي متجر حاليًا.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final r = _results[index];
                                final storeCode = r['store_code'] as String? ?? '';
                                final storeName = (r['store_name'] as String?)?.trim();
                                final itemName = r['item_name'] as String? ?? '';
                                final price = (r['price'] as num?)?.toDouble() ?? 0;
                                final stock = (r['stock_quantity'] as num?)?.toInt() ?? 0;
                                final d = _distanceKm(r);
                                final distanceLabel = d == null ? null : (d < 1 ? '${(d * 1000).round()} م' : '${d.toStringAsFixed(1)} كم');

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    leading: const Icon(Icons.storefront_rounded, color: AppColors.navy),
                                    title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                      '${storeName == null || storeName.isEmpty ? storeCode : storeName} • ${stock > 0 ? 'متوفر' : 'نفد المخزون'}${distanceLabel != null ? ' • $distanceLabel' : ''}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                    ),
                                    trailing: Text(
                                      price.toCurrency(),
                                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
                                    ),
                                    onTap: () => openStoreByCode(context, ref, storeCode),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
