import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:admin_side/widgets/admin_upper_navbar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isShopOpen = false;

  @override
  void initState() {
    super.initState();
    _loadShopStatus();
  }

  Future<void> _loadShopStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('shop_status')
            .get();

    if (doc.exists) {
      setState(() {
        _isShopOpen = doc.data()?['isOpen'] ?? false;
      });
    }
  }

  Future<void> _toggleShopStatus(bool newStatus) async {
    try {
      if (kDebugMode) {
        print("toggling shop status");
      }
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('shop_status')
          .set({
            'isOpen': newStatus,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      setState(() {
        _isShopOpen = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop is now ${newStatus ? 'open' : 'closed'}'),
            backgroundColor: newStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update shop status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminUpperNavbar(
        isShopOpen: _isShopOpen,
        onToggleShopStatus: _toggleShopStatus,
      ),
      // ... rest of your build method
    );
  }
}
