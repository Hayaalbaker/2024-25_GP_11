import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with Email & Password and save user data in Firestore
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String userName, bool isLocalGuide) async {
    try {
      // طباعة القيمة للتحقق
      print('Registering user: $userName, Local Guide: $isLocalGuide');

      // إنشاء المستخدم
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // تخزين بيانات المستخدم في Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'email': email,
        'userName': userName,
        'local_guide': isLocalGuide ? 'yes' : 'no', // حفظ حالة الدليل المحلي
        'created_at': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      print('Registration Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  }

  // Sign in with Email & Password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign In Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }
}