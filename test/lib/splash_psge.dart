import 'package:flutter/material.dart';
import 'package:test/login_screen.dart';

class SplashPsge extends StatefulWidget {
  const SplashPsge({super.key});

  @override
  State<SplashPsge> createState() => _SplashPsgeState();
}

class _SplashPsgeState extends State<SplashPsge> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/splashgif.gif', // Path to your GIF file
          fit: BoxFit.cover, // Makes the GIF cover the entire screen
          width: double.infinity, // Ensures the width spans the screen
          height: double.infinity, // Ensures the height spans the screen
        ),
      ),
    );
  }
}
