import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/scanner_screen.dart';

class DetailsScreen extends StatefulWidget {
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  String? gender;

  void _saveDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found. Please log in again.")),
      );
      return;
    }

    if (ageController.text.isNotEmpty &&
        weightController.text.isNotEmpty &&
        heightController.text.isNotEmpty &&
        gender != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'age': ageController.text,
        'weight': weightController.text,
        'height': heightController.text,
        'gender': gender,
      }, SetOptions(merge: true));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ScannerScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Details',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            TextField(
              controller: heightController,
              decoration: InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            DropdownButton<String>(
              value: gender,
              hint: Text("Select Gender"),
              onChanged: (String? newValue) {
                setState(() {
                  gender = newValue;
                });
              },
              items: ["Male", "Female", "Other"]
                  .map((gender) => DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                    'email': user.email,
                    'age': ageController.text,
                    'weight': weightController.text,
                    'height': heightController.text,
                    'gender': gender,
                  }, SetOptions(merge: true));
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ScannerScreen()),
                );
              },
              child: Text('Next'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
