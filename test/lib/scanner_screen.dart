import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'shop_list_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String barcode = "";
  List<Map<String, dynamic>> cartItems = [];
  int _selectedIndex = 0;
  final TextEditingController barcodeController = TextEditingController();

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        barcode = result.rawContent;
      });
      if (barcode.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutrientScreen(barcode: barcode),
          ),
        );
      }
    } catch (e) {
      setState(() {
        barcode = "Error scanning: $e";
      });
    }
  }

  void searchBarcode() {
    final inputBarcode = barcodeController.text.trim();
    if (inputBarcode.isNotEmpty) {
      setState(() {
        barcode = inputBarcode;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutrientScreen(barcode: inputBarcode),
        ),
      );
      barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a barcode")),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Stay on scanner screen
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopListScreen(cartItems: cartItems),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(), // No email parameter
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barcode Scanner"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              barcode.isEmpty ? "Scan a barcode" : "Scanned: $barcode",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: barcodeController,
                decoration: const InputDecoration(
                  labelText: "Enter Barcode",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: searchBarcode,
              child: const Text("Search Barcode"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: scanBarcode,
              child: const Text("Start Scan"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}