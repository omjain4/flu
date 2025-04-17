import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'shop_list_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  List<Map<String, String>> suggestedItems = [];

  final List<String> barcodeList = [
    '3274080005003',
    '6111242101180',
    '4000415778507',
    '7622210449283',
    '3175680011480',
    '3268840001008'
  ];

  @override
  void initState() {
    super.initState();
    fetchSuggestedItems();
  }

  Future<void> fetchSuggestedItems() async {
    List<Map<String, String>> fetchedItems = [];
    for (String code in barcodeList) {
      final response = await http.get(Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$code.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final name = product['product_name'] ?? 'Unknown';
          final image = product['image_front_small_url'] ??
              'https://via.placeholder.com/150?text=No+Image';

          fetchedItems.add({
            'name': name,
            'image': image,
          });
        }
      }
    }

    setState(() {
      suggestedItems = fetchedItems;
    });
  }

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
    if (index == 1) {
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
          builder: (context) => const ProfileScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Barcode Scanner"),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      barcode.isEmpty
                          ? "Scan a barcode to begin"
                          : "Scanned: $barcode",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: "Enter Barcode Manually",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: searchBarcode,
                            icon: const Icon(Icons.search),
                            label: const Text("Search"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A5298),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: scanBarcode,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Scan"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Suggested Items",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3C72)),
              ),
            ),
            const SizedBox(height: 10),
            suggestedItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    itemCount: suggestedItems.length,
                    shrinkWrap: true,
                    primary: false,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final item = suggestedItems[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              item['image']!,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey);
                              },
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                item['name']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E3C72),
        selectedItemColor: const Color(0xFF56C596),
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
