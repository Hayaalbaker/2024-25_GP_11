import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service class that handles authentication and user-related operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream that provides the current authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Checks if both the email and username exist in Firestore.
  Future<void> checkEmailAndUsernameExists(String email, String username) async {
    final emailExists = await checkEmailExists(email);
    final usernameExists = await checkUsernameExists(username);

    if (emailExists && usernameExists) {
      throw Exception('Both email and username are already in use.');
    } else if (emailExists) {
      throw Exception('Email is already in use.');
    } else if (usernameExists) {
      throw Exception('Username is already in use.');
    }
  }

  /// Registers a new user with the given email and password,
  /// and stores additional user information in Firestore.
  ///
  /// Returns the [User] if registration is successful, or throws an exception on error.
  Future<User?> registerWithEmailAndPassword({
  required String email,
  required String password,
  required String userName,
  required String displayName,
  required bool isLocalGuide,
  required String city,
  required String country, // Add the country parameter here
}) async {
  try {
    // Check if email or username already exists
    await checkEmailAndUsernameExists(email, userName);

    // Create user with email and password
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;

    if (user != null) {
      // Update the user's display name in Firebase Auth
      await user.updateDisplayName(displayName);
      await user.reload();
      user = _auth.currentUser;

      // Additional null check after reassigning
      if (user != null) {
        // Store additional user information in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'userName': userName,
          'displayName': displayName,
          'isLocalGuide': isLocalGuide,
          'city': city,
          'country': country, // Include country here
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }

    return user;
  } on FirebaseAuthException catch (e) {
    // Handle Firebase-specific authentication errors
    throw Exception('Registration failed: ${e.message}');
  } catch (e) {
    // Handle any other errors
    throw Exception('Registration failed: $e');
  }
}

  /// Checks if an email already exists in Firestore.
  Future<bool> checkEmailExists(String email) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

  /// Checks if a username already exists in Firestore.
  Future<bool> checkUsernameExists(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('userName', isEqualTo: username) // Ensure this matches your Firestore field
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> checkEmailExists(String email) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> checkUsernameExists(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('userName', isEqualTo: username) // Ensure this matches your Firestore field
        .get();
    return result.docs.isNotEmpty;
  }

  /// Signs in an existing user with the given email and password.
  ///
  /// Returns the [User] if sign-in is successful, or throws an exception on error.
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific authentication errors
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      // Handle any other errors
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sends a password reset email to the given email address.
  ///
  /// Throws an exception if sending the email fails.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      // Handle any other errors
      throw Exception('Password reset failed: $e');
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// Throws an exception if an error occurs during sign out.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Handle sign-out errors
      throw Exception('Sign out failed: $e');
    }
  }
}
