import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/services/firestore_service.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleInstance = GoogleSignIn();
  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Sign in with email and password
  /// Returns the UserModel if successful
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    if (credential.user != null) {
      // Fetch user data from Firestore
      return await FirestoreService.getUser(credential.user!.uid);
    }
    return null;
  }

  /// Sign in with Google
  /// Creates user in Firestore if new user
  Future<UserModel?> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleInstance.signIn();
    if (googleUser == null) return null;

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential =
        GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    // Once signed in, return the UserCredential
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (userCredential.user != null) {
      final uid = userCredential.user!.uid;

      // Check if user already exists in Firestore
      UserModel? existingUser = await FirestoreService.getUser(uid);

      if (existingUser != null) {
        return existingUser;
      }

      // Create new user in Firestore
      final displayName = googleUser.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final newUser = UserModel(
        uid: uid,
        email: googleUser.email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
        interestedCategories: [],
        savedItemIds: [],
        postedItemIds: [],
      );

      await FirestoreService.createUser(newUser);
      return newUser;
    }
    return null;
  }

  /// Create a new account with email and password
  /// Creates user document in Firestore
  Future<UserModel?> createAccount({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    List<String> interestedCategories = const [],
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (credential.user != null) {
      final uid = credential.user!.uid;

      // Update display name in Firebase Auth if provided
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        await credential.user!.updateDisplayName('$firstName $lastName'.trim());
      }

      // Create user document in Firestore
      final newUser = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: null,
        createdAt: DateTime.now(),
        interestedCategories: interestedCategories,
        savedItemIds: [],
        postedItemIds: [],
      );

      await FirestoreService.createUser(newUser);
      return newUser;
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    await googleInstance.signOut();
    await firebaseAuth.signOut();
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await FirestoreService.getUser(currentUser!.uid);
  }

  /// Stream of current user data from Firestore
  Stream<UserModel?> currentUserDataStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }
    return FirestoreService.userStream(currentUser!.uid);
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserName({
    required String username,
  }) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);
    await currentUser!.reauthenticateWithCredential(credential);

    // Delete user data from Firestore first
    await FirestoreService.deleteUser(currentUser!.uid);

    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}

