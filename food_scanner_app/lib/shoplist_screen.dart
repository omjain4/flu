import 'package:flutter/material.dart';

class ShopListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(String) onIncrease;
  final Function(String) onDecrease;

  ShopListScreen({required this.cartItems, required this.onIncrease, required this.onDecrease});

  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
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
                return ListTile(
                  leading: Image.network(
                    product["image_url"] ?? "https://via.placeholder.com/150",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product["product_name"] ?? "Unknown Product"),
                  subtitle: Text("Quantity: ${product["quantity"]}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.red),
                        onPressed: () => widget.onDecrease(product["code"]),
                      ),
                      Text(product["quantity"].toString()),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () => widget.onIncrease(product["code"]),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
