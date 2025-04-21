import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'diet_screen.dart';
import 'shop_list_screen.dart';
import 'login_screen.dart'; // Added to enable navigation to LoginScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _sugarLimitController = TextEditingController();
  final _fiberLimitController = TextEditingController();
  final _avoidIngredientsController = TextEditingController();
  final _preferIngredientsController = TextEditingController();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  bool _isEditingUserInfo = false;
  bool _isEditingPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final prefDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();

      setState(() {
        _userData = userDoc.exists ? userDoc.data() : null;
        _preferences = prefDoc.exists ? prefDoc.data() : null;
        _weightController.text = _userData?['weight']?.toString() ?? '';
        _heightController.text = _userData?['height']?.toString() ?? '';
        _sugarLimitController.text =
            _preferences?['nutrient_limits']?['sugar']?['max']?.toString() ?? '';
        _fiberLimitController.text =
            _preferences?['nutrient_limits']?['fiber']?['min']?.toString() ?? '';
        _avoidIngredientsController.text =
            _preferences?['ingredients_avoid']?.join(', ') ?? '';
        _preferIngredientsController.text =
            _preferences?['ingredients_prefer']?.join(', ') ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'weight': double.tryParse(_weightController.text) ?? 0,
        'height': double.tryParse(_heightController.text) ?? 0,
        'email': user.email,
      }, SetOptions(merge: true));

      setState(() {
        _isEditingUserInfo = false;
        _userData = {
          ...?_userData,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'email': user.email,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User info updated successfully!")),
      );
    } catch (e) {
      print("Error saving user info: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .set({
        'nutrient_limits': {
          'sugar': {'max': double.tryParse(_sugarLimitController.text) ?? 5.0},
          'fiber': {'min': double.tryParse(_fiberLimitController.text) ?? 3.0},
        },
        'ingredients_avoid': _avoidIngredientsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'ingredients_prefer': _preferIngredientsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      }, SetOptions(merge: true));

      setState(() {
        _isEditingPreferences = false;
        _preferences = {
          'nutrient_limits': {
            'sugar': {'max': double.tryParse(_sugarLimitController.text) ?? 5.0},
            'fiber': {'min': double.tryParse(_fiberLimitController.text) ?? 3.0},
          },
          'ingredients_avoid': _avoidIngredientsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'ingredients_prefer': _preferIngredientsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences updated successfully!")),
      );
    } catch (e) {
      print("Error saving preferences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(
        context,
        '/login', // Redirect to LoginScreen using named route
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShopListScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DietScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "User Information",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingUserInfo = !_isEditingUserInfo;
                                  });
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: _isEditingUserInfo
                                      ? const Color(0xFF56C596)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Email: ${user?.email ?? 'Not signed in'}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isEditingUserInfo
                              ? TextField(
                                  controller: _weightController,
                                  decoration: InputDecoration(
                                    labelText: "Weight (kg)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                )
                              : Text(
                                  "Weight: ${_userData?['weight']?.toString() ?? 'Not set'} kg",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          const SizedBox(height: 8),
                          _isEditingUserInfo
                              ? TextField(
                                  controller: _heightController,
                                  decoration: InputDecoration(
                                    labelText: "Height (cm)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                )
                              : Text(
                                  "Height: ${_userData?['height']?.toString() ?? 'Not set'} cm",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          if (_isEditingUserInfo) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _saveUserInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF56C596),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Save User Info",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Preferences",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3C72),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingPreferences =
                                        !_isEditingPreferences;
                                  });
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: _isEditingPreferences
                                      ? const Color(0xFF56C596)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _isEditingPreferences
                              ? TextField(
                                  controller: _sugarLimitController,
                                  decoration: InputDecoration(
                                    labelText: "Max Sugar (g/100g)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                )
                              : Text(
                                  "Max Sugar: ${_preferences?['nutrient_limits']?['sugar']?['max']?.toString() ?? 'Not set'} g/100g",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          const SizedBox(height: 8),
                          _isEditingPreferences
                              ? TextField(
                                  controller: _fiberLimitController,
                                  decoration: InputDecoration(
                                    labelText: "Min Fiber (g/100g)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                )
                              : Text(
                                  "Min Fiber: ${_preferences?['nutrient_limits']?['fiber']?['min']?.toString() ?? 'Not set'} g/100g",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          const SizedBox(height: 8),
                          _isEditingPreferences
                              ? TextField(
                                  controller: _avoidIngredientsController,
                                  decoration: InputDecoration(
                                    labelText:
                                        "Ingredients to Avoid (comma-separated)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : Text(
                                  "Ingredients to Avoid: ${_preferences?['ingredients_avoid']?.join(', ') ?? 'None'}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          const SizedBox(height: 8),
                          _isEditingPreferences
                              ? TextField(
                                  controller: _preferIngredientsController,
                                  decoration: InputDecoration(
                                    labelText:
                                        "Preferred Ingredients (comma-separated)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : Text(
                                  "Preferred Ingredients: ${_preferences?['ingredients_prefer']?.join(', ') ?? 'None'}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                          if (_isEditingPreferences) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _savePreferences,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF56C596),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Save Preferences",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Logout",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E3C72),
        selectedItemColor: Colors.grey,
        unselectedItemColor: const Color(0xFF000000),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Diet',
          ),
        ],
      ),
    );
  }
}