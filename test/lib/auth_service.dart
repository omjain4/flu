import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }
  Future<void> updateUserProfile(User user, String age, String weight, String height, String gender) async {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': user.email,
    'age': age,
    'weight': weight,
    'height': height,
    'gender': gender,
  });
}

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
