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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    print('Firebase initialization error: $e');
  }

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
      home: SplashScreen(),
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

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuth();
  }

  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthenticationWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splashgif.gif',
          fit: BoxFit.cover, // Make the GIF cover the entire screen
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Failed to load splash screen',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ); // Fallback if GIF fails to load
          },
        ),
      ),
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
            return const ScannerScreen();
          } else {
            return LoginScreen();
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}