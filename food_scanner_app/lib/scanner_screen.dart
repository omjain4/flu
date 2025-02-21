import 'package:flutter/material.dart';
import 'barcode_scanner_screen.dart'; // Import the BarcodeScannerScreen file

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void scanBarcode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome to FoodPrint"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "What are you drinking?",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.search), text: "Analyse Your Product"),
              Tab(icon: Icon(Icons.arrow_forward), text: "Get Ingredients"),
              Tab(icon: Icon(Icons.help), text: "Get Help"),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // "Analyse Your Product" Tab
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {}, // Implement search functionality
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

                // "Get Ingredients" Tab - Only Scan Button
                Center(
                  child: ElevatedButton(
                    onPressed: scanBarcode,
                    child: Text("Scan Product"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
