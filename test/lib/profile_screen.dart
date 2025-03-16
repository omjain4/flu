import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
   final String email;

  ProfileScreen({required this.email});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return Center(child: Text("No user data found."));
          }

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello ${user?.email ?? 'User'}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Age: ${userData['age'] ?? 'Not set'}"),
                Text("Weight: ${userData['weight'] ?? 'Not set'} kg"),
                Text("Height: ${userData['height'] ?? 'Not set'} cm"),
                Text("Gender: ${userData['gender'] ?? 'Not set'}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
