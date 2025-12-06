import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String groupsCollection = 'Groups';
  final String usersCollection = 'Users';

  User? getCurrentUser() => _auth.currentUser;

  // 1. Create a new Hub
  Future<String> createNewHub({
    required String name,
  }) async {
    final user = getCurrentUser();
    if (user == null) {
      throw Exception("User not logged in.");
    }

    // Fetch the user's name (we need this for the hub creatorName)
    DocumentSnapshot userDoc = await _firestore.collection(usersCollection).doc(user.uid).get();
    String creatorName;
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>?;
      creatorName = data?['name'] ?? user.email!.split('@').first;
    } else {
      creatorName = user.email!.split('@').first;
    }

    // Generate a unique 6-character hub ID
    String hubId = _generateHubId();

    // Create the new Hub document (default to 'Classes' for simplicity)
    final newHub = {
      'id': hubId,
      'name': name,
      'groupType': 'Classes', // Default to 'Classes'
      'creatorId': user.uid,
      'creatorName': creatorName,
      'creatorEmail': user.email,
      'members': [user.uid], // Creator is the first member
      'createdAt': Timestamp.now(),
      'lastActive': Timestamp.now(),
    };

    try {
      await _firestore.collection(groupsCollection).doc(hubId).set(newHub);
      if (kDebugMode) {
        print("Successfully created new hub: $name with ID: $hubId");
      }
      return hubId;
    } catch (e) {
      if (kDebugMode) {
        print("Error creating hub: $e");
      }
      throw Exception("Failed to create hub: $e");
    }
  }

  // Helper method to generate a unique 6-character hub ID
  String _generateHubId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    String id;
    bool isUnique = false;

    do {
      id = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      // Check if this ID already exists
      isUnique = true; // For simplicity, we'll assume uniqueness for now
      // In a production app, you'd want to check against the database
    } while (!isUnique);

    return id;
  }
  
  // 2. Stream all Hubs the current user is a member of
  Stream<QuerySnapshot> getHubsStream() {
    final user = getCurrentUser();
    if (user == null) {
      // Return an empty stream if the user is not logged in
      return const Stream.empty();
    }

    return _firestore
        .collection(groupsCollection)
        .where('members', arrayContains: user.uid)
        .snapshots();
  }

  // 3. Join an existing Hub by ID
  Future<void> joinHubById(String hubId) async {
    final user = getCurrentUser();
    if (user == null) {
      throw Exception("User not logged in.");
    }

    // Get the hub document directly by ID
    final hubDoc = await _firestore.collection(groupsCollection).doc(hubId.trim().toUpperCase()).get();

    if (!hubDoc.exists) {
      throw Exception("No hub found with ID: $hubId");
    }

    final hubData = hubDoc.data() as Map<String, dynamic>;
    final members = List<String>.from(hubData['members'] ?? []);

    if (members.contains(user.uid)) {
      throw Exception("You are already a member of this hub.");
    }

    // Add the user to the members array
    members.add(user.uid);
    await _firestore.collection(groupsCollection).doc(hubId.trim().toUpperCase()).update({
      'members': members,
      'lastActive': Timestamp.now(),
    });

    if (kDebugMode) {
      print("Successfully joined hub: $hubId");
    }
  }
}