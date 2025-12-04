import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  tools,
  bookshelf,
  table,
  chair,
  generalTrash,
}

class TrashItem {
  final String id;
  final String name;
  final ItemCategory category;
  final String? description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String postedByUserId;
  final String postedByName;
  final DateTime postedAt;
  ItemStatus status;
  String? claimedByUserId;
  final bool isCurbside;

  LatLng get location => LatLng(latitude, longitude);

  TrashItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imageUrl,
    required LatLng location,
    required this.postedByUserId,
    required this.postedByName,
    required this.postedAt,
    this.status = ItemStatus.available,
    this.claimedByUserId,
    this.isCurbside = false,
  })  : latitude = location.latitude,
        longitude = location.longitude;

  // Constructor for direct latitude/longitude values
  TrashItem._fromCoordinates({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.postedByUserId,
    required this.postedByName,
    required this.postedAt,
    this.status = ItemStatus.available,
    this.claimedByUserId,
    required this.isCurbside,
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

  /// Converts the TrashItem to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'postedByUserId': postedByUserId,
      'postedByName': postedByName,
      'postedAt': Timestamp.fromDate(postedAt),
      'status': status.name,
      'claimedByUserId': claimedByUserId,
      'isCurbside': isCurbside,
    };
  }

  /// Creates a TrashItem from a Firestore DocumentSnapshot
  factory TrashItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TrashItem._fromCoordinates(
      id: doc.id,
      name: data['name'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ItemCategory.other,
      ),
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedAt: (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ItemStatus.available,
      ),
      claimedByUserId: data['claimedByUserId'],
      isCurbside: data['isCurbside'] ?? false,
    );
  }

  /// Creates a TrashItem from a Map (for compatibility)
  factory TrashItem.fromMap(Map<String, dynamic> map, {String? docId}) {
    return TrashItem._fromCoordinates(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.name == map['category'] || e.toString() == map['category'],
        orElse: () => ItemCategory.other,
      ),
      description: map['description'],
      imageUrl: map['imageUrl'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      postedByUserId: map['postedByUserId'] ?? '',
      postedByName: map['postedByName'] ?? map['postedBy'] ?? '',
      postedAt: map['postedAt'] is Timestamp
          ? (map['postedAt'] as Timestamp).toDate()
          : (map['postedAt'] is String
              ? DateTime.parse(map['postedAt'])
              : DateTime.now()),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'] || e.toString() == map['status'],
        orElse: () => ItemStatus.available,
      ),
      claimedByUserId: map['claimedByUserId'] ?? map['claimedBy'],
      isCurbside: map['isCurbside'] ?? false,
    );
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
      'postedByUserId': postedByUserId,
      'postedByName': postedByName,
      'postedAt': postedAt.toIso8601String(),
      'status': status.toString(),
      'claimedByUserId': claimedByUserId,
      'isCurbside': isCurbside,
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
      postedByUserId: json['postedByUserId'] ?? '',
      postedByName: json['postedByName'] ?? json['postedBy'] ?? '',
      postedAt: DateTime.parse(json['postedAt']),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      claimedByUserId: json['claimedByUserId'] ?? json['claimedBy'],
      isCurbside: json['isCurbside'] ?? false,
    );
  }

  /// Creates a copy of the TrashItem with updated fields
  TrashItem copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    String? description,
    String? imageUrl,
    LatLng? location,
    String? postedByUserId,
    String? postedByName,
    DateTime? postedAt,
    ItemStatus? status,
    String? claimedByUserId,
    bool? isCurbside,
  }) {
    return TrashItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedAt: postedAt ?? this.postedAt,
      status: status ?? this.status,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
      isCurbside: isCurbside ?? this.isCurbside,
    );
  }
}
