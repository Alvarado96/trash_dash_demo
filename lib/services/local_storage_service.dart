import 'package:hive/hive.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/models/trash_item.dart';

class LocalStorageService {
  // Boxes
  static Box<UserModel> get usersBox => Hive.box<UserModel>('users');
  static Box<TrashItem> get trashItemsBox => Hive.box<TrashItem>('trashItems');
  static Box get currentUserBox => Hive.box('currentUser');

  // User operations
  static Future<void> saveUser(UserModel user) async {
    await usersBox.put(user.uid, user);
  }

  static UserModel? getUser(String uid) {
    return usersBox.get(uid);
  }

  static Future<void> deleteUser(String uid) async {
    await usersBox.delete(uid);
  }

  static List<UserModel> getAllUsers() {
    return usersBox.values.toList();
  }

  // Current user session
  static Future<void> setCurrentUser(String uid) async {
    await currentUserBox.put('userId', uid);
  }

  static String? getCurrentUserId() {
    return currentUserBox.get('userId');
  }

  static Future<void> clearCurrentUser() async {
    await currentUserBox.delete('userId');
  }

  static UserModel? getCurrentUser() {
    final uid = getCurrentUserId();
    if (uid != null) {
      return getUser(uid);
    }
    return null;
  }

  // Trash item operations
  static Future<void> saveTrashItem(TrashItem item) async {
    await trashItemsBox.put(item.id, item);
  }

  static TrashItem? getTrashItem(String id) {
    return trashItemsBox.get(id);
  }

  static Future<void> deleteTrashItem(String id) async {
    await trashItemsBox.delete(id);
  }

  static List<TrashItem> getAllTrashItems() {
    return trashItemsBox.values.toList();
  }

  static List<TrashItem> getAvailableTrashItems() {
    return trashItemsBox.values
        .where((item) => item.status == ItemStatus.available)
        .toList();
  }

  static List<TrashItem> getClaimedTrashItems() {
    return trashItemsBox.values
        .where((item) => item.status == ItemStatus.claimed)
        .toList();
  }

  static List<TrashItem> getUserClaimedItems(String userId) {
    return trashItemsBox.values
        .where((item) => item.status == ItemStatus.claimed && item.claimedBy == userId)
        .toList();
  }

  static List<TrashItem> getUserPostedItems(String userId) {
    return trashItemsBox.values
        .where((item) => item.postedBy == userId)
        .toList();
  }

  static Future<void> updateTrashItem(TrashItem item) async {
    await trashItemsBox.put(item.id, item);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await usersBox.clear();
    await trashItemsBox.clear();
    await currentUserBox.clear();
  }
}