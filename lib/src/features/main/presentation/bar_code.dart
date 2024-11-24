import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  BarcodeScannerScreenState createState() => BarcodeScannerScreenState();
}

class BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  static const platform = MethodChannel("channel");
  String _barcodeData = "No data scanned yet";

  Future<void> _startBarcodeScanner() async {
    try {
      final result = await platform.invokeMethod("startBarcodeScanner");
      setState(() {
        _barcodeData = "Scanned data: $result";
      });
    } on PlatformException catch (e) {
      setState(() {
        _barcodeData = "======================= Error: ${e.details}";
        debugPrint("$_barcodeData");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Barcode Scanner")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_barcodeData),
            ElevatedButton(
              onPressed: _startBarcodeScanner,
              child: Text("Start Scanner"),
            ),
          ],
        ),
      ),
    );
  }
}
