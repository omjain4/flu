import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'shop_list_screen.dart';
import 'profile_screen.dart';

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
  List<String> goodIngredients = [];
  List<String> harmfulIngredients = [];
  List<String> badIngredients = [];
  List<String> otherIngredients = [];
  int totalIngredients = 0;
  bool isAddedToCart = false;
  int _selectedIndex = 0; // Not a primary tab

  final List<String> predefinedBadIngredients = [
    'high fructose corn syrup',
    'artificial sweeteners',
    'trans fat',
    'partially hydrogenated oil',
    'aspartame',
    'sodium benzoate',
  ];

  @override
  void initState() {
    super.initState();
    fetchProductDetails(widget.barcode);
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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

  void _clusterIngredients(
      String ingredientsText, List<dynamic>? additives, List<dynamic>? allergens, Map<String, dynamic>? preferences) {
    final ingredientList = ingredientsText
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final ingredientsPrefer = List<String>.from(preferences?['ingredients_prefer'] ?? []);
    final ingredientsAvoid = List<String>.from(preferences?['ingredients_avoid'] ?? []);
    final allergenList = allergens?.map((a) => a.toString().split(':').last.toLowerCase()).toList() ?? [];

    goodIngredients = [];
    harmfulIngredients = [];
    badIngredients = [];
    otherIngredients = [];

    for (var ingredient in ingredientList) {
      if (ingredientsPrefer.contains(ingredient) || ingredient.contains('organic') || ingredient.contains('fiber')) {
        goodIngredients.add(ingredient);
      } else if (ingredientsAvoid.contains(ingredient) || allergenList.any((a) => ingredient.contains(a))) {
        harmfulIngredients.add(ingredient);
      } else if (predefinedBadIngredients.any((bad) => ingredient.contains(bad))) {
        badIngredients.add(ingredient);
      } else {
        otherIngredients.add(ingredient);
      }
    }

    for (var additive in additives ?? []) {
      final additiveText = additive.toString().split(':').last.toLowerCase();
      if (!harmfulIngredients.contains(additiveText)) {
        harmfulIngredients.add(additiveText);
      }
    }

    totalIngredients = ingredientList.length + (additives?.length ?? 0);
  }

  Future<void> _calculateAndStoreRating(
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? userData,
    Map<String, dynamic> nutriments,
    String ingredientsText,
  ) async {
    if (userData == null || !userData.containsKey('weight') || !userData.containsKey('height')) {
      setState(() {
        personalizedRating = null;
        ratingMessage = "Please complete your profile to see personalized ratings";
      });
      return;
    }

    final weight = double.tryParse(userData['weight'].toString()) ?? 0;
    final height = double.tryParse(userData['height'].toString()) ?? 0;
    final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0;

    preferences ??= {
      'nutrient_limits': {},
      'ingredients_avoid': [],
      'ingredients_prefer': [],
    };

    final nutrientLimits = Map<String, dynamic>.from(preferences['nutrient_limits'] ?? {});
    final maxSugar = nutrientLimits['sugar']?['max']?.toDouble() ?? (bmi > 30 ? 2.0 : bmi > 25 ? 3.0 : 5.0);
    final minFiber = nutrientLimits['fiber']?['min']?.toDouble() ?? (bmi > 25 ? 4.0 : 3.0);

    final ingredientsAvoid = List<String>.from(preferences['ingredients_avoid'] ?? []);
    final ingredientsPrefer = List<String>.from(preferences['ingredients_prefer'] ?? []);

    int totalCriteria = 0;
    int metCriteria = 0;

    if (nutriments.containsKey('sugars_100g')) {
      totalCriteria++;
      final sugarValue = (nutriments['sugars_100g'] as num?)?.toDouble() ?? 0;
      if (sugarValue <= maxSugar) metCriteria++;
    }

    if (nutriments.containsKey('fiber_100g')) {
      totalCriteria++;
      final fiberValue = (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0;
      if (fiberValue >= minFiber) metCriteria++;
    }

    final ingredientsLower = ingredientsText.toLowerCase();
    for (var ingredient in ingredientsAvoid) {
      totalCriteria++;
      if (!ingredientsLower.contains(ingredient)) metCriteria++;
    }

    for (var ingredient in ingredientsPrefer) {
      totalCriteria++;
      if (ingredientsLower.contains(ingredient)) metCriteria++;
    }

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
          ingredients = data["product"]["ingredients_text"] ?? "No ingredients found. Stay curious!";
          imageUrl = data["product"]["image_url"] ?? "https://via.placeholder.com/150";
          nutriments = data["product"]["nutriments"] ?? {};
          isLoading = false;
        });

        final preferences = await _getUserPreferences();
        final userData = await _getUserData();
        _clusterIngredients(
          ingredients,
          data["product"]["additives_tags"],
          data["product"]["allergens_tags"],
          preferences,
        );
        await _calculateAndStoreRating(preferences, userData, nutriments, ingredients);
      } else {
        setState(() {
          productName = "Product not found";
          ingredients = "Oops! We couldn't find any ingredients. How about trying another product?";
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
        ingredients = "Please check your connection or try again later. Stay positive!";
        imageUrl = "https://via.placeholder.com/150";
        nutriments = {};
        isLoading = false;
        personalizedRating = null;
        ratingMessage = "Error fetching data";
      });
    }
  }

  void addToCart() {
    if (isAddedToCart) return;

    Provider.of<CartProvider>(context, listen: false).addToCart({
      'name': productName,
      'code': widget.barcode,
      'quantity': 1,
    });
    setState(() {
      isAddedToCart = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$productName added to cart!")),
    );
  }

  Widget nutrientRow(String label, String emoji, dynamic value, String unit) {
    return value != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text("$emoji ", style: const TextStyle(fontSize: 18)),
                Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                Text("$value $unit", style: const TextStyle(color: Color(0xFF1E3C72))),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget ingredientSection(String title, List<String> ingredients, Color color) {
    return ingredients.isNotEmpty
        ? ExpansionTile(
            title: Text(
              '$title (${ingredients.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            children: ingredients
                .map((ingredient) => ListTile(
                      title: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                    ))
                .toList(),
          )
        : const SizedBox();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    } else if (index == 1) {
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
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Product Details"),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ratingMessage,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: personalizedRating != null ? const Color(0xFF56C596) : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isAddedToCart ? null : addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAddedToCart ? Colors.grey : const Color(0xFF56C596),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isAddedToCart ? 'Added to Cart' : 'Add to Cart',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nutritional Information (per 100g)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: nutriments.isEmpty
                          ? Column(
                              children: [
                                const Icon(
                                  Icons.question_answer,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Nutritional information is currently unavailable. Stay curious and explore more!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                nutrientRow("Energy", "🔥", nutriments["energy-kcal_100g"], "kcal"),
                                nutrientRow("Protein", "💪", nutriments["proteins_100g"], "g"),
                                nutrientRow("Fat", "🍳", nutriments["fat_100g"], "g"),
                                nutrientRow("Carbs", "🍞", nutriments["carbohydrates_100g"], "g"),
                                nutrientRow("Sugar", "🍬", nutriments["sugars_100g"], "g"),
                                nutrientRow("Fiber", "🌾", nutriments["fiber_100g"], "g"),
                                nutrientRow("Salt", "🧂", nutriments["salt_100g"], "g"),
                                nutrientRow("Sodium", "🧪", nutriments["sodium_100g"], "g"),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ingredients == "No ingredients found. Stay curious!"
                          ? Column(
                              children: [
                                const Icon(
                                  Icons.info,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ingredients,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Ingredients: $totalIngredients',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3C72),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Harmful: ${harmfulIngredients.length}, Good: ${goodIngredients.length}, Bad: ${badIngredients.length}, Other: ${otherIngredients.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ingredientSection("Good Ingredients", goodIngredients, Colors.green),
                                ingredientSection("Harmful Ingredients", harmfulIngredients, Colors.orange),
                                ingredientSection("Bad Ingredients", badIngredients, Colors.red),
                                ingredientSection("Other Ingredients", otherIngredients, Colors.blueGrey),
                              ],
                            ),
                    ),
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
        ],
      ),
    );
  }
}