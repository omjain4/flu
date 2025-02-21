import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'search_screen.dart';
import 'shoplist_screen.dart';
import 'settings_screen.dart';

void main(){
  runApp(FoodPrintApp());
}

class FoodPrintApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodPrint',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cartItems = [];

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = cartItems.indexWhere((item) => item["code"] == product["code"]);
      if (index != -1) {
        cartItems[index]["quantity"] += 1;
      } else {
        product["quantity"] = 1;
        cartItems.add(product);
      }
    });
  }

  void increaseQuantity(String productCode) {
    setState(() {
      final index = cartItems.indexWhere((item) => item["code"] == productCode);
      if (index != -1) {
        cartItems[index]["quantity"] += 1;
      }
    });
  }

  void decreaseQuantity(String productCode) {
    setState(() {
      final index = cartItems.indexWhere((item) => item["code"] == productCode);
      if (index != -1 && cartItems[index]["quantity"] > 1) {
        cartItems[index]["quantity"] -= 1;
      } else {
        cartItems.removeAt(index);
      }
    });
  }

  List<Widget> get _pages => [
        ScannerScreen(),
        SearchScreen(onAddToCart: addToCart),
        ShopListScreen(cartItems: cartItems, onIncrease: increaseQuantity, onDecrease: decreaseQuantity),
        SettingsScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Shop List (${cartItems.length})"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
