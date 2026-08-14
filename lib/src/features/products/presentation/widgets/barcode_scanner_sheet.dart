import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';

class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetectedCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasDetectedCode) {
                return;
              }

              final rawValue = capture.barcodes
                  .map((barcode) => barcode.rawValue?.trim())
                  .whereType<String>()
                  .firstWhere(
                    (value) => value.isNotEmpty,
                    orElse: () => '',
                  );

              if (rawValue.isEmpty || !mounted) {
                return;
              }

              _hasDetectedCode = true;
              Navigator.of(context).pop(rawValue);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _controller.toggleTorch,
                        icon: const Icon(Icons.flashlight_on_rounded),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.accent, width: 3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'وجّه الكاميرا نحو الباركود ليتم إدخاله تلقائيًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
