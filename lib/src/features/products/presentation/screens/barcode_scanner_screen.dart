import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/datasources/app_database.dart';
import '../../domain/models/product.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes.map((b) => b.rawValue).firstWhere(
      (value) => value != null && value.trim().isNotEmpty,
      orElse: () => null,
    );
    if (value == null || value.trim().isEmpty) return;
    _handled = true;
    await _controller.stop();
    final product = await AppDatabase.instance.findProductByBarcode(value.trim());
    if (!mounted) return;
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح الباركود')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('وجّه الكاميرا نحو الباركود. سيتم البحث عنه في المخزون المحلي.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keeps the return type explicit for callers that want to open the scanner.
typedef BarcodeScanResult = Product?;
