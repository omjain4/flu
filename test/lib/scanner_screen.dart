import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'shop_list_screen.dart';
import 'search_screen.dart';
import 'cart_provider.dart';
import 'diet_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String barcode = "";
  int _selectedIndex = 0;
  final TextEditingController barcodeController = TextEditingController();
  List<Map<String, dynamic>> recentlyViewedItems = [];

  @override
  void initState() {
    super.initState();
    fetchRecentlyViewedItems();
  }

  Future<void> fetchRecentlyViewedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recently_viewed')
          .orderBy('timestamp', descending: true)
          .limit(6)
          .get();

      List<Map<String, dynamic>> items = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        items.add({
          'name': data['name'] ?? 'Unknown',
          'image': data['image'] ?? 'https://via.placeholder.com/150?text=No+Image',
          'barcode': data['barcode'] ?? '',
        });
      }

      setState(() {
        recentlyViewedItems = items;
      });
    } catch (e) {
      print('Error fetching recently viewed items: $e');
    }
  }

  Future<void> saveRecentlyViewedItem(String barcode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final name = product['product_name'] ?? 'Unknown';
          final image = product['image_front_small_url'] ??
              'https://via.placeholder.com/150?text=No+Image';

          final collection = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recently_viewed');

          await collection.doc(barcode).set({
            'barcode': barcode,
            'name': name,
            'image': image,
            'timestamp': FieldValue.serverTimestamp(),
          });

          final snapshot = await collection
              .orderBy('timestamp', descending: true)
              .get();
          if (snapshot.docs.length > 6) {
            final batch = FirebaseFirestore.instance.batch();
            for (var doc in snapshot.docs.skip(6)) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }

          fetchRecentlyViewedItems();
        }
      }
    } catch (e) {
      print('Error saving recently viewed item: $e');
    }
  }

  Future<void> clearRecentlyViewedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recently_viewed')
          .get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      fetchRecentlyViewedItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recently viewed items cleared!")),
      );
    } catch (e) {
      print('Error clearing recently viewed items: $e');
    }
  }

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        barcode = result.rawContent;
      });
      if (barcode.isNotEmpty) {
        await saveRecentlyViewedItem(barcode);
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
      saveRecentlyViewedItem(inputBarcode);
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ShopListScreen(),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    }else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DietScreen(),
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
                "Recently Viewed Items",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3C72)),
              ),
            ),
            const SizedBox(height: 10),
            if (recentlyViewedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: clearRecentlyViewedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Clear Recently Viewed"),
                ),
              ),
            recentlyViewedItems.isEmpty
                ? const Center(
                    child: Text(
                      "No recently viewed items",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    itemCount: recentlyViewedItems.length,
                    shrinkWrap: true,
                    primary: false,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final item = recentlyViewedItems[index];
                      final isInCart = Provider.of<CartProvider>(context, listen: false)
                          .isItemInCart(item['barcode']);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NutrientScreen(barcode: item['barcode']),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                item['image'],
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image,
                                      size: 60, color: Colors.grey);
                                },
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  item['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: isInCart
                                    ? null
                                    : () {
                                        Provider.of<CartProvider>(context, listen: false)
                                            .addToCart({
                                          'name': item['name'],
                                          'code': item['barcode'],
                                          'quantity': 1,
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "${item['name']} added to cart!")),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInCart ? Colors.grey : const Color(0xFF56C596),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 30),
                                ),
                                child: Text(
                                  isInCart ? 'Already Added to Cart' : 'Add to Cart',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E3C72),
        selectedItemColor: Colors.grey,
        unselectedItemColor: const Color(0xFF000000),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Diet',
          ),
        ],
      ),
    );
  }
}