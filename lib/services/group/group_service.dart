import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String groupsCollection = 'Groups';
  final String usersCollection = 'Users';

  User? getCurrentUser() => _auth.currentUser;

  // 1. Create a new Hub (Class or Organization)
  Future<void> createNewHub({
    required String name,
    required String type, // 'Class' or 'Organization'
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      throw Exception("User not logged in.");
    }

    final String groupType = type == 'Class' ? 'Classes' : 'Organizations';

    // Fetch the user's name (we need this for the hub creatorName)
    DocumentSnapshot userDoc = await _firestore.collection(usersCollection).doc(user.uid).get();
    String creatorName = userDoc.exists ? userDoc.get('name') ?? user.email!.split('@').first : user.email!.split('@').first;
    
    // Create the new Hub document
    final newHub = {
      'name': name,
      'groupType': groupType, // Stored as 'Classes' or 'Organizations'
      'creatorId': user.uid,
      'creatorName': creatorName,
      'members': [user.uid], // Creator is the first member
      'createdAt': Timestamp.now(),
      'lastActive': Timestamp.now(),
    };

    try {
      await _firestore.collection(groupsCollection).add(newHub);
      if (kDebugMode) {
        print("Successfully created new hub: $name");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error creating hub: $e");
      }
      throw Exception("Failed to create hub: $e");
    }
  }
  
  // 2. Stream all Hubs the current user is a member of
  Stream<List<Map<String, dynamic>>> getHubsStream() {
    final user = getCurrentUser();
    if (user == null) {
      if (kDebugMode) {
        print("User is null. Returning empty stream.");
      }
      return Stream.value([]);
    }

    // Query groups where the 'members' array field contains the current user's UID.
    return _firestore
        .collection(groupsCollection)
        .where('members', arrayContains: user.uid)
        .orderBy('lastActive', descending: true) // Sort by most recently active
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the Firestore document ID as the groupId to the data map
        data['groupId'] = doc.id; 
        return data;
      }).toList();
    });
  }
}