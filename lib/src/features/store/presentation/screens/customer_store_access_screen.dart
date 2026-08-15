import 'package:flutter/material.dart';

import '../../domain/store_payload.dart';
import 'customer_catalog_screen.dart';

class CustomerStoreAccessScreen extends StatefulWidget {
  const CustomerStoreAccessScreen({super.key});

  @override
  State<CustomerStoreAccessScreen> createState() => _CustomerStoreAccessScreenState();
}

class _CustomerStoreAccessScreenState extends State<CustomerStoreAccessScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'يرجى لصق رابط أو كود المتجر.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final encoded = _extractEncodedSegment(raw);
      final payload = StorePayload.decode(encoded);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CustomerCatalogScreen(payload: payload)),
      );
    } catch (_) {
      setState(() => _error = 'الرابط أو الكود غير صالح. تأكد أنك لصقت الرابط كاملاً كما أرسله التاجر.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _extractEncodedSegment(String raw) {
    if (raw.contains('://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }
    if (raw.contains('/')) {
      return raw.substring(raw.lastIndexOf('/') + 1);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الدخول إلى متجر')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'الصق الرابط الذي أرسله لك التاجر عبر واتساب',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'atmina://store/...',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loading ? null : _open,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.storefront_rounded),
                label: Text(_loading ? 'جارٍ الفتح...' : 'فتح المتجر'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
