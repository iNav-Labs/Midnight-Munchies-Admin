import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _hindiNameController = TextEditingController();
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _selectedCategories;
  final List<Map<String, dynamic>> _items = [];

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _fetchcategories();
  }

  Future<void> _fetchcategories() async {
    try {
      final hostelDoc =
          await _firestore.collection('settings').doc('shop_status').get();
      final List<dynamic> categoriesList =
          hostelDoc.data()?['categories'] ?? ["A", "B", "C", "D"];
      setState(() {
        categories = List<String>.from(categoriesList);
      });
    } catch (e) {
      debugPrint('Error fetching hostels: $e');
      setState(() {
        categories = ["A", "B", "C", "D"]; // Fallback to default hostels
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      final QuerySnapshot snapshot = await _firestore.collection('items').get();
      setState(() {
        _items.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          _items.add({
            'id': doc.id,
            'name': data['name'],
            'hindiName': data['hindiName'] ?? '',
            'price': data['price'],
            'image': data['imageUrl'],
          });
        }
      });
    } catch (e) {
      _showErrorDialog('Error loading items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For Web
          _imageBytes = await pickedFile.readAsBytes();
          setState(() {
            _imageUrl = null; // Clear any existing URL
          });
        } else {
          // For Mobile
          setState(() {
            _imageUrl = pickedFile.path;
            _imageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _uploadImageAndAddItem() async {
    if (double.tryParse(_priceController.text) != null &&
        double.parse(_priceController.text) > 0) {
      if (_formKey.currentState!.validate() &&
          (_imageUrl != null || _imageBytes != null)) {
        try {
          setState(() => _isLoading = true);

          // Generate unique filename
          final String fileName = '${_uuid.v4()}.jpg';
          final Reference ref = _storage.ref().child('items/$fileName');

          late TaskSnapshot snapshot;

          // Upload to Firebase Storage based on platform
          if (kIsWeb && _imageBytes != null) {
            // For Web
            snapshot = await ref.putData(
              _imageBytes!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else if (_imageUrl != null) {
            // For Mobile
            final File imageFile = File(_imageUrl!);
            snapshot = await ref.putFile(imageFile);
          } else {
            throw Exception("No image data available");
          }

          // Get download URL
          final String downloadUrl = await snapshot.ref.getDownloadURL();

          // Add to Firestore
          await _firestore.collection('items').add({
            'name': _nameController.text,
            'hindiName': _hindiNameController.text,
            'price': _priceController.text,
            'imageUrl': downloadUrl,
            'category': _selectedCategories,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Clear form
          _nameController.clear();
          _priceController.clear();
          _hindiNameController.clear();
          setState(() {
            _imageUrl = null;
            _imageBytes = null;
          });

          // Reload items
          await _loadItems();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully!')),
          );
        } catch (e) {
          _showErrorDialog('Error adding item: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Please select an image and fill all fields'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter a valid price'),
        ),
      );
    }
  }

  Future<void> _deleteItem(int index) async {
    try {
      setState(() => _isLoading = true);

      // Delete from Firestore
      await _firestore.collection('items').doc(_items[index]['id']).delete();

      // Delete from Storage
      final String imageUrl = _items[index]['image'];
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      setState(() {
        _items.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Item deleted successfully!'),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error deleting item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editItem(int index) async {
    final String itemId = _items[index]['id'];
    _nameController.text = _items[index]['name'];
    _priceController.text = _items[index]['price'];
    _hindiNameController.text = _items[index]['hindiName'] ?? '';

    final BuildContext parentContext = context;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              "Edit Item",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, "Food Name"),
                const SizedBox(height: 12),
                _buildTextField(_hindiNameController, "Hindi Name"),
                const SizedBox(height: 12),
                _buildTextField(
                  _priceController,
                  "Price",
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    if (double.tryParse(_priceController.text) != null &&
                        double.parse(_priceController.text) > 0) {
                      await _firestore.collection('items').doc(itemId).update({
                        'name': _nameController.text,
                        'hindiName': _hindiNameController.text,
                        'price': _priceController.text,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(dialogContext);
                      await _loadItems();

                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Item updated successfully!'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Please enter a valid price'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (parentContext.mounted) {
                      _showErrorDialog('Error updating item: $e');
                    }
                  }
                },
                child: Text(
                  "Save",
                  style: GoogleFonts.poppins(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add New Food Item",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6552FF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(_nameController, "Food Name"),
                            const SizedBox(height: 16),
                            _buildTextField(_hindiNameController, "Hindi Name"),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _priceController,
                              "Price",
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
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
                                            'Select Categories',
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
                                        categories.map((String hostel) {
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
                                    value: _selectedCategories,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategories = newValue;
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
                                      width:
                                          MediaQuery.of(context).size.width -
                                          40,
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
                                        thumbVisibility:
                                            WidgetStateProperty.all(true),
                                      ),
                                    ),
                                    menuItemStyleData: MenuItemStyleData(
                                      height: 50,
                                      padding: const EdgeInsets.only(
                                        left: 14,
                                        right: 14,
                                      ),
                                      selectedMenuItemBuilder: (
                                        context,
                                        child,
                                      ) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF6552FF,
                                              // ignore: deprecated_member_use
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: child,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildImageUploadSection(),
                            const SizedBox(height: 24),
                            _buildAddButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 500, // Set a fixed height for the list
                    child:
                        _items.isEmpty ? _buildEmptyState() : _buildItemList(),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload, color: Color(0xFF6552FF)),
          label: Text(
            "Upload Image",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6552FF),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      // Web preview
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _imageBytes!,
          width: 120,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageUrl != null && !kIsWeb) {
      // Mobile preview
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_imageUrl!),
          width: 120,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Placeholder
      return Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: Icon(Icons.image, color: Colors.grey, size: 40),
        ),
      );
    }
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _uploadImageAndAddItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6552FF),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Add Item",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No items added yet.",
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _items[index]['image'],
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error_outline),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _items[index]['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${_items[index]['price']}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6552FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF6552FF)),
                      onPressed: () => _editItem(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
