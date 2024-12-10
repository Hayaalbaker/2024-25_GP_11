import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> checkEmailAndUsernameExists(String email, String username) async {
    final emailExists = await checkEmailExists(email);
    final usernameExists = await checkUsernameExists(username);

    if (emailExists && usernameExists) {
      throw 'Both email and username are already in use.';
    } else if (emailExists) {
      throw 'Email is already in use.';
    } else if (usernameExists) {
      throw 'Username is already in use.';
    }
  }

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String userName,
    required String displayName,
    required bool isLocalGuide,
    required String city,
    required String country,
  }) async {
    try {
      await checkEmailAndUsernameExists(email, userName);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _auth.currentUser;

        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'userName': userName,
            'displayName': displayName,
            'isLocalGuide': isLocalGuide,
            'city': city,
            'country': country,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthError(e.code);
    } catch (e) {
      throw 'Registration failed: $e';
    }
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
        .where('userName', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthError(e.code);
    } catch (e) {
      throw 'Sign in failed: $e';
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getFriendlyAuthError(e.code);
    } catch (e) {
      throw 'Password reset failed: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Sign out failed: $e';
    }
  }

  String _getFriendlyAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already associated with an account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Your password is too weak.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}