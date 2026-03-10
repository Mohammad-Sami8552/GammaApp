import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: kIsWeb
  ? "91787931989-fg4npdcbubjegccplt3iieqelatgd8dt.apps.googleusercontent.com": null,
  serverClientId: kIsWeb? null: "91787931989-fg4npdcbubjegccplt3iieqelatgd8dt.apps.googleusercontent.com",
  scopes: [
    'email',
    // 'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if(credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      UserCredential credential;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        credential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // FIX 1: Use 'signIn()' instead of 'authenticate()'
        // FIX 2: Add '?' because the user might cancel (return null)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        // Check if user canceled the login
        if (googleUser == null) {
          return; // Stop the function here
        }

        // FIX 3: Add 'await' because authentication is a Future
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _firebaseAuth.signInWithCredential(cred);
      }

      // Save user to Firestore if new
      if (credential.user != null) {
        final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'email': credential.user!.email,
            'createdAt': FieldValue.serverTimestamp(), // Fixed typo 'createAt' -> 'createdAt'
          });
        }
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}