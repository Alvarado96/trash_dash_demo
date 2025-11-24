import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';

part 'trash_item.g.dart';

@HiveType(typeId: 1)
enum ItemStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  claimed,
  @HiveField(2)
  pickedUp,
}

@HiveType(typeId: 2)
enum ItemCategory {
  @HiveField(0)
  furniture,
  @HiveField(1)
  electronics,
  @HiveField(2)
  clothing,
  @HiveField(3)
  books,
  @HiveField(4)
  toys,
  @HiveField(5)
  appliances,
  @HiveField(6)
  decorations,
  @HiveField(7)
  other,
  @HiveField(8)
  tools,
  @HiveField(9)
  bookshelf,
  @HiveField(10)
  table,
  @HiveField(11)
  chair,
  @HiveField(12)
  generalTrash,
}

@HiveType(typeId: 3)
class TrashItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ItemCategory category;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final double latitude;

  @HiveField(6)
  final double longitude;

  @HiveField(7)
  final String postedBy;

  @HiveField(8)
  final DateTime postedAt;

  @HiveField(9)
  ItemStatus status;

  @HiveField(10)
  String? claimedBy;

  LatLng get location => LatLng(latitude, longitude);

  TrashItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imageUrl,
    required LatLng location,
    required this.postedBy,
    required this.postedAt,
    this.status = ItemStatus.available,
    this.claimedBy,
  })  : latitude = location.latitude,
        longitude = location.longitude;

  // Constructor for Hive deserialization
  TrashItem._({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
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
