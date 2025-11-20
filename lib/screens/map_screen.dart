import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:trash_dash_demo/models/trash_item.dart';
import 'package:trash_dash_demo/data/sample_data.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
  }

  void _loadTrashItems() {
    setState(() {
      _trashItems = SampleData.sampleItems;
      _createMarkers();
    });
  }

  void _createMarkers() {
    _markers = _trashItems
        .where((item) => item.status != ItemStatus.pickedUp)
        .map((item) {
      final String statusText = item.status == ItemStatus.available ? 'Available' : 'Claimed';

      return Marker(
        markerId: MarkerId(item.id),
        position: item.location,
        infoWindow: InfoWindow(
          title: item.name,
          snippet: '${item.categoryName} • $statusText',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          item.status == ItemStatus.available
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
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
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                      onPressed: () {
                        setState(() {
                          item.status = ItemStatus.pickedUp;
                          _currentlyClaimedItem = null;
                          _createMarkers();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Item picked up! Enjoy your treasure!'),
                            backgroundColor: Colors.green,
                          ),
                        );
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
                      onPressed: () {
                        setState(() {
                          item.status = ItemStatus.available;
                          item.claimedBy = null;
                          _currentlyClaimedItem = null;
                          _createMarkers();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Item unclaimed. It\'s now available for others.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
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
            else
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    final locationData = await location.getLocation();
    setState(() {
      _currentPosition = LatLng(
        locationData.latitude ?? 38.8339,
        locationData.longitude ?? -104.8214,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'TrashDash',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
          : GoogleMap(
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
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
