import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:admin_side/widgets/admin_bottom_navbar.dart';
import 'package:admin_side/screens/admin_profile_sccreen.dart';
import 'package:admin_side/screens/admin_items_screen.dart';
import 'package:admin_side/screens/admin_daily_sales_screen.dart';
import 'package:admin_side/widgets/admin_upper_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: library_prefixes
import 'package:url_launcher/url_launcher.dart' as urlLauncher;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentTabIndex = 0;
  bool _isShopOpen = false;
  String? _selectedHostel;
  List<String> hostels = ["A", "B", "C", "D"];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> cookingOrders = [];
  List<Map<String, dynamic>> deliveryOrders = [];
  List<Map<String, dynamic>> deliveredOrders = [];

  Future<void> _fetchHostels() async {
    try {
      final hostelDoc =
          await _firestore.collection('settings').doc('shop_status').get();
      final List<dynamic> hostelList =
          hostelDoc.data()?['hostels'] ?? ["A", "B", "C", "D"];
      setState(() {
        hostels = List<String>.from(hostelList);
      });
    } catch (e) {
      debugPrint('Error fetching hostels: $e');
      setState(() {
        hostels = ["A", "B", "C", "D"]; // Fallback to default hostels
      });
    }
  }

  Future<void> _toggleShopStatus(bool value) async {
    try {
      await _firestore.collection('settings').doc('shop_status').update({
        'status': value,
      });
    } catch (e) {
      debugPrint('Error updating shop status: $e');
    }
    setState(() {
      _isShopOpen = value;
    });
  }

  Future<void> _loadShopStatus() async {
    final shopStatus =
        await _firestore.collection('settings').doc('shop_status').get();
    setState(() {
      _isShopOpen = shopStatus.data()?['status'] ?? false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _moveToDelivery(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'delivery',
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  void _markAsDelivered(String orderId) async {
    // Show confirmation dialog first
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delivery'),
          content: const Text('Are you sure this order has been delivered?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );

    // Only proceed if user confirmed
    if (confirm == true) {
      try {
        await _firestore.collection('orders').doc(orderId).update({
          'status': 'delivered',
        });
      } catch (e) {
        debugPrint('Error updating order status: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHostels();
    _loadShopStatus();
  }

  Widget buildOrderList(
    List<Map<String, dynamic>> orders,
    bool isCooking, {
    bool isFiltered = false,
    required String status,
  }) {
    return orders.isEmpty
        ? const Center(
          child: Text(
            "No orders available",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            if (orders[index]["status"] != status) {
              return const SizedBox.shrink();
            }
            return Card(
              color: Colors.white,
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () {
                  // Show order details in a dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          "Order Details",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Customer: ${orders[index]["name"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Hostel: ${orders[index]["hostel"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6552FF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Phone: ${orders[index]["phone"] ?? "Not provided"}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Items:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...orders[index]["items"].map<Widget>((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item["name"],
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        "x${item["count"]}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const Divider(),
                              const Text(
                                "Items in Hindi:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ...orders[index]["items"].map<Widget>((item) {
                                // Debug print to see the entire item object
                                if (kDebugMode) {
                                  print("Full item: $item");
                                }

                                // Check if hindiName exists and is not empty
                                final hindiName = item["hindiName"];
                                if (hindiName == null ||
                                    hindiName.toString().isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          hindiName.toString(),
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        "x${item["count"]}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Close"),
                          ),
                          TextButton(
                            onPressed: () {
                              isCooking
                                  ? _moveToDelivery(orders[index]["id"])
                                  : _markAsDelivered(orders[index]["id"]);
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              isCooking
                                  ? "Move to Delivery"
                                  : "Mark as Delivered",
                              style: TextStyle(
                                color: isCooking ? Colors.orange : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF6552FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.truck,
                    color: Color(0xFF6552FF),
                  ),
                ),
                title: Text(
                  orders[index]["name"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...orders[index]["items"].map((item) {
                      return Text(
                        "${item["name"]} x ${item["count"]}",
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                    Text(
                      "${orders[index]["hostel"]}",
                      style: const TextStyle(
                        color: Color(0xFF6552FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final phoneNumber = orders[index]["phone"] ?? "";
                          if (phoneNumber.isNotEmpty) {
                            String formattedNumber = phoneNumber;
                            if (!phoneNumber.startsWith('+')) {
                              // If no country code, assume Indian number and add +91
                              formattedNumber =
                                  phoneNumber.startsWith('0')
                                      ? '+91${phoneNumber.substring(1)}'
                                      : '+91$phoneNumber';
                            }

                            final Uri phoneUri = Uri(
                              scheme: 'tel',
                              path: formattedNumber,
                            );
                            if (await urlLauncher.canLaunchUrl(phoneUri)) {
                              await urlLauncher.launchUrl(phoneUri);
                            } else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not launch dialer with $formattedNumber',
                                  ),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No phone number available'),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.phone, color: Colors.red),
                      ),
                      IconButton(
                        icon: Icon(
                          isCooking ? Icons.local_shipping : Icons.check_circle,
                          color: isCooking ? Colors.orange : Colors.green,
                        ),
                        onPressed: () {
                          isCooking
                              ? _moveToDelivery(orders[index]["id"])
                              : _markAsDelivered(orders[index]["id"]);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  Stream<List<Map<String, dynamic>>> getTodaysOrders() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    return _firestore
        .collection('orders')
        .where(
          'orderDate',
          isGreaterThanOrEqualTo: startOfYesterday,
        ) // Fetch from yesterday
        .snapshots()
        .map((snapshot) {
          if (kDebugMode) {
            print(snapshot.docs.length);
          }
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final orderDate = (data['orderDate'] as Timestamp).toDate();
                final status = data['status'] ?? 'cooking';

                // Show orders that were placed today or are still pending from yesterday
                if (orderDate.isAfter(startOfToday) || status == 'cooking') {
                  return {
                    'id': doc.id,
                    'name': data['name'] ?? '',
                    'hostel': data['hostel'] ?? '',
                    'status': status,
                    'items': List<Map<String, dynamic>>.from(
                      data['items'] ?? [],
                    ),
                    'orderDate': orderDate,
                    'phone': data['phone'] ?? '',
                  };
                }
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList(); // Remove null values
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
              tabs: const [
                Tab(text: "Cooking"),
                Tab(text: "Delivery"),
                Tab(text: "Select Hostel"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTodaysOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];

                return IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    buildOrderList(orders, true, status: "cooking"),
                    buildOrderList(orders, false, status: "delivery"),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                isExpanded: true,
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.apartment_rounded,
                                      size: 24,
                                      color: Color(0xFF6552FF),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Select Hostel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                items:
                                    hostels.map((String hostel) {
                                      return DropdownMenuItem<String>(
                                        value: hostel,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.apartment_rounded,
                                              color: Color(0xFF6552FF),
                                              size: 20,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              hostel,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                value: _selectedHostel,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedHostel = newValue;
                                  });
                                },
                                buttonStyleData: ButtonStyleData(
                                  height: 50,
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                    left: 14,
                                    right: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                ),
                                iconStyleData: IconStyleData(
                                  icon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Color(0xFF6552FF),
                                    size: 30,
                                  ),
                                  iconEnabledColor: Color(0xFF6552FF),
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  maxHeight: 300,
                                  width: MediaQuery.of(context).size.width - 40,
                                  padding: null,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  offset: const Offset(0, -10),
                                  scrollbarTheme: ScrollbarThemeData(
                                    radius: const Radius.circular(40),
                                    thickness: WidgetStateProperty.all(6),
                                    thumbVisibility: WidgetStateProperty.all(
                                      true,
                                    ),
                                  ),
                                ),
                                menuItemStyleData: MenuItemStyleData(
                                  height: 50,
                                  padding: const EdgeInsets.only(
                                    left: 14,
                                    right: 14,
                                  ),
                                  selectedMenuItemBuilder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF6552FF,
                                          // ignore: deprecated_member_use
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: buildOrderList(
                            orders
                                .where(
                                  (order) =>
                                      _selectedHostel == null ||
                                      order["hostel"] == _selectedHostel,
                                )
                                .toList(),
                            false,
                            isFiltered: true,
                            status: "delivery",
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      const ItemsScreen(),
      const ProfileScreen(),
      const DailySalesScreen(),
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AdminUpperNavbar(
          isShopOpen: _isShopOpen,
          onToggleShopStatus: _toggleShopStatus,
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: AdminBottomNavbar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
