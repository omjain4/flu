import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'barcode_scanner_screen.dart';
import 'search_screen.dart';
import 'shop_list_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(MaterialApp(home: ScannerScreen()));
}

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cartItems = []; // Shopping cart list

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void scanBarcode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
    );
  }

  void navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          onAddToCart: (item) {
            setState(() {
              int index = cartItems.indexWhere((cartItem) => cartItem["code"] == item["code"]);
              if (index != -1) {
                cartItems[index]["quantity"] += 1;
              } else {
                cartItems.add({...item, "quantity": 1});
              }
            });
          },
        ),
      ),
    );
  }

  void navigateToShopList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopListScreen(cartItems: cartItems),
      ),
    );
  }

  void navigateToProfile() {
    User? user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? "No email found";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(email: email),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      navigateToSearch();
    } else if (index == 2) {
      navigateToShopList();
    } else if (index == 3) {
      navigateToProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Shop List"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // App Title
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "Welcome to FoodPrint",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: TextField(
                onTap: navigateToSearch,
                decoration: InputDecoration(
                  hintText: "What are you drinking?",
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: navigateToSearch,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.search), text: "Analyze Your Product"),
                Tab(icon: Icon(Icons.arrow_forward), text: "Get Ingredients"),
                Tab(icon: Icon(Icons.help), text: "Get Help"),
              ],
              labelColor: Colors.black,
              indicatorColor: Colors.black,
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Analyze Your Product Tab
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: navigateToSearch,
                          child: Text("Search Product"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                        ElevatedButton(
                          onPressed: scanBarcode,
                          child: Text("Scan Product"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Get Ingredients Tab - Only Scan Button
                  Center(
                    child: ElevatedButton(
                      onPressed: scanBarcode,
                      child: Text("Scan Product"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ),

                  // Get Help Tab - Placeholder
                  Center(
                    child: Text("Help Section Coming Soon!", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
