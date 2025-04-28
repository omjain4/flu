import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'shop_list_screen.dart';
import 'diet_screen.dart';
import 'cart_provider.dart';
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => NutrientScreen(barcode: barcode),
            transitionsBuilder: (_, animation, __, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: Curves.easeInOutSine),
              );
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ).then((_) async {
          await saveRecentlyViewedItem(barcode);
        });
      }
    } catch (e) {
      setState(() {
        barcode = "Error scanning: $e";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) return; // Already on ScannerScreen
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShopListScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DietScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Label Lens",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Scan, Learn, Eat Smart",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: scanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Start Scanning",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recently Scanned",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (recentlyViewedItems.isNotEmpty)
                    TextButton(
                      onPressed: clearRecentlyViewedItems,
                      child: const Text(
                        "Clear All",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              recentlyViewedItems.isEmpty
                  ? const Center(
                      child: Text(
                        "No recently scanned items",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      itemCount: recentlyViewedItems.length,
                      shrinkWrap: true,
                      primary: false,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => NutrientScreen(barcode: item['barcode']),
                                transitionsBuilder: (_, animation, __, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  final tween = Tween(begin: begin, end: end).chain(
                                    CurveTween(curve: Curves.easeInOutSine),
                                  );
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            ).then((_) async {
                              await saveRecentlyViewedItem(item['barcode']);
                            });
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
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
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: isInCart
                                      ? null
                                      : () {
                                          Provider.of<CartProvider>(context,
                                                  listen: false)
                                              .addToCart({
                                            'name': item['name'],
                                            'code': item['barcode'],
                                            'quantity': 1,
                                          });
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "${item['name']} added to cart!")),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isInCart
                                        ? Colors.grey
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(100, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    isInCart ? 'Added' : 'Add to Cart',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
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
            icon: Icon(Icons.food_bank_outlined),
            label: 'Diet',
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