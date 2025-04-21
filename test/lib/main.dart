import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'details_screen.dart';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'shop_list_screen.dart';
import 'profile_screen.dart';
import 'nutrition_screen.dart';
import 'diet_screen.dart';
import 'cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL); // Set local persistence
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(), // Use AuthenticationWrapper as the home
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/details': (context) => DetailsScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/search': (context) => const SearchScreen(),
        '/cart': (context) => const ShopListScreen(),
        '/diet': (context) => const DietScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/nutrient': (context) => const NutrientScreen(barcode: ''),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            // User is authenticated, navigate to ScannerScreen
            return const ScannerScreen();
          } else {
            // User is not authenticated, navigate to LoginScreen
            return LoginScreen();
          }
        }
        // Show loading indicator while checking auth state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}