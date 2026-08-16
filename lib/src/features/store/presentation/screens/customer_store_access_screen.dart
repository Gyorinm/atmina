import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/store_opener.dart';
import 'store_qr_scan_screen.dart';

class CustomerStoreAccessScreen extends ConsumerStatefulWidget {
  const CustomerStoreAccessScreen({super.key});

  @override
  ConsumerState<CustomerStoreAccessScreen> createState() => _CustomerStoreAccessScreenState();
}

class _CustomerStoreAccessScreenState extends ConsumerState<CustomerStoreAccessScreen> {
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
    await _openWith(_extractCode(raw));
  }

  Future<void> _openWith(String code) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await openStoreByCode(context, ref, code);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const StoreQrScanScreen()),
    );
    if (result == null || result.isEmpty) return;
    _controller.text = result;
    await _openWith(_extractCode(result));
  }

  String _extractCode(String raw) {
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
                'امسح رمز QR الخاص بالمتجر، أو الصق الرابط أو الكود الذي أرسله لك التاجر عبر واتساب',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loading ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('مسح رمز QR بالكاميرا'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('أو', style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ATM-XXXXXXXXX أو رابط كامل',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
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
