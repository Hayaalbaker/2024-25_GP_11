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
      throw Exception('Both email and username are already in use.');
    } else if (emailExists) {
      throw Exception('Email is already in use.');
    } else if (usernameExists) {
      throw Exception('Username is already in use.');
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
    throw Exception('Registration failed: ${e.message}');
  } catch (e) {
    throw Exception('Registration failed: $e');
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
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
