import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ItemStatus {
  available,
  claimed,
  pickedUp,
}

enum ItemCategory {
  furniture,
  electronics,
  clothing,
  books,
  toys,
  appliances,
  decorations,
  other,
}

class TrashItem {
  final String id;
  final String name;
  final ItemCategory category;
  final String? description;
  final String imageUrl;
  final LatLng location;
  final String postedBy;
  final DateTime postedAt;
  ItemStatus status;
  String? claimedBy;

  TrashItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imageUrl,
    required this.location,
    required this.postedBy,
    required this.postedAt,
    this.status = ItemStatus.available,
    this.claimedBy,
  });

  String get categoryName {
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
      case ItemCategory.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toString(),
      'description': description,
      'imageUrl': imageUrl,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'postedBy': postedBy,
      'postedAt': postedAt.toIso8601String(),
      'status': status.toString(),
      'claimedBy': claimedBy,
    };
  }

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      id: json['id'],
      name: json['name'],
      category: ItemCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      description: json['description'],
      imageUrl: json['imageUrl'],
      location: LatLng(json['latitude'], json['longitude']),
      postedBy: json['postedBy'],
      postedAt: DateTime.parse(json['postedAt']),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      claimedBy: json['claimedBy'],
    );
  }
}
