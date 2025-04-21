import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scanner_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in")),
      );
      return;
    }

    final details = {
      'age': int.tryParse(ageController.text) ?? 0,
      'weight': double.tryParse(weightController.text) ?? 0,
      'height': double.tryParse(heightController.text) ?? 0,
      'gender': genderController.text.trim(),
      'email': user.email,
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(details);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Details saved!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving details: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF56C596),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  // Title Text
                  const Text(
                    "Enter Your Details",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Provide your details to personalize your experience",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Age Input
                  TextFormField(
                    controller: ageController,
                    decoration: InputDecoration(
                      labelText: "Age",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: TextStyle(color: Colors.grey[700]),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Age is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Weight Input
                  TextFormField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: "Weight (kg)",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: TextStyle(color: Colors.grey[700]),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Weight is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Height Input
                  TextFormField(
                    controller: heightController,
                    decoration: InputDecoration(
                      labelText: "Height (cm)",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: TextStyle(color: Colors.grey[700]),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Height is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Gender Input
                  TextFormField(
                    controller: genderController,
                    decoration: InputDecoration(
                      labelText: "Gender",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: TextStyle(color: Colors.grey[700]),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Gender is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  ElevatedButton(
                    onPressed: _saveDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF56C596),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}