import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'shop_list_screen.dart';
import 'profile_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  _DietScreenState createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  int _selectedIndex = 4;
  final _foodController = TextEditingController();
  List<Map<String, dynamic>> _foodLog = [];
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  String _goal = 'maintain';
  double _caloriesConsumed = 0;
  double _proteinConsumed = 0;
  double _fatConsumed = 0;
  double _carbsConsumed = 0;
  double _sugarConsumed = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFoodLog();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final prefDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();

      setState(() {
        _userData = userDoc.exists ? userDoc.data() : null;
        _preferences = prefDoc.exists ? prefDoc.data() : null;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFoodLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diet')
          .doc(dateStr)
          .collection('foods')
          .get();

      setState(() {
        _foodLog = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'calories': (data['calories'] ?? 0.0).toDouble(),
            'protein': (data['protein'] ?? 0.0).toDouble(),
            'fat': (data['fat'] ?? 0.0).toDouble(),
            'carbs': (data['carbs'] ?? 0.0).toDouble(),
            'sugar': (data['sugar'] ?? 0.0).toDouble(),
            'quantity': (data['quantity'] ?? 1.0).toDouble(),
            'timestamp': data['timestamp'] ?? Timestamp.now(),
          };
        }).toList();
        _calculateTotals();
      });
    } catch (e) {
      print("Error loading food log: $e");
    }
  }

  Future<void> _addFood() async {
    final foodName = _foodController.text.trim().toLowerCase();
    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a food name")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fallbackData = {
      'apple': {'calories': 52.0, 'protein': 0.26, 'fat': 0.17, 'carbs': 13.81, 'sugar': 10.39},
      'roti': {'calories': 264.0, 'protein': 6.59, 'fat': 1.94, 'carbs': 55.05, 'sugar': 0.0},
      'chicken': {'calories': 165.0, 'protein': 31.0, 'fat': 3.6, 'carbs': 0.0, 'sugar': 0.0},
      'rice': {'calories': 130.0, 'protein': 2.7, 'fat': 0.3, 'carbs': 28.0, 'sugar': 0.1},
      'default': {'calories': 50.0, 'protein': 2.0, 'fat': 1.0, 'carbs': 10.0, 'sugar': 0.5},
    };

    try {
    const appId = '05fec456';
    const appKey = '9676de0299a58fcd5ba4335697e03639';
      final url = Uri.parse(
          'https://api.edamam.com/api/food-database/v2/parser?ingr=${Uri.encodeQueryComponent(foodName)}&app_id=$appId&app_key=$appKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foodItem = data['parsed']?.isNotEmpty == true ? data['parsed'][0]['food'] : null;

        if (foodItem == null) {
          throw Exception("No food data found for '$foodName'");
        }

        final nutrients = foodItem['nutrients'] ?? {};
        final foodData = {
          'name': foodName,
          'calories': (nutrients['ENERC_KCAL'] ?? fallbackData[foodName] ?? fallbackData['default']!['calories']!).toDouble(),
          'protein': (nutrients['PROCNT'] ?? fallbackData[foodName] ?? fallbackData['default']!['protein']!).toDouble(),
          'fat': (nutrients['FAT'] ?? fallbackData[foodName] ?? fallbackData['default']!['fat']!).toDouble(),
          'carbs': (nutrients['CHOCDF'] ?? fallbackData[foodName] ?? fallbackData['default']!['carbs']!).toDouble(),
          'sugar': (nutrients['SUGAR'] ?? fallbackData[foodName] ?? fallbackData['default']!['sugar']!).toDouble(),
          'quantity': 1.0,
          'timestamp': Timestamp.now(),
        };

        final today = DateTime.now();
        final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('diet')
            .doc(dateStr)
            .collection('foods')
            .add(foodData);

        setState(() {
          _foodLog.add({...foodData, 'id': docRef.id});
          _calculateTotals();
          _foodController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$foodName added to diet log")),
        );
      } else {
        throw Exception("API error: Status ${response.statusCode}");
      }
    } catch (e) {
      print("Error adding food: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

      final foodData = {
        'name': foodName,
        'calories': (fallbackData[foodName]?['calories'] ?? fallbackData['default']!['calories']!).toDouble(),
        'protein': (fallbackData[foodName]?['protein'] ?? fallbackData['default']!['protein']!).toDouble(),
        'fat': (fallbackData[foodName]?['fat'] ?? fallbackData['default']!['fat']!).toDouble(),
        'carbs': (fallbackData[foodName]?['carbs'] ?? fallbackData['default']!['carbs']!).toDouble(),
        'sugar': (fallbackData[foodName]?['sugar'] ?? fallbackData['default']!['sugar']!).toDouble(),
        'quantity': 1.0,
        'timestamp': Timestamp.now(),
      };

      final today = DateTime.now();
      final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diet')
          .doc(dateStr)
          .collection('foods')
          .add(foodData);

      setState(() {
        _foodLog.add({...foodData, 'id': docRef.id});
        _calculateTotals();
        _foodController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$foodName added with default values due to API error")),
      );
    }
  }

  void _calculateTotals() {
    _caloriesConsumed = _foodLog.fold(0, (sum, item) => sum + (item['calories'] * (item['quantity'] ?? 1.0)));
    _proteinConsumed = _foodLog.fold(0, (sum, item) => sum + (item['protein'] * (item['quantity'] ?? 1.0)));
    _fatConsumed = _foodLog.fold(0, (sum, item) => sum + (item['fat'] * (item['quantity'] ?? 1.0)));
    _carbsConsumed = _foodLog.fold(0, (sum, item) => sum + (item['carbs'] * (item['quantity'] ?? 1.0)));
    _sugarConsumed = _foodLog.fold(0, (sum, item) => sum + (item['sugar'] * (item['quantity'] ?? 1.0)));
  }

  Future<void> _removeFood(String? id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid food item")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('diet')
          .doc(dateStr)
          .collection('foods')
          .doc(id)
          .delete();

      setState(() {
        _foodLog.removeWhere((item) => item['id'] == id);
        _calculateTotals();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food item removed")),
      );
    } catch (e) {
      print("Error removing food: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error removing food")),
      );
    }
  }

  Future<void> _updateQuantity(String? id, double newQuantity) async {
    if (id == null || newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid quantity")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    try {
      final index = _foodLog.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        final foodItem = _foodLog[index];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('diet')
            .doc(dateStr)
            .collection('foods')
            .doc(id)
            .update({'quantity': newQuantity});

        setState(() {
          _foodLog[index] = {
            ...foodItem,
            'quantity': newQuantity,
          };
          _calculateTotals();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quantity updated to $newQuantity")),
        );
      }
    } catch (e) {
      print("Error updating quantity: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating quantity")),
      );
    }
  }

  Map<String, dynamic> _calculateDietPlan() {
    final weight = _userData?['weight']?.toDouble() ?? 70.0;
    final height = _userData?['height']?.toDouble() ?? 170.0;
    final age = _userData?['age']?.toDouble() ?? 30.0;
    final activityLevel = 1.55;

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    final bmr = 10 * weight + 6.25 * height - 5 * age + 5;

    final tdee = bmr * activityLevel;

    double targetCalories;
    if (_goal == 'lose') {
      targetCalories = tdee - 500;
    } else if (_goal == 'gain') {
      targetCalories = tdee + 500;
    } else {
      targetCalories = tdee;
    }

    final carbs = (targetCalories * 0.51) / 4;
    final protein = (targetCalories * 0.18) / 4;
    final fat = (targetCalories * 0.33) / 9;
    final sugar = targetCalories * 0.10 / 4;

    return {
      'calories': targetCalories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'sugar': sugar,
      'bmi': bmi,
    };
  }

  List<String> _checkNutrientWarnings(Map<String, dynamic> plan) {
    final warnings = <String>[];
    if (_sugarConsumed > plan['sugar']) {
      warnings.add("Warning: You've exceeded your daily sugar limit!");
    }
    if (_carbsConsumed > plan['carbs']) {
      warnings.add("Warning: You've exceeded your daily carbs limit!");
    }
    if (_fatConsumed > plan['fat']) {
      warnings.add("Warning: You've exceeded your daily fat limit!");
    }
    return warnings;
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
    final dietPlan = _calculateDietPlan();
    final warnings = _checkNutrientWarnings(dietPlan);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Diet Tracker"),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add Food",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _foodController,
                            decoration: InputDecoration(
                              labelText: "Food Name (e.g., roti)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addFood,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF56C596),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Add Food",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (warnings.isNotEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Warnings",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3C72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...warnings.map((warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    warning,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Food Log",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _foodLog.isEmpty
                              ? const Text(
                                  "No foods logged today",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                )
                              : Column(
                                  children: _foodLog.map((food) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        food['name'] as String? ?? 'Unknown',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF1E3C72),
                                                        ),
                                                      ),
                                                      Text(
                                                        "Calories: ${(food['calories'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1)} kcal, Protein: ${(food['protein'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1)}g, Fat: ${(food['fat'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1)}g, Carbs: ${(food['carbs'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1)}g, Sugar: ${(food['sugar'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1)}g",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.blueGrey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () => _updateQuantity(food['id'] as String?, (food['quantity'] as double? ?? 1.0) - 1),
                                                      icon: const Icon(Icons.remove),
                                                      color: const Color(0xFF56C596),
                                                    ),
                                                    Text(
                                                      '${(food['quantity'] as double? ?? 1.0).toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1E3C72),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _updateQuantity(food['id'] as String?, (food['quantity'] as double? ?? 1.0) + 1),
                                                      icon: const Icon(Icons.add),
                                                      color: const Color(0xFF56C596),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _removeFood(food['id'] as String?),
                                                      icon: const Icon(Icons.delete),
                                                      color: Colors.red,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )).toList(),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            "Total: ${_caloriesConsumed.toStringAsFixed(1)} kcal, ${_proteinConsumed.toStringAsFixed(1)}g protein, ${_fatConsumed.toStringAsFixed(1)}g fat, ${_carbsConsumed.toStringAsFixed(1)}g carbs, ${_sugarConsumed.toStringAsFixed(1)}g sugar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                          Text(
                            "Remaining: ${(dietPlan['calories'] - _caloriesConsumed).toStringAsFixed(1)} kcal, ${(dietPlan['protein'] - _proteinConsumed).toStringAsFixed(1)}g protein, ${(dietPlan['fat'] - _fatConsumed).toStringAsFixed(1)}g fat, ${(dietPlan['carbs'] - _carbsConsumed).toStringAsFixed(1)}g carbs, ${(dietPlan['sugar'] - _sugarConsumed).toStringAsFixed(1)}g sugar",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Personalized Diet Plan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButton<String>(
                            value: _goal,
                            onChanged: (value) {
                              setState(() {
                                _goal = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(value: 'maintain', child: Text("Maintain Weight")),
                              DropdownMenuItem(value: 'lose', child: Text("Lose Weight")),
                              DropdownMenuItem(value: 'gain', child: Text("Gain Weight")),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "BMI: ${dietPlan['bmi'].toStringAsFixed(1)}",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          Text(
                            "Target Calories: ${dietPlan['calories'].toStringAsFixed(1)} kcal",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          Text(
                            "Protein: ${dietPlan['protein'].toStringAsFixed(1)} g",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          Text(
                            "Fat: ${dietPlan['fat'].toStringAsFixed(1)} g",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          Text(
                            "Carbs: ${dietPlan['carbs'].toStringAsFixed(1)} g",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          Text(
                            "Sugar: ${dietPlan['sugar'].toStringAsFixed(1)} g",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Sample Foods:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          Text(
                            _goal == 'lose'
                                ? "- Brown rice (150g): 180 kcal, 4g protein, 1g fat, 38g carbs\n- Grilled chicken (100g): 165 kcal, 31g protein, 3g fat, 0g carbs\n- Steamed broccoli (100g): 35 kcal, 3g protein, 0g fat, 7g carbs"
                                : _goal == 'gain'
                                    ? "- Oatmeal (50g): 190 kcal, 6g protein, 3g fat, 32g carbs\n- Peanut butter (30g): 180 kcal, 7g protein, 16g fat, 6g carbs\n- Banana (120g): 90 kcal, 1g protein, 0g fat, 23g carbs"
                                    : "- Whole wheat roti (50g): 150 kcal, 4g protein, 2g fat, 28g carbs\n- Lentil dal (100g): 120 kcal, 7g protein, 2g fat, 17g carbs\n- Mixed vegetables (100g): 50 kcal, 2g protein, 0g fat, 10g carbs",
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                          ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Diet',
          ),
        ],
      ),
    );
  }
}