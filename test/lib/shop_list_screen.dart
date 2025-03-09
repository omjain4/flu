import 'package:flutter/material.dart';

class ShopListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  ShopListScreen({required this.cartItems});

  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  Map<String, int> productQuantities = {}; // Tracks quantities for each product

  @override
  void initState() {
    super.initState();
    // Initialize quantity for each product
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Shopping List")),
      body: widget.cartItems.isEmpty
          ? Center(child: Text("No items in your shopping list yet!"))
          : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final product = widget.cartItems[index];
                final productCode = product["code"] ?? "";
                final productName = product["product_name"] ?? "Unknown Product";
                final imageUrl = product["image_url"] ?? "https://via.placeholder.com/150";
                final quantity = productQuantities[productCode] ?? 1;

                return ListTile(
                  leading: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(productName),
                  subtitle: Text("Quantity: $quantity"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.red),
                        onPressed: () => decreaseQuantity(productCode),
                      ),
                      Text(quantity.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () => increaseQuantity(productCode),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
