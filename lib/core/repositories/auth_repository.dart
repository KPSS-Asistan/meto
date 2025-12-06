import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Get current user
  User? getCurrentUser() => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email/password
  Future<User> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      );
    }
    
    return userCredential.user!;
  }

  // Sign up with email/password
  Future<User> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to create user',
      );
    }
    
    await _createUserDocument(userCredential.user!);
    
    return userCredential.user!;
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Google sign in cancelled',
      );
    }
    
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = await _auth.signInWithCredential(credential);
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to sign in with Google',
      );
    }
    
    // Check if user is new
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _createUserDocument(userCredential.user!);
    }
    
    return userCredential.user!;
  }

  // Sign in with Apple - DISABLED (package removed)
  // TODO: Re-enable if Apple Sign-In is needed
  // Future<User> signInWithApple() async {
  //   throw UnimplementedError('Apple Sign-In is currently disabled');
  // }

  // Sign in anonymously
  Future<User> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    
    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to sign in anonymously',
      );
    }
    
    await _createUserDocument(userCredential.user!, isAnonymous: true);
    
    return userCredential.user!;
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user, {
    bool isAnonymous = false,
  }) async {
    try {
      // Check if document already exists
      final exists = await _userDocumentExists(user.uid);
      if (exists) {
        log('User document already exists for ${user.uid}');
        return;
      }

      final now = DateTime.now();
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'isPremium': false,
        'isAnonymous': isAnonymous,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      
      log('User document created for ${user.uid}');
    } catch (e) {
      // Log error but don't throw - user can still access the app
      log('Error creating user document: $e');
    }
  }

  // Check if user document exists
  Future<bool> _userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      log('Error checking user document existence: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
