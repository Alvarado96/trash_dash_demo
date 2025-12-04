import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> interestedCategories;
  final List<String> savedItemIds;
  final List<String> postedItemIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.createdAt,
    this.interestedCategories = const [],
    this.savedItemIds = const [],
    this.postedItemIds = const [],
  });

  String get fullName => '$firstName $lastName';

  /// Converts the UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'interestedCategories': interestedCategories,
      'savedItemIds': savedItemIds,
      'postedItemIds': postedItemIds,
    };
  }

  /// Creates a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      interestedCategories: List<String>.from(data['interestedCategories'] ?? []),
      savedItemIds: List<String>.from(data['savedItemIds'] ?? []),
      postedItemIds: List<String>.from(data['postedItemIds'] ?? []),
    );
  }

  /// Creates a UserModel from a Map (for compatibility)
  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : DateTime.now()),
      interestedCategories: List<String>.from(map['interestedCategories'] ?? []),
      savedItemIds: List<String>.from(map['savedItemIds'] ?? []),
      postedItemIds: List<String>.from(map['postedItemIds'] ?? []),
    );
  }

  /// Creates a copy of the UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? interestedCategories,
    List<String>? savedItemIds,
    List<String>? postedItemIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      interestedCategories: interestedCategories ?? this.interestedCategories,
      savedItemIds: savedItemIds ?? this.savedItemIds,
      postedItemIds: postedItemIds ?? this.postedItemIds,
    );
  }
}