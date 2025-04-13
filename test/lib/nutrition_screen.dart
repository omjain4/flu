import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutrientScreen extends StatefulWidget {
  final String barcode;
  const NutrientScreen({super.key, required this.barcode});

  @override
  _NutrientScreenState createState() => _NutrientScreenState();
}

class _NutrientScreenState extends State<NutrientScreen> {
  String productName = "Loading...";
  String ingredients = "Fetching ingredients...";
  String imageUrl = "https://via.placeholder.com/150";
  Map<String, dynamic> nutriments = {};
  bool isLoading = true;
  int? personalizedRating;
  String ratingMessage = "Calculating rating...";

  @override
  void initState() {
    super.initState();
    fetchProductDetails(widget.barcode);
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching preferences: $e");
      return null;
    }
  }

  Future<void> _calculateAndStoreRating(
      Map<String, dynamic>? preferences,
      Map<String, dynamic>? userData,
      Map<String, dynamic> nutriments,
      String ingredientsText) async {
    if (userData == null || !userData.containsKey('weight') || !userData.containsKey('height')) {
      setState(() {
        personalizedRating = null;
        ratingMessage = "Please complete your profile to see personalized ratings";
      });
      return;
    }

    // Calculate BMI
    final weight = double.tryParse(userData['weight'].toString()) ?? 0;
    final height = double.tryParse(userData['height'].toString()) ?? 0;
    final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0;

    // Initialize preferences if null
    preferences ??= {
      'nutrient_limits': {},
      'ingredients_avoid': [],
      'ingredients_prefer': [],
    };

    // Use manual preferences if set; otherwise, apply BMI-based defaults
    final nutrientLimits = Map<String, dynamic>.from(preferences['nutrient_limits'] ?? {});
    final maxSugar = nutrientLimits['sugar']?['max']?.toDouble() ??
        (bmi > 30 ? 2.0 : bmi > 25 ? 3.0 : 5.0);
    final minFiber = nutrientLimits['fiber']?['min']?.toDouble() ??
        (bmi > 25 ? 4.0 : 3.0);

    final ingredientsAvoid = List<String>.from(preferences['ingredients_avoid'] ?? []);
    final ingredientsPrefer = List<String>.from(preferences['ingredients_prefer'] ?? []);

    int totalCriteria = 0;
    int metCriteria = 0;

    // Debug logs
    print("Product: $productName, Sugar: ${nutriments['sugars_100g']}, Fiber: ${nutriments['fiber_100g']}");
    print("User Preferences - Max Sugar: $maxSugar, Min Fiber: $minFiber");
    print("Avoid: $ingredientsAvoid, Prefer: $ingredientsPrefer");

    // Evaluate nutrient limits
    if (nutriments.containsKey('sugars_100g')) {
      totalCriteria++;
      final sugarValue = (nutriments['sugars_100g'] as num?)?.toDouble() ?? 0;
      if (sugarValue <= maxSugar) {
        metCriteria++;
      }
    }
    if (nutriments.containsKey('fiber_100g')) {
      totalCriteria++;
      final fiberValue = (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0;
      if (fiberValue >= minFiber) {
        metCriteria++;
      }
    }

    // Evaluate ingredients
    final ingredientsLower = ingredientsText.toLowerCase();
    for (var ingredient in ingredientsAvoid) {
      totalCriteria++;
      if (!ingredientsLower.contains(ingredient)) {
        metCriteria++;
      }
    }
    for (var ingredient in ingredientsPrefer) {
      totalCriteria++;
      if (ingredientsLower.contains(ingredient)) {
        metCriteria++;
      }
    }

    // Calculate score
    if (totalCriteria == 0) {
      setState(() {
        personalizedRating = null;
        ratingMessage = "Insufficient data for rating";
      });
      return;
    }

    final score = ((metCriteria / totalCriteria) * 5).round();
    setState(() {
      personalizedRating = score;
      ratingMessage = "Personalized Rating: $score/5";
    });

    // Store rating in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ratings')
            .doc(widget.barcode)
            .set({
          'score': score,
          'date_rated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error storing rating: $e");
      }
    }
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
          nutriments = data["product"]["nutriments"] ?? {};
          isLoading = false;
        });

        // Calculate personalized rating
        final preferences = await _getUserPreferences();
        final userData = await _getUserData();
        await _calculateAndStoreRating(preferences, userData, nutriments, ingredients);
      } else {
        setState(() {
          productName = "Product not found";
          ingredients = "Try scanning again.";
          imageUrl = "https://via.placeholder.com/150";
          nutriments = {};
          isLoading = false;
          personalizedRating = null;
          ratingMessage = "Product not found";
        });
      }
    } catch (e) {
      setState(() {
        productName = "Error fetching data";
        ingredients = "Please check your connection.";
        imageUrl = "https://via.placeholder.com/150";
        nutriments = {};
        isLoading = false;
        personalizedRating = null;
        ratingMessage = "Error fetching data";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Image.network(imageUrl, width: 150, height: 150, fit: BoxFit.cover),
                          const SizedBox(height: 10),
                          Text(
                            productName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ratingMessage,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: personalizedRating != null ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Nutritional Information (per 100g):",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    nutriments.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (nutriments.containsKey("energy-kcal_100g"))
                                Text(
                                  "🔥 Energy: ${nutriments["energy-kcal_100g"]} kcal",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("proteins_100g"))
                                Text(
                                  "💪 Protein: ${nutriments["proteins_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("fat_100g"))
                                Text(
                                  "🍳 Fat: ${nutriments["fat_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("carbohydrates_100g"))
                                Text(
                                  "🍞 Carbohydrates: ${nutriments["carbohydrates_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("sugars_100g"))
                                Text(
                                  "🍭 Sugars: ${nutriments["sugars_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("fiber_100g"))
                                Text(
                                  "🌾 Fiber: ${nutriments["fiber_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (nutriments.containsKey("salt_100g"))
                                Text(
                                  "🧂 Salt: ${nutriments["salt_100g"]} g",
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          )
                        : const Text(
                            "Nutritional data not available",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                    const SizedBox(height: 20),
                    const Text(
                      "Ingredients:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(ingredients, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
    );
  }
}