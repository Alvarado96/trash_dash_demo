import 'package:uuid/uuid.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/services/local_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const _uuid = Uuid();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password against hash
  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // Get current user
  UserModel? get currentUser => LocalStorageService.getCurrentUser();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    List<String> interestedCategories = const [],
  }) async {
    try {
      // Check if user already exists
      final existingUsers = LocalStorageService.getAllUsers();
      for (var user in existingUsers) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          throw 'An account already exists for that email';
        }
      }

      // Validate password
      if (password.length < 6) {
        throw 'The password provided is too weak';
      }

      // Hash the password
      final passwordHash = _hashPassword(password);

      // Create new user
      final uid = _uuid.v4();
      final userModel = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
        passwordHash: passwordHash,
        interestedCategories: interestedCategories,
      );

      // Save user to Hive
      await LocalStorageService.saveUser(userModel);

      // Set as current user
      await LocalStorageService.setCurrentUser(uid);

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Find user by email
      final users = LocalStorageService.getAllUsers();
      UserModel? foundUser;

      for (var user in users) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          foundUser = user;
          break;
        }
      }

      if (foundUser == null) {
        throw 'No user found with this email';
      }

      // Verify password
      if (foundUser.passwordHash == null) {
        // User signed up with Google, no password set
        throw 'This account uses Google Sign-In. Please sign in with Google.';
      }

      if (!_verifyPassword(password, foundUser.passwordHash!)) {
        throw 'Incorrect password';
      }

      // Set as current user
      await LocalStorageService.setCurrentUser(foundUser.uid);

      return foundUser;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Check if user already exists by email
      final users = LocalStorageService.getAllUsers();
      UserModel? existingUser;

      for (var user in users) {
        if (user.email.toLowerCase() == googleUser.email.toLowerCase()) {
          existingUser = user;
          break;
        }
      }

      if (existingUser != null) {
        // User exists, sign them in
        await LocalStorageService.setCurrentUser(existingUser.uid);
        return existingUser;
      }

      // Create new user
      final displayName = googleUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final uid = _uuid.v4();
      final userModel = UserModel(
        uid: uid,
        email: googleUser.email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
      );

      // Save user to Hive
      await LocalStorageService.saveUser(userModel);

      // Set as current user
      await LocalStorageService.setCurrentUser(uid);

      return userModel;
    } catch (e) {
      throw 'Google sign in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await LocalStorageService.clearCurrentUser();
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    return LocalStorageService.getUser(uid);
  }
}