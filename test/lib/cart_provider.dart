import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  CartProvider() {
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      _cartItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'code': data['code'] ?? '',
          'quantity': data['quantity'] ?? 1,
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(item['code']);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({
          'quantity': FieldValue.increment(1),
        });
        final index = _cartItems.indexWhere((i) => i['code'] == item['code']);
        if (index != -1) {
          _cartItems[index]['quantity'] += 1;
        }
      } else {
        await docRef.set({
          'name': item['name'],
          'code': item['code'],
          'quantity': item['quantity'] ?? 1,
        });
        _cartItems.add({
          'name': item['name'],
          'code': item['code'],
          'quantity': item['quantity'] ?? 1,
        });
      }
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cartItems.clear();
      notifyListeners();
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  Future<void> incrementItemQuantity(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final index = _cartItems.indexWhere((item) => item['code'] == code);
    if (index == -1) return;

    try {
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(code);
        await docRef.update({
          'quantity': FieldValue.increment(1),
        });
      }
      _cartItems[index]['quantity'] += 1;
      notifyListeners();
    } catch (e) {
      print('Error incrementing quantity: $e');
    }
  }

  Future<void> decrementItemQuantity(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final index = _cartItems.indexWhere((item) => item['code'] == code);
    if (index == -1) return;

    try {
      if (_cartItems[index]['quantity'] <= 1) {
        await removeItem(code);
      } else {
        if (user != null) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(code);
          await docRef.update({
            'quantity': FieldValue.increment(-1),
          });
        }
        _cartItems[index]['quantity'] -= 1;
      }
      notifyListeners();
    } catch (e) {
      print('Error decrementing quantity: $e');
    }
  }

  Future<void> removeItem(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(code);
        await docRef.delete();
      }
      _cartItems.removeWhere((item) => item['code'] == code);
      notifyListeners();
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  bool isItemInCart(String code) {
    return _cartItems.any((item) => item['code'] == code);
  }
}