import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/models/trash_item.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get trashItemsCollection =>
      _firestore.collection('trashItems');

  // ============ USER OPERATIONS ============

  /// Create a new user document in Firestore
  static Future<void> createUser(UserModel user) async {
    await usersCollection.doc(user.uid).set(user.toFirestore());
  }

  /// Get user by UID
  static Future<UserModel?> getUser(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update user document
  static Future<void> updateUser(UserModel user) async {
    await usersCollection.doc(user.uid).update(user.toFirestore());
  }

  /// Delete user document
  static Future<void> deleteUser(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  /// Stream of user data for real-time updates
  static Stream<UserModel?> userStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user's interested categories
  static Future<void> updateInterestedCategories(
      String uid, List<String> categories) async {
    await usersCollection.doc(uid).update({
      'interestedCategories': categories,
    });
  }

  /// Add item to user's saved items
  static Future<void> addSavedItem(String uid, String itemId) async {
    await usersCollection.doc(uid).update({
      'savedItemIds': FieldValue.arrayUnion([itemId]),
    });
  }

  /// Remove item from user's saved items
  static Future<void> removeSavedItem(String uid, String itemId) async {
    await usersCollection.doc(uid).update({
      'savedItemIds': FieldValue.arrayRemove([itemId]),
    });
  }

  /// Add item to user's posted items
  static Future<void> addPostedItem(String uid, String itemId) async {
    await usersCollection.doc(uid).update({
      'postedItemIds': FieldValue.arrayUnion([itemId]),
    });
  }

  /// Remove item from user's posted items
  static Future<void> removePostedItem(String uid, String itemId) async {
    await usersCollection.doc(uid).update({
      'postedItemIds': FieldValue.arrayRemove([itemId]),
    });
  }

  // ============ TRASH ITEM OPERATIONS ============

  /// Create a new trash item in Firestore using a transaction for consistency
  static Future<void> createTrashItem(TrashItem item) async {
    await _firestore.runTransaction((transaction) async {
      // Add the trash item
      transaction.set(trashItemsCollection.doc(item.id), item.toFirestore());
      
      // Also add to user's posted items if userId is provided
      if (item.postedByUserId.isNotEmpty) {
        transaction.update(usersCollection.doc(item.postedByUserId), {
          'postedItemIds': FieldValue.arrayUnion([item.id]),
        });
      }
    });
  }

  /// Get trash item by ID
  static Future<TrashItem?> getTrashItem(String id) async {
    final doc = await trashItemsCollection.doc(id).get();
    if (doc.exists) {
      return TrashItem.fromFirestore(doc);
    }
    return null;
  }

  /// Update trash item
  static Future<void> updateTrashItem(TrashItem item) async {
    await trashItemsCollection.doc(item.id).update(item.toFirestore());
  }

  /// Delete trash item using a transaction for consistency
  static Future<void> deleteTrashItem(String id) async {
    // Get the item first to find the user ID
    final doc = await trashItemsCollection.doc(id).get();
    if (!doc.exists) return;
    
    final item = TrashItem.fromFirestore(doc);
    
    await _firestore.runTransaction((transaction) async {
      // Remove from user's posted items if userId is available
      if (item.postedByUserId.isNotEmpty) {
        transaction.update(usersCollection.doc(item.postedByUserId), {
          'postedItemIds': FieldValue.arrayRemove([id]),
        });
      }
      
      // Delete the trash item
      transaction.delete(trashItemsCollection.doc(id));
    });
  }

  /// Get all trash items
  static Future<List<TrashItem>> getAllTrashItems() async {
    final snapshot = await trashItemsCollection.get();
    return snapshot.docs.map((doc) => TrashItem.fromFirestore(doc)).toList();
  }

  /// Stream of all trash items for real-time updates
  static Stream<List<TrashItem>> trashItemsStream() {
    return trashItemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TrashItem.fromFirestore(doc)).toList();
    });
  }

  /// Get available trash items
  static Future<List<TrashItem>> getAvailableTrashItems() async {
    final snapshot = await trashItemsCollection
        .where('status', isEqualTo: 'available')
        .get();
    return snapshot.docs.map((doc) => TrashItem.fromFirestore(doc)).toList();
  }

  /// Get items posted by a specific user
  static Future<List<TrashItem>> getUserPostedItems(String userId) async {
    final snapshot = await trashItemsCollection
        .where('postedByUserId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => TrashItem.fromFirestore(doc)).toList();
  }

  /// Get items claimed by a specific user
  static Future<List<TrashItem>> getUserClaimedItems(String userId) async {
    final snapshot = await trashItemsCollection
        .where('claimedByUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'claimed')
        .get();
    return snapshot.docs.map((doc) => TrashItem.fromFirestore(doc)).toList();
  }

  /// Claim a trash item
  static Future<void> claimTrashItem(String itemId, String userId) async {
    await trashItemsCollection.doc(itemId).update({
      'status': 'claimed',
      'claimedByUserId': userId,
    });
  }

  /// Unclaim a trash item
  static Future<void> unclaimTrashItem(String itemId) async {
    await trashItemsCollection.doc(itemId).update({
      'status': 'available',
      'claimedByUserId': null,
    });
  }

  /// Mark item as picked up
  static Future<void> markItemPickedUp(String itemId) async {
    await trashItemsCollection.doc(itemId).update({
      'status': 'pickedUp',
    });
  }
}
