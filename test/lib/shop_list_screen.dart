import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const ShopListScreen({super.key, required this.cartItems});

  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  Map<String, int> productQuantities = {};

  @override
  void initState() {
    super.initState();
    for (var product in widget.cartItems) {
      productQuantities[product["code"] ?? ""] = product["quantity"] ?? 1;
    }
  }

  void increaseQuantity(String productCode) {
    setState(() {
      productQuantities[productCode] = (productQuantities[productCode] ?? 1) + 1;
    });
  }

  void decreaseQuantity(String productCode) {
    setState(() {
      if (productQuantities[productCode] != null && productQuantities[productCode]! > 1) {
        productQuantities[productCode] = productQuantities[productCode]! - 1;
      }
    });
  }

  Future<int?> _getProductRating(String barcode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ratings')
          .doc(barcode)
          .get();
      if (doc.exists) {
        final data = doc.data();
        return data?['score'] as int?;
      }
      return null;
    } catch (e) {
      print("Error fetching rating: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Shopping List")),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text("No items in your shopping list yet!"))
          : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final product = widget.cartItems[index];
                final productCode = product["code"] ?? "";
                final productName = product["product_name"] ?? "Unknown Product";
                final imageUrl = product["image_url"] ?? "https://via.placeholder.com/150";
                final quantity = productQuantities[productCode] ?? 1;

                return FutureBuilder<int?>(
                  future: _getProductRating(productCode),
                  builder: (context, snapshot) {
                    String ratingText = "No rating";
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      ratingText = "Loading rating...";
                    } else if (snapshot.hasData && snapshot.data != null) {
                      ratingText = "Rating: ${snapshot.data}/5";
                    }

                    return ListTile(
                      leading: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(productName),
                      subtitle: Text("Quantity: $quantity\n$ratingText"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red),
                            onPressed: () => decreaseQuantity(productCode),
                          ),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => increaseQuantity(productCode),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}