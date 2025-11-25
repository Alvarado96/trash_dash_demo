import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trash_dash_demo/models/trash_item.dart';
import 'package:trash_dash_demo/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

class PostTrashScreen extends StatefulWidget {
  const PostTrashScreen({super.key});

  @override
  State<PostTrashScreen> createState() => _PostTrashScreenState();
}

class _PostTrashScreenState extends State<PostTrashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  ItemCategory? _selectedCategory;
  File? _selectedImage;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  List<Location> _addressSuggestions = [];
  Map<String, String> _addressDisplayNames = {}; // Maps location key to formatted address
  bool _showSuggestions = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _addressDisplayNames = {};
        _showSuggestions = false;
      });
      return;
    }

    try {
      List<Location> locations = [];

      // Try multiple search strategies
      try {
        // Strategy 1: Full address with Colorado Springs
        locations = await locationFromAddress('$query, Colorado Springs, CO, USA');
      } catch (e) {
        try {
          // Strategy 2: Without USA
          locations = await locationFromAddress('$query, Colorado Springs, CO');
        } catch (e2) {
          try {
            // Strategy 3: With ZIP code
            locations = await locationFromAddress('$query, Colorado Springs, CO 80906');
          } catch (e3) {
            try {
              // Strategy 4: Just the query
              locations = await locationFromAddress(query);
            } catch (e4) {
              // All strategies failed
              locations = [];
            }
          }
        }
      }

      if (locations.isEmpty) {
        setState(() {
          _addressSuggestions = [];
          _addressDisplayNames = {};
          _showSuggestions = false;
        });
        return;
      }

      // Get formatted addresses for each location
      final displayNames = <String, String>{};
      for (final location in locations.take(5)) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final street = placemark.street ?? '';
            final locality = placemark.locality ?? '';
            final area = placemark.administrativeArea ?? '';
            final postal = placemark.postalCode ?? '';

            final address = street.isNotEmpty
                ? '$street, $locality, $area $postal'
                : '$locality, $area $postal';

            final key = '${location.latitude},${location.longitude}';
            displayNames[key] = address;
          }
        } catch (e) {
          // If reverse geocoding fails, use coordinates as fallback
          final key = '${location.latitude},${location.longitude}';
          displayNames[key] = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        }
      }

      setState(() {
        _addressSuggestions = locations.take(5).toList();
        _addressDisplayNames = displayNames;
        _showSuggestions = locations.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _addressSuggestions = [];
        _addressDisplayNames = {};
        _showSuggestions = false;
      });
    }
  }

  Future<void> _selectLocation(Location location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}';

        setState(() {
          _addressController.text = address;
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _showSuggestions = false;
          _addressSuggestions = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting address details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = LocalStorageService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // In a real app, you would upload the image to a server and get a URL
      // For now, we'll use a placeholder or the local file path
      final imageUrl = _selectedImage!.path; // This would be replaced with uploaded URL

      final newItem = TrashItem(
        id: const Uuid().v4(),
        name: _titleController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: imageUrl,
        location: _selectedLocation!,
        postedBy: '${currentUser.firstName} ${currentUser.lastName}',
        postedAt: DateTime.now(),
        status: ItemStatus.available,
      );

      await LocalStorageService.saveTrashItem(newItem);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Trash Item'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker section
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Wooden Chair',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<ItemCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ItemCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryDisplayName(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add more details about the item...',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address field with autocomplete
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Enter street address',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          _searchAddress(value);
                        },
                        onEditingComplete: () async {
                          // If user finishes typing and hasn't selected from suggestions, try to geocode it
                          if (_selectedLocation == null && _addressController.text.isNotEmpty) {
                            try {
                              final query = '${_addressController.text}, Colorado Springs, CO';
                              final locations = await locationFromAddress(query);
                              if (locations.isNotEmpty) {
                                setState(() {
                                  _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
                                  _showSuggestions = false;
                                  _addressSuggestions = [];
                                });
                              }
                            } catch (e) {
                              // Geocoding failed, but allow user to continue
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an address';
                          }
                          return null;
                        },
                      ),
                      if (_showSuggestions && _addressSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _addressSuggestions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final location = _addressSuggestions[index];
                              final key = '${location.latitude},${location.longitude}';
                              final displayAddress = _addressDisplayNames[key] ??
                                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

                              return ListTile(
                                leading: const Icon(Icons.location_on, size: 20),
                                title: Text(
                                  displayAddress,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  _selectLocation(location);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Post Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(ItemCategory category) {
    switch (category) {
      case ItemCategory.furniture:
        return 'Furniture';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.toys:
        return 'Toys';
      case ItemCategory.appliances:
        return 'Appliances';
      case ItemCategory.decorations:
        return 'Decorations';
      case ItemCategory.tools:
        return 'Tools';
      case ItemCategory.bookshelf:
        return 'Bookshelf';
      case ItemCategory.table:
        return 'Table';
      case ItemCategory.chair:
        return 'Chair';
      case ItemCategory.generalTrash:
        return 'General Trash';
      case ItemCategory.other:
        return 'Other';
    }
  }
}