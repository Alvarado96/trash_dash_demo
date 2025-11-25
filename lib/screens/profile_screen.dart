import 'package:flutter/material.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/services/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  Set<String> _selectedCategories = {};
  bool _isEditing = false;

  final List<String> _availableCategories = [
    'Furniture',
    'Electronics',
    'Clothing',
    'Books',
    'Toys',
    'Appliances',
    'Decorations',
    'Tools',
    'Bookshelf',
    'Table',
    'Chair',
    'General Trash',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = LocalStorageService.getCurrentUser();
    if (_currentUser != null) {
      setState(() {
        _selectedCategories = Set.from(_currentUser!.interestedCategories);
      });
    }
  }

  Future<void> _saveCategories() async {
    if (_currentUser == null) return;

    // Update user model with new categories
    final updatedUser = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      firstName: _currentUser!.firstName,
      lastName: _currentUser!.lastName,
      photoUrl: _currentUser!.photoUrl,
      createdAt: _currentUser!.createdAt,
      passwordHash: _currentUser!.passwordHash,
      interestedCategories: _selectedCategories.toList(),
    );

    // Save to Hive
    await LocalStorageService.saveUser(updatedUser);

    setState(() {
      _currentUser = updatedUser;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categories updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No user logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategories = Set.from(_currentUser!.interestedCategories);
                  _isEditing = false;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: _currentUser!.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _currentUser!.photoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  _currentUser!.firstName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            _currentUser!.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_currentUser!.firstName} ${_currentUser!.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser!.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interested Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interested Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (!_isEditing)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: Icon(
                            Icons.edit,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!_isEditing)
                    // Display mode
                    _selectedCategories.isEmpty
                        ? Card(
                            elevation: 0,
                            color: Colors.grey.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No categories selected. Tap edit to add your interests!',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedCategories.map((category) {
                              return Chip(
                                label: Text(category),
                                backgroundColor: Colors.green.shade100,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          )
                  else
                    // Edit mode
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select categories you\'re interested in:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((category) {
                            final isSelected = _selectedCategories.contains(category);
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green.shade700,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveCategories,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Stats Section
                  Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Member Since',
                            value: _formatDate(_currentUser!.createdAt),
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.category,
                            label: 'Interested Categories',
                            value: '${_selectedCategories.length} selected',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}