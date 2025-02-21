import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nutrition_screen.dart'; // Import the NutrientScreen

class SearchScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  SearchScreen({required this.onAddToCart});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  Set<String> addedProducts = {}; // Keeps track of added products
  bool isLoading = false;

  Future<void> searchProduct(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      searchResults = [];
      addedProducts.clear(); // Reset added products on new search
    });

    final url = Uri.parse("https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&json=1");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data["products"] ?? [];
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        searchResults = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void navigateToNutritionScreen(String barcode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutrientScreen(barcode: barcode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Food Products")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search for food...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: searchProduct,
            ),
          ),

          isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final product = searchResults[index];
                      final productName = product["product_name"] ?? "Unknown Product";
                      final productCode = product["code"] ?? "";

                      return ListTile(
                        title: Text(productName),
                        onTap: () => navigateToNutritionScreen(productCode), // Navigate when tapped
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
