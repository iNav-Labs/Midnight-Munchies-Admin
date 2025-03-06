import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User data
  String adminName = "";
  String adminEmail = "";
  String adminPhone = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(user?.uid).get();
    final userData = userDoc.data();

    if (user != null) {
      setState(() {
        adminEmail = user.email ?? "No email";
        adminName = userData!["name"] ?? "User";
        adminPhone = userData["phone"] ?? "No phone number";
        // You might want to fetch additional user data from Firestore or other sources
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear any stored tokens or user data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Remove all stored preferences
      // Or selectively clear auth-related preferences:
      // await prefs.remove('user_token');
      // await prefs.remove('user_id');

      // Sign out from Firebase
      await _auth.signOut();

      // After successful logout, navigate to login screen
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Show error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Details
                _buildProfileField(Icons.person, "Username", adminName),
                _buildProfileField(Icons.email, "Email ID", adminEmail),
                _buildProfileField(Icons.phone, "Phone Number", adminPhone),
                // _buildPasswordField(),
                // const SizedBox(height: 10),
                // Change Password Option
                // ListTile(
                //   leading: const Icon(Icons.settings, color: Color(0xFF6552FF)),
                //   title: const Text(
                //     "Change Password",
                //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                //   ),
                //   trailing: const Icon(
                //     Icons.arrow_forward_ios,
                //     size: 16,
                //     color: Colors.grey,
                //   ),
                //   onTap: () {
                //     // Handle password change navigation
                //   },
                // ),
                const SizedBox(height: 20),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _logout(context),
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.logout,
                              size: 18,
                              color: Colors.white,
                            ),
                    label: Text(
                      _isLoading ? "Logging out..." : "Logout",
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6552FF)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
