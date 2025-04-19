import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'nutrition_screen.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Product")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            String scannedBarcode = barcodes.first.rawValue!;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NutrientScreen(barcode: scannedBarcode)),
            );
          }
        },
      ),
    );
  }
}
