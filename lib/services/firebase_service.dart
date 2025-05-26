import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String studentId,
  }) async {
    try {
      developer.log('Starting signup process for email: $email', name: 'FirebaseService');
      
      // Create the user account
      developer.log('Attempting to create user in Firebase Auth...', name: 'FirebaseService');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user
      final user = userCredential.user;
      if (user == null) {
        developer.log('User creation failed - user is null', name: 'FirebaseService', error: 'User credential returned null user');
        throw 'Failed to create user account';
      }

      developer.log('User created successfully in Firebase Auth with UID: ${user.uid}', name: 'FirebaseService');

      // Create a Map for the user data
      final userData = {
        'email': email,
        'username': username,
        'studentId': studentId,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'student',
        'uid': user.uid,
      };

      developer.log('Attempting to create Firestore document with data: $userData', name: 'FirebaseService');

      try {
        // Create the user document in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData);

        developer.log('User document created in Firestore successfully', name: 'FirebaseService');
      } catch (firestoreError) {
        developer.log(
          'Error creating Firestore document',
          name: 'FirebaseService',
          error: firestoreError.toString(),
          stackTrace: StackTrace.current,
        );
        // If Firestore fails, we should clean up the Auth user
        try {
          await user.delete();
          developer.log('Cleaned up Auth user after Firestore failure', name: 'FirebaseService');
        } catch (deleteError) {
          developer.log(
            'Error deleting Auth user after Firestore failure',
            name: 'FirebaseService',
            error: deleteError.toString(),
          );
        }
        rethrow;
      }

    } on FirebaseAuthException catch (e) {
      developer.log(
        'FirebaseAuthException during signup',
        name: 'FirebaseService',
        error: '${e.code} - ${e.message}',
        stackTrace: e.stackTrace,
      );
      switch (e.code) {
        case 'email-already-in-use':
          throw 'This email is already registered. Please use a different email.';
        case 'invalid-email':
          throw 'The email address is not valid.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        case 'weak-password':
          throw 'The password is too weak. Please use a stronger password.';
        default:
          throw 'An error occurred during signup: ${e.message}';
      }
    } on FirebaseException catch (e) {
      developer.log(
        'FirebaseException during signup',
        name: 'FirebaseService',
        error: '${e.code} - ${e.message}',
        stackTrace: e.stackTrace,
      );
      throw 'An error occurred while saving user data: ${e.message}';
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during signup',
        name: 'FirebaseService',
        error: e.toString(),
        stackTrace: stackTrace,
      );
      throw 'An unexpected error occurred during signup: $e';
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Incorrect password.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        default:
          throw 'An error occurred: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
} 