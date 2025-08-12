import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/storage_service.dart';
import 'dart:convert';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String _error = '';

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _user?.role == AppConstants.adminRole;

  // Constructor - automatically check user state on initialization
  AuthController() {
    _checkCurrentUser();
  }

  // Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message and notify listeners
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Check if a user is already logged in
  Future<void> _checkCurrentUser() async {
    _setLoading(true);
    
    // Check for cached user data first
    final cachedUserData = StorageService.getString(AppConstants.userDataKey);
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        // If we have a user but no cached data, fetch from Firestore
        if (cachedUserData == null) {
          await _fetchUserData(user.uid);
        } else {
          // Use cached data for faster loading
          _user = UserModel.fromJson(json.decode(cachedUserData));
        }
      } else {
        _user = null;
        await StorageService.saveString(AppConstants.userDataKey, '');
      }

      _setLoading(false);
    });
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        _user = UserModel.fromSnapshot(docSnapshot);

        // Cache user data for faster loading next time
        await StorageService.saveString(
          AppConstants.userDataKey,
          json.encode(_user!.toJson())
        );
      }
    } catch (e) {
      _setError('Failed to fetch user data: $e');
    }
  }

  // Register a new user
  Future<bool> register({
    required String fullname,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Create the user in Firebase Auth
      final UserCredential authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        // Create user document in Firestore
        final UserModel newUser = UserModel(
          id: authResult.user!.uid,
          fullname: fullname,
          email: email,
          role: AppConstants.userRole, // Default to user role
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(authResult.user!.uid)
            .set(newUser.toJson());

        // Update local user state
        _user = newUser;
        _firebaseUser = authResult.user;

        // Cache user data
        await StorageService.saveString(
          AppConstants.userDataKey,
          json.encode(newUser.toJson())
        );

        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            _setError('Email is already in use. Please try another email.');
            break;
          case 'weak-password':
            _setError('Password is too weak. Please use a stronger password.');
            break;
          case 'invalid-email':
            _setError('Invalid email address. Please check and try again.');
            break;
          default:
            _setError('Registration failed: ${e.message}');
        }
      } else {
        _setError('Registration failed: $e');
      }

      return false;
    }
  }

  // Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      final UserCredential authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        await _fetchUserData(authResult.user!.uid);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            _setError('Invalid email or password. Please try again.');
            break;
          case 'user-disabled':
            _setError('This account has been disabled. Please contact support.');
            break;
          case 'too-many-requests':
            _setError('Too many failed login attempts. Please try again later.');
            break;
          default:
            _setError('Login failed: ${e.message}');
        }
      } else {
        _setError('Login failed: $e');
      }

      return false;
    }
  }

  // Forgot password - send reset email
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError('');

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _setError('No user found with this email address.');
            break;
          case 'invalid-email':
            _setError('Invalid email address. Please check and try again.');
            break;
          default:
            _setError('Password reset failed: ${e.message}');
        }
      } else {
        _setError('Password reset failed: $e');
      }

      return false;
    }
  }

  // Logout the current user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _auth.signOut();
      _user = null;
      _firebaseUser = null;

      // Clear cached user data
      await StorageService.saveString(AppConstants.userDataKey, '');
    } catch (e) {
      _setError('Logout failed: $e');
    }

    _setLoading(false);
  }

  // Update user information in memory
  void refreshUser(UserModel updatedUser) {
    _user = updatedUser;

    // Cache updated user data
    StorageService.saveString(
      AppConstants.userDataKey,
      json.encode(updatedUser.toJson())
    );

    notifyListeners();
  }

  // Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Re-authenticate the user before changing password
      if (_firebaseUser == null || _firebaseUser!.email == null) {
        throw Exception('User not authenticated');
      }

      // Create credential for re-authentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );

      // Re-authenticate
      await _firebaseUser!.reauthenticateWithCredential(credential);

      // Change password
      await _firebaseUser!.updatePassword(newPassword);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Current password is incorrect');
          case 'weak-password':
            throw Exception('New password is too weak');
          case 'requires-recent-login':
            throw Exception('Please log in again before changing your password');
          default:
            throw Exception('Failed to change password: ${e.message}');
        }
      } else {
        throw Exception('Failed to change password: $e');
      }
    }
  }
}
