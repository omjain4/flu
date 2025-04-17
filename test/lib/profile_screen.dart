import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController maxSugarController = TextEditingController();
  final TextEditingController minFiberController = TextEditingController();
  final TextEditingController avoidIngredientsController =
      TextEditingController();
  final TextEditingController preferIngredientsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          maxSugarController.text =
              data['nutrient_limits']?['sugar']?['max']?.toString() ?? '';
          minFiberController.text =
              data['nutrient_limits']?['fiber']?['min']?.toString() ?? '';
          avoidIngredientsController.text =
              (data['ingredients_avoid'] as List<dynamic>?)?.join(', ') ?? '';
          preferIngredientsController.text =
              (data['ingredients_prefer'] as List<dynamic>?)?.join(', ') ?? '';
        });
      }
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  @override
  void dispose() {
    maxSugarController.dispose();
    minFiberController.dispose();
    avoidIngredientsController.dispose();
    preferIngredientsController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save preferences")),
      );
      return;
    }

    final preferences = {
      'nutrient_limits': {
        'sugar': {'max': double.tryParse(maxSugarController.text) ?? 0},
        'fiber': {'min': double.tryParse(minFiberController.text) ?? 0},
      },
      'ingredients_avoid': avoidIngredientsController.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),
      'ingredients_prefer': preferIngredientsController.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .set(preferences);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences saved!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving preferences: $e")),
      );
    }
  }

  double? _calculateBMI(Map<String, dynamic>? userData) {
    if (userData == null ||
        !userData.containsKey('weight') ||
        !userData.containsKey('height')) {
      return null;
    }
    final weight = double.tryParse(userData['weight'].toString()) ?? 0;
    final height = double.tryParse(userData['height'].toString()) ?? 0;
    return height > 0 ? weight / ((height / 100) * (height / 100)) : null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          final bmi = _calculateBMI(userData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello ${user?.email ?? 'User'}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("Age: ${userData?['age'] ?? 'Not set'}"),
                Text("Weight: ${userData?['weight'] ?? 'Not set'} kg"),
                Text("Height: ${userData?['height'] ?? 'Not set'} cm"),
                Text("Gender: ${userData?['gender'] ?? 'Not set'}"),
                Text(
                  "BMI: ${bmi != null ? bmi.toStringAsFixed(1) : 'Not calculated'}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Set Your Preferences",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Leave blank to use BMI-based defaults (e.g., stricter sugar limits for higher BMI)",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maxSugarController,
                  decoration: const InputDecoration(
                    labelText: "Max Sugar (g/100g)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minFiberController,
                  decoration: const InputDecoration(
                    labelText: "Min Fiber (g/100g)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: avoidIngredientsController,
                  decoration: const InputDecoration(
                    labelText: "Ingredients to Avoid (comma-separated)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: preferIngredientsController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Ingredients (comma-separated)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Save Preferences"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
