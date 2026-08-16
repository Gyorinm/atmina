import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/store_payload.dart';
import '../presentation/screens/customer_catalog_screen.dart';
import 'customer_session_controller.dart';
import 'store_api_service.dart';

Future<void> openStoreByCode(BuildContext context, WidgetRef ref, String code) async {
  final trimmedCode = code.trim();
  if (trimmedCode.isEmpty) return;
  try {
    final json = await StoreApiService().fetchCatalog(trimmedCode);
    final payload = StorePayload.fromMap(json, fallbackCode: trimmedCode);
    await ref.read(customerSessionControllerProvider.notifier).saveLastStore(
          trimmedCode,
          payload.storeName,
        );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CustomerCatalogScreen(payload: payload)),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }
}
