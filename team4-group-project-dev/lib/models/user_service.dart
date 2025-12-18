//models that contain class data and types for app.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_handler.dart';
import 'user_handler.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<UserModel?> get currentUser {
    return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection('Users').doc(user.uid).get();
        return doc.exists ? UserModel.fromDocument(doc) : null;
      } catch (e) {
        print('Error getting user data: $e');
        return null;
      }
    });
  }

  static Future<String> getCurrentUserId() async {
    // Return the user's UID or an empty string if not signed in.
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // Returns the current logged-in user's profile from Firestore or null
  static Future<UserModel?> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('Users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromDocument(doc);
        }
      } catch (e) {
        //! Avoid printing in production; keep for debug builds only
        //! Use debugPrint which is noop in release mode
        debugPrint('Error fetching current user data: $e');
      }
    }
    return null;
  }

  //I hate flutter and i hate this db batching system lol
  static Future<void> createUser(
    UserModel user, {
    Map<String, Map<String, dynamic>>? subcollections,
  }) async {
    final docRef = _firestore.collection('Users').doc(user.id);
    final batch = _firestore.batch();

    //there's def a better way to seperatly push each value but this is what i got for now
    final data = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'bio': user.bio,
      'photoUrl': user.photoUrl,
      'phone': user.phone,
      'createdAt': FieldValue.serverTimestamp(),
      'tools': user.tools,
      'games': user.games,
      'address': user.address,
      'events': user.events,
    };

    batch.set(docRef, data);
    try {
      await batch.commit();
    } catch (e) {
      print('Error creating user with subcollections: $e');
      rethrow;
    }
  }

  //creates user if they aren't in the databse yet.
  static Future<void> createUserIfNotExists(
    UserModel user, {
    Map<String, Map<String, dynamic>>? subcollections,
  }) async {
    final docRef = _firestore.collection('Users').doc(user.id);
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await createUser(user, subcollections: subcollections);
      }
    } catch (e) {
      print('Error in createUserIfNotExists: $e');
      rethrow;
    }
  }

  // Update an existing user document. `fields` should contain the keys to update.
  // This performs a merge update so unspecified fields are preserved.
  static Future<void> updateUser(String id, Map<String, dynamic> fields) async {
    final docRef = _firestore.collection('Users').doc(id);
    try {
      await docRef.set(fields, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user $id: $e');
      rethrow;
    }
  }
}

// Strongly-typed forwarding function for convenience imports elsewhere.
// Ensure the top-level alias has an explicit type so callers don't see
// a `Future<dynamic>` when awaiting it.
Future<String> Function() getCurrentUserId = UserService.getCurrentUserId;
