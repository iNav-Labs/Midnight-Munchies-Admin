import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _salesData = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreSales();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreSales();
    }
  }

  Future<void> _loadMoreSales() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var query = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(20);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      final newSales =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final items =
                (data['items'] as List)
                    .map(
                      (item) => {'name': item['name'], 'count': item['count']},
                    )
                    .toList();

            return {
              'date': DateFormat(
                'yyyy-MM-dd',
              ).format((data['orderDate'] as Timestamp).toDate()),
              'items': items,
              'price': data['price'],
              'customer': data['name'],
              'hostel': data['hostel'],
            };
          }).toList();

      setState(() {
        _salesData.addAll(newSales);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sales: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> groupedSales = {};
    for (var sale in _salesData) {
      groupedSales.putIfAbsent(sale['date'], () => []).add(sale);
    }

    List<String> sortedDates =
        groupedSales.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: sortedDates.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == sortedDates.length) {
                    return _buildLoadingIndicator();
                  }
                  String date = sortedDates[index];
                  return _buildSalesSection(date, groupedSales[date]!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        )
        : const SizedBox();
  }

  Widget _buildSalesSection(String date, List<Map<String, dynamic>> sales) {
    String formattedDate = DateFormat(
      "dd MMM yyyy",
    ).format(DateTime.parse(date));
    double totalRevenue = sales.fold(
      0.0,
      (sum, item) => sum + (item['price'] as double),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sales Header
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            "$formattedDate - Revenue: ₹${totalRevenue.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6552FF),
            ),
          ),
        ),
        ...sales.map((sale) => _buildSalesCard(sale)),
      ],
    );
  }

  Widget _buildSalesCard(Map<String, dynamic> sale) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.fastfood, color: Colors.black87),
          ),
          title: Text(
            "${sale['customer']} (${sale['hostel']})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            "₹${sale['price']}",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          children: [
            ...(sale['items'] as List).map(
              (item) => ListTile(
                dense: true,
                title: Text(item['name']),
                trailing: Text('x${item['count']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
