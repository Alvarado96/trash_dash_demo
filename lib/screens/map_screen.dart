import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:trash_dash_demo/models/trash_item.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/services/local_storage_service.dart';
import 'package:trash_dash_demo/services/auth_service.dart';
import 'package:trash_dash_demo/screens/interested_items_screen.dart';
import 'package:trash_dash_demo/screens/saved_items_screen.dart';
import 'package:trash_dash_demo/screens/profile_screen.dart';
import 'package:trash_dash_demo/screens/post_trash_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final TrashItem? selectedItem;

  const MapScreen({super.key, this.selectedItem});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Location location = Location();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};
  List<TrashItem> _trashItems = [];
  TrashItem? _currentlyClaimedItem;
  double _currentZoom = 13.0;
  bool _infoWindowsVisible = false;

  @override
  void initState() {
    super.initState();
    _loadTrashItems();
    _getCurrentLocation();

    // If a selected item was passed, show its details after a short delay
    if (widget.selectedItem != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showItemDetailsAndCenter(widget.selectedItem!);
        }
      });
    }
  }

  void _showItemDetailsAndCenter(TrashItem item) {
    // Center map on the item
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: item.location,
          zoom: 16.0,
        ),
      ),
    );

    // Show item details
    _showItemDetails(item);
  }

  void _loadTrashItems() {
    setState(() {
      _trashItems = LocalStorageService.getAllTrashItems();
      _createMarkers();
    });
  }

  void _createMarkers() {
    final currentUser = LocalStorageService.getCurrentUser();
    final userInterests = currentUser?.interestedCategories ?? [];
    final currentUserName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'
        : '';

    _markers = _trashItems
        .where((item) => item.status != ItemStatus.pickedUp)
        .map((item) {
      final String statusText = item.status == ItemStatus.available ? 'Available' : 'Claimed';

      // Check if this item was posted by current user
      final bool isUserPosted = item.postedBy == currentUserName;

      // Check if this item matches user's interests
      final bool matchesInterest = userInterests.any(
        (interest) => interest.toLowerCase() == item.categoryName.toLowerCase()
      );

      // Determine marker color
      double markerHue;
      if (isUserPosted) {
        // Purple/Violet for user's posted items
        markerHue = BitmapDescriptor.hueViolet;
      } else if (matchesInterest && item.status == ItemStatus.available) {
        // Cyan/Azure color for items matching interests and available
        markerHue = BitmapDescriptor.hueAzure;
      } else if (item.status == ItemStatus.available) {
        // Green for available items
        markerHue = BitmapDescriptor.hueGreen;
      } else {
        // Orange for claimed items
        markerHue = BitmapDescriptor.hueOrange;
      }

      return Marker(
        markerId: MarkerId(item.id),
        position: item.location,
        infoWindow: InfoWindow(
          title: item.name,
          snippet: '${item.categoryName} • $statusText',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        onTap: () {
          _handleMarkerTap(item);
        },
      );
    }).toSet();
  }

  void _handleMarkerTap(TrashItem item) {
    // If the item is claimed by someone else, show confirmation dialog
    if (item.status == ItemStatus.claimed && item.claimedBy != 'You') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Item Already Claimed'),
          content: Text(
            'Someone else is already on the way for this item. Are you sure you want to look at it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showItemDetails(item);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      // Show item details directly for available items or items claimed by you
      _showItemDetails(item);
    }
  }

  void _showInfoWindowsForVisibleMarkers() async {
    if (_mapController == null) return;

    // Get the visible region
    final LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();

    // Collect all visible markers
    final List<String> visibleMarkerIds = [];
    for (var item in _trashItems.where((item) => item.status != ItemStatus.pickedUp)) {
      final lat = item.location.latitude;
      final lng = item.location.longitude;

      // Check if marker is within visible bounds
      if (lat >= visibleRegion.southwest.latitude &&
          lat <= visibleRegion.northeast.latitude &&
          lng >= visibleRegion.southwest.longitude &&
          lng <= visibleRegion.northeast.longitude) {
        visibleMarkerIds.add(item.id);
      }
    }

    // Show info windows for all visible markers with a small delay
    for (int i = 0; i < visibleMarkerIds.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      _mapController!.showMarkerInfoWindow(MarkerId(visibleMarkerIds[i]));
    }
  }

  void _hideAllInfoWindows() {
    if (_mapController == null) return;

    // Hide all info windows
    for (var item in _trashItems.where((item) => item.status != ItemStatus.pickedUp)) {
      _mapController!.hideMarkerInfoWindow(MarkerId(item.id));
    }
  }

  Widget _buildItemImage(String imageUrl) {
    // Check if it's a network URL or local file path
    final bool isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 50),
          );
        },
      );
    } else {
      // Local file
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 50),
            );
          },
        );
      } else {
        return Container(
          height: 200,
          color: Colors.grey.shade300,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Image not found', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(TrashItem item) async {
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${item.location.latitude},${item.location.longitude}';

    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showItemDetails(TrashItem item) {
    final currentUser = LocalStorageService.getCurrentUser();
    final currentUserName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'
        : '';
    final isUserPosted = item.postedBy == currentUserName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildItemImage(item.imageUrl),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Bookmark button
                StatefulBuilder(
                  builder: (context, setStateBookmark) {
                    // Get fresh user data on each rebuild
                    final freshUser = LocalStorageService.getCurrentUser();
                    final isSaved = freshUser?.savedItemIds.contains(item.id) ?? false;

                    return IconButton(
                      onPressed: () async {
                        if (freshUser == null) return;

                        final updatedSavedIds = List<String>.from(freshUser.savedItemIds);
                        if (isSaved) {
                          updatedSavedIds.remove(item.id);
                        } else {
                          updatedSavedIds.add(item.id);
                        }

                        // Show snackbar immediately at bottom of screen
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSaved ? 'Removed from saved items' : 'Saved item!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }

                        final updatedUser = UserModel(
                          uid: freshUser.uid,
                          email: freshUser.email,
                          firstName: freshUser.firstName,
                          lastName: freshUser.lastName,
                          photoUrl: freshUser.photoUrl,
                          createdAt: freshUser.createdAt,
                          passwordHash: freshUser.passwordHash,
                          interestedCategories: freshUser.interestedCategories,
                          savedItemIds: updatedSavedIds,
                        );

                        await LocalStorageService.saveUser(updatedUser);

                        // Trigger rebuild to show new state
                        setStateBookmark(() {});
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey(isSaved),
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.categoryName,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.status == ItemStatus.available
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.status == ItemStatus.available ? 'Available' : 'Claimed',
                    style: TextStyle(
                      color: item.status == ItemStatus.available
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 16),
              Text(
                item.description!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Posted by ${item.postedBy}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            // Only show directions and claim buttons for items NOT posted by current user
            if (!isUserPosted) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openGoogleMaps(item);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.blue.shade700),
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (item.status == ItemStatus.available)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _currentlyClaimedItem != null
                        ? null
                        : () async {
                            setState(() {
                              item.status = ItemStatus.claimed;
                              item.claimedBy = 'You';
                              _currentlyClaimedItem = item;
                            });

                            // Save to Hive
                            await LocalStorageService.updateTrashItem(item);

                            setState(() {
                              _createMarkers();
                            });

                            // Capture the messenger before async gap
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);

                            // Show directions dialog
                            final bool? wantsDirections = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Get Directions?'),
                                content: const Text(
                                  'Would you like to open Google Maps for directions to this item?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );

                            if (wantsDirections == true) {
                              await _openGoogleMaps(item);
                            } else if (wantsDirections == false) {
                              // Only show snackbar if user clicked "No"
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Item claimed! Head over to pick it up.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentlyClaimedItem != null
                          ? Colors.grey
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentlyClaimedItem != null
                          ? "Already on the way to another item"
                          : "I'm on my way!",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else if (item.claimedBy == 'You')
                Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          item.status = ItemStatus.pickedUp;
                          _currentlyClaimedItem = null;
                        });

                        // Save to Hive
                        await LocalStorageService.updateTrashItem(item);

                        setState(() {
                          _createMarkers();
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item picked up! Enjoy your treasure!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Mark as Picked Up",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() {
                          item.status = ItemStatus.available;
                          item.claimedBy = null;
                          _currentlyClaimedItem = null;
                        });

                        // Save to Hive
                        await LocalStorageService.updateTrashItem(item);

                        setState(() {
                          _createMarkers();
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item unclaimed. It\'s now available for others.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.shade700),
                        foregroundColor: Colors.red.shade700,
                      ),
                      child: const Text(
                        "Cancel - I'm not going anymore",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
              else if (item.claimedBy != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.claimedBy} is on the way for this item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
            // Show "Mark as Picked Up" button for poster anytime (claimed or available)
            if (isUserPosted && (item.status == ItemStatus.available || item.status == ItemStatus.claimed)) ...[
              const SizedBox(height: 16),
              // Show who claimed it if applicable
              if (item.status == ItemStatus.claimed && item.claimedBy != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${item.claimedBy} claimed this item',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (item.status == ItemStatus.claimed && item.claimedBy != null)
                const SizedBox(height: 12),
              // Always show "Mark as Picked Up" button for poster
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Capture messenger before async gap
                    final messenger = ScaffoldMessenger.of(context);

                    setState(() {
                      item.status = ItemStatus.pickedUp;
                    });

                    // Save to Hive
                    await LocalStorageService.updateTrashItem(item);

                    setState(() {
                      _createMarkers();
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Item marked as picked up!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    "Mark as Picked Up",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Add timeout to prevent infinite loading
      serviceEnabled = await location.serviceEnabled().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!serviceEnabled) {
        serviceEnabled = await location.requestService().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
        if (!serviceEnabled) {
          // Use default location if service not enabled
          setState(() {
            _currentPosition = const LatLng(38.8339, -104.8214);
            _isLoadingLocation = false;
          });
          return;
        }
      }

      permissionGranted = await location.hasPermission().timeout(
        const Duration(seconds: 5),
        onTimeout: () => PermissionStatus.denied,
      );

      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission().timeout(
          const Duration(seconds: 10),
          onTimeout: () => PermissionStatus.denied,
        );
        if (permissionGranted != PermissionStatus.granted) {
          // Use default location if permission denied
          setState(() {
            _currentPosition = const LatLng(38.8339, -104.8214);
            _isLoadingLocation = false;
          });
          return;
        }
      }

      LocationData? locationData;
      try {
        locationData = await location.getLocation().timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        // Timeout or error getting location
        locationData = null;
      }

      setState(() {
        _currentPosition = LatLng(
          locationData?.latitude ?? 38.8339,
          locationData?.longitude ?? -104.8214,
        );
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      // If any error occurs, use default location
      setState(() {
        _currentPosition = const LatLng(38.8339, -104.8214);
        _isLoadingLocation = false;
      });
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final UserModel? currentUser = LocalStorageService.getCurrentUser();

    return Drawer(
      child: Column(
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: currentUser?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        currentUser!.photoUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            currentUser.firstName[0].toUpperCase(),
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
                      currentUser?.firstName[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            accountName: Text(
              '${currentUser?.firstName ?? ''} ${currentUser?.lastName ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              currentUser?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Profile option
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          // My Items option
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Items I\'m Interested In'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InterestedItemsScreen(),
                ),
              );
            },
          ),
          // Saved Items option
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Saved Items'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedItemsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          // Logout option
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Show confirmation dialog
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmLogout == true && mounted) {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/landing');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Trash Dash',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 1.2,
            fontFamily: 'sans-serif',
          ),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostTrashScreen(),
            ),
          );

          // If item was posted successfully, reload trash items
          if (result == true) {
            _loadTrashItems();
          }
        },
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Post Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(38.8339, -104.8214),
                    zoom: 13.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onCameraMove: (CameraPosition position) {
                    // Only update if zoom level changed significantly
                    if ((position.zoom - _currentZoom).abs() > 0.1) {
                      setState(() {
                        _currentZoom = position.zoom;
                      });

                      // Show info windows when zoomed in close enough
                      if (position.zoom >= 15.0 && !_infoWindowsVisible) {
                        _infoWindowsVisible = true;
                        _showInfoWindowsForVisibleMarkers();
                      } else if (position.zoom < 15.0 && _infoWindowsVisible) {
                        // Hide info windows when zoomed out
                        _infoWindowsVisible = false;
                        _hideAllInfoWindows();
                      }
                    }
                  },
                  onCameraIdle: () {
                    // Update info windows when camera stops moving (after pan/zoom)
                    if (_currentZoom >= 15.0) {
                      _showInfoWindowsForVisibleMarkers();
                    }
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                ),
                // Custom location button with green theme
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green.shade700,
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.white),
                        onPressed: () {
                          if (_currentPosition != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _currentPosition!,
                                  zoom: 15.0,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
