import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

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
      'apple': {
        'calories': 52.0,
        'protein': 0.26,
        'fat': 0.17,
        'carbs': 13.81,
        'sugar': 10.39
      },
      'roti': {
        'calories': 264.0,
        'protein': 6.59,
        'fat': 1.94,
        'carbs': 55.05,
        'sugar': 0.0
      },
      'chicken': {
        'calories': 165.0,
        'protein': 31.0,
        'fat': 3.6,
        'carbs': 0.0,
        'sugar': 0.0
      },
      'rice': {
        'calories': 130.0,
        'protein': 2.7,
        'fat': 0.3,
        'carbs': 28.0,
        'sugar': 0.1
      },
      'default': {
        'calories': 50.0,
        'protein': 2.0,
        'fat': 1.0,
        'carbs': 10.0,
        'sugar': 0.5
      },
    };

    try {
      const appId = '05fec456';
      const appKey = '9676de0299a58fcd5ba4335697e03639';
      final url = Uri.parse(
          'https://api.edamam.com/api/food-database/v2/parser?ingr=${Uri.encodeQueryComponent(foodName)}&app_id=$appId&app_key=$appKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foodItem = data['parsed']?.isNotEmpty == true
            ? data['parsed'][0]['food']
            : null;

        if (foodItem == null) {
          throw Exception("No food data found for '$foodName'");
        }

        final nutrients = foodItem['nutrients'] ?? {};
        final foodData = {
          'name': foodName,
          'calories': (nutrients['ENERC_KCAL'] ??
                  fallbackData[foodName] ??
                  fallbackData['default']!['calories']!)
              .toDouble(),
          'protein': (nutrients['PROCNT'] ??
                  fallbackData[foodName] ??
                  fallbackData['default']!['protein']!)
              .toDouble(),
          'fat': (nutrients['FAT'] ??
                  fallbackData[foodName] ??
                  fallbackData['default']!['fat']!)
              .toDouble(),
          'carbs': (nutrients['CHOCDF'] ??
                  fallbackData[foodName] ??
                  fallbackData['default']!['carbs']!)
              .toDouble(),
          'sugar': (nutrients['SUGAR'] ??
                  fallbackData[foodName] ??
                  fallbackData['default']!['sugar']!)
              .toDouble(),
          'quantity': 1.0,
          'timestamp': Timestamp.now(),
        };

        final today = DateTime.now();
        final dateStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
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
        'calories': (fallbackData[foodName]?['calories'] ??
                fallbackData['default']!['calories']!)
            .toDouble(),
        'protein': (fallbackData[foodName]?['protein'] ??
                fallbackData['default']!['protein']!)
            .toDouble(),
        'fat': (fallbackData[foodName]?['fat'] ??
                fallbackData['default']!['fat']!)
            .toDouble(),
        'carbs': (fallbackData[foodName]?['carbs'] ??
                fallbackData['default']!['carbs']!)
            .toDouble(),
        'sugar': (fallbackData[foodName]?['sugar'] ??
                fallbackData['default']!['sugar']!)
            .toDouble(),
        'quantity': 1.0,
        'timestamp': Timestamp.now(),
      };

      final today = DateTime.now();
      final dateStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
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
        SnackBar(
            content:
                Text("$foodName added with default values due to API error")),
      );
    }
  }

  void _calculateTotals() {
    _caloriesConsumed = _foodLog.fold(
        0, (sum, item) => sum + (item['calories'] * (item['quantity'] ?? 1.0)));
    _proteinConsumed = _foodLog.fold(
        0, (sum, item) => sum + (item['protein'] * (item['quantity'] ?? 1.0)));
    _fatConsumed = _foodLog.fold(
        0, (sum, item) => sum + (item['fat'] * (item['quantity'] ?? 1.0)));
    _carbsConsumed = _foodLog.fold(
        0, (sum, item) => sum + (item['carbs'] * (item['quantity'] ?? 1.0)));
    _sugarConsumed = _foodLog.fold(
        0, (sum, item) => sum + (item['sugar'] * (item['quantity'] ?? 1.0)));
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
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
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
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
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

  Map<String, dynamic> _calculateDietPlan({String goal = 'maintain'}) {
    final weight = _userData?['weight']?.toDouble() ?? 70.0;
    final height = _userData?['height']?.toDouble() ?? 170.0;
    final age = _userData?['age']?.toDouble() ?? 30.0;
    final activityLevel = 1.55;

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    final bmr = 10 * weight + 6.25 * height - 5 * age + 5;

    final tdee = bmr * activityLevel;

    double targetCalories;
    if (goal == 'lose') {
      targetCalories = tdee - 500;
    } else if (goal == 'gain') {
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

  TableRow _buildTableRow(String label, String value) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
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
    final dietPlan = _calculateDietPlan(goal: _goal);
    final warnings = _checkNutrientWarnings(dietPlan);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Diet Log", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(DateTime.now()),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.show_chart, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Daily Summary",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildProgressBar("Calories", _caloriesConsumed, dietPlan['calories'], ""),
                              _buildProgressBar("Protein", _proteinConsumed, dietPlan['protein'], "g"),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildProgressBar("Carbs", _carbsConsumed, dietPlan['carbs'], "g"),
                              _buildProgressBar("Fat", _fatConsumed, dietPlan['fat'], "g"),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildProgressBar("Sugar", _sugarConsumed, dietPlan['sugar'], "g"),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.4 - 16), // Placeholder
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fitness_center, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Weight Goal",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
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
                            isExpanded: true,
                            underline: Container(height: 1, color: Colors.grey[300]),
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (warnings.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Warnings",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            ...warnings.map((warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    warning,
                                    style: const TextStyle(fontSize: 16, color: Colors.red),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fastfood, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Today's Food Log",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _foodLog.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No foods logged today",
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 16.0,
                                    columns: const [
                                      DataColumn(label: Text('Food', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Protein (g)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Fat (g)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Carbs (g)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Sugar (g)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataColumn(label: Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                                    ],
                                    rows: _foodLog.map((food) {
                                      final totalCalories = (food['calories'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1);
                                      final totalProtein = (food['protein'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1);
                                      final totalFat = (food['fat'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1);
                                      final totalCarbs = (food['carbs'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1);
                                      final totalSugar = (food['sugar'] * (food['quantity'] ?? 1.0)).toStringAsFixed(1);
                                      final quantity = (food['quantity'] ?? 1.0).toStringAsFixed(0);

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(food['name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 16, color: Colors.black87))),
                                          DataCell(Text(totalCalories, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                          DataCell(Text(totalProtein, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                          DataCell(Text(totalFat, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                          DataCell(Text(totalCarbs, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                          DataCell(Text(totalSugar, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () => _updateQuantity(food['id'] as String?, (food['quantity'] as double? ?? 1.0) - 1),
                                                icon: const Icon(Icons.remove, size: 20, color: Colors.green),
                                              ),
                                              Text(
                                                quantity,
                                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                              ),
                                              IconButton(
                                                onPressed: () => _updateQuantity(food['id'] as String?, (food['quantity'] as double? ?? 1.0) + 1),
                                                icon: const Icon(Icons.add, size: 20, color: Colors.green),
                                              ),
                                              IconButton(
                                                onPressed: () => _removeFood(food['id'] as String?),
                                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add Food"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _foodController,
                    decoration: const InputDecoration(
                      labelText: "Food Name (e.g., roti)",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    _addFood();
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProgressBar(String label, double current, double total, String unit) {
    final percentage = (current / total).clamp(0.0, 1.0);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4 - 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            "${current.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}$unit",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          CustomLinearProgressIndicator(
            value: percentage,
          ),
        ],
      ),
    );
  }
}

class CustomLinearProgressIndicator extends StatelessWidget {
  final double value;

  const CustomLinearProgressIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      minHeight: 8,
    );
  }
}