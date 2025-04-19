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
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${user?.email ?? 'User'}",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow("Age", userData?['age']),
                        _buildInfoRow("Weight", "${userData?['weight']} kg"),
                        _buildInfoRow("Height", "${userData?['height']} cm"),
                        _buildInfoRow("Gender", userData?['gender']),
                        _buildInfoRow("BMI",
                            bmi != null ? bmi.toStringAsFixed(1) : "Not set"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Your Dietary Preferences",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Leave blank to use BMI-based defaults.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                    label: "Max Sugar (g/100g)",
                    controller: maxSugarController),
                const SizedBox(height: 15),
                _buildInputField(
                    label: "Min Fiber (g/100g)",
                    controller: minFiberController),
                const SizedBox(height: 15),
                _buildInputField(
                  label: "Ingredients to Avoid (comma-separated)",
                  controller: avoidIngredientsController,
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  label: "Preferred Ingredients (comma-separated)",
                  controller: preferIngredientsController,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save Preferences"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      elevation: 0,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _savePreferences,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: ${value ?? 'Not set'}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
