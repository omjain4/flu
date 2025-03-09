import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'scanner_screen.dart'; // Add this line to import ScannerScreen

class AuthScreen extends StatefulWidget {
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

  if (isLogin) {
    user = await _authService.signInWithEmail(email, password);
  } else {
    user = await _authService.registerWithEmail(email, password);
  }

  if (user != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isLogin ? "Signed in!" : "Account created!"),
    ));

    // Navigate to ScannerScreen after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error during authentication")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Sign In" : "Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Create an Account" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
