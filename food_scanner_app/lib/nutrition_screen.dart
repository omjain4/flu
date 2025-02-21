import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NutrientScreen extends StatefulWidget {
  final String barcode;
  NutrientScreen({required this.barcode});

  @override
  _NutrientScreenState createState() => _NutrientScreenState();
}

class _NutrientScreenState extends State<NutrientScreen> {
  String productName = "Loading...";
  String ingredients = "Fetching ingredients...";
  String imageUrl = "https://via.placeholder.com/150"; // Placeholder if no image
  Map<String, dynamic> nutriments = {}; // To store nutritional details
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductDetails(widget.barcode);
  }

  Future<void> fetchProductDetails(String barcode) async {
    final url = Uri.parse("https://world.openfoodfacts.org/api/v2/product/$barcode.json");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          productName = data["product"]["product_name"] ?? "Unknown Product";
          ingredients = data["product"]["ingredients_text"] ?? "No ingredients available";
          imageUrl = data["product"]["image_url"] ?? "https://via.placeholder.com/150";
          nutriments = data["product"]["nutriments"] ?? {}; // Get nutritional info
          isLoading = false;
        });
      } else {
        setState(() {
          productName = "Product not found";
          ingredients = "Try scanning again.";
          imageUrl = "https://via.placeholder.com/150";
          nutriments = {};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        productName = "Error fetching data";
        ingredients = "Please check your connection.";
        imageUrl = "https://via.placeholder.com/150";
        nutriments = {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image & Name
                    Center(
                      child: Column(
                        children: [
                          Image.network(imageUrl, width: 150, height: 150, fit: BoxFit.cover),
                          SizedBox(height: 10),
                          Text(productName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Nutritional Information
                    Text("Nutritional Information (per 100g):",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),

                    nutriments.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nutriments.containsKey("energy-kcal_100g"))
                                Text("🔥 Energy: ${nutriments["energy-kcal_100g"]} kcal",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("proteins_100g"))
                                Text("💪 Protein: ${nutriments["proteins_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("fat_100g"))
                                Text("🍳 Fat: ${nutriments["fat_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("carbohydrates_100g"))
                                Text("🍞 Carbohydrates: ${nutriments["carbohydrates_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("sugars_100g"))
                                Text("🍭 Sugars: ${nutriments["sugars_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("fiber_100g"))
                                Text("🌾 Fiber: ${nutriments["fiber_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                              if (nutriments.containsKey("salt_100g"))
                                Text("🧂 Salt: ${nutriments["salt_100g"]} g",
                                    style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : Text("Nutritional data not available",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),

                    SizedBox(height: 20),

                    // Ingredients Section
                    Text("Ingredients:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(ingredients, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
    );
  }
}
