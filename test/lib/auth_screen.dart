import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'scanner_screen.dart'; // Add this line to import ScannerScreen

// Define the PigeonUserDetails class
class PigeonUserDetails {
  final String id;
  final String name;

  PigeonUserDetails({required this.id, required this.name});

  // Example factory constructor to create an instance from a map
  factory PigeonUserDetails.fromMap(Map<String, dynamic> map) {
    return PigeonUserDetails(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  factory PigeonUserDetails.fromUser(User user) {
    return PigeonUserDetails(
      id: user.uid,
      name: user.displayName ?? "Unknown",
    );
  }
}

class AuthService {
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Registration Error: $e");
      return null;
    }
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLogin = true;

  void _authenticate() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    User? user;

    try {
      if (isLogin) {
        user = await _authService.signInWithEmail(email, password);
      } else {
        user = await _authService.registerWithEmail(email, password);
      }

      print(user.runtimeType); // Check the actual type of the returned object

      if (user != null) {
        final PigeonUserDetails details = PigeonUserDetails.fromUser(user);
        print("Authentication successful: ${details.name}");
        // Proceed with navigation
      } else {
        print("Authentication failed");
      }
    } catch (e) {
      print("Sign In Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Sign In" : "Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin
                  ? "Create an Account"
                  : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
