import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_project/models/message.dart';

class HubMessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? getCurrentUser() => _auth.currentUser;

  // Create a new channel in a hub
  Future<String> createChannel(String hubId, String channelName, String channelType) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    final channelId = "${hubId}_${channelName.replaceAll(' ', '_').toLowerCase()}";

    final channelData = {
      'id': channelId,
      'name': channelName,
      'type': channelType, // 'text', 'voice', etc.
      'hubId': hubId,
      'createdBy': user.uid,
      'createdAt': Timestamp.now(),
      'lastActivity': Timestamp.now(),
    };

    await _firestore.collection('channels').doc(channelId).set(channelData);
    return channelId;
  }

  // Get all channels for a hub
  Stream<QuerySnapshot> getChannelsStream(String hubId) {
    return _firestore
        .collection('channels')
        .where('hubId', isEqualTo: hubId)
        .snapshots();
  }

  // Send message to a channel
  Future<void> sendChannelMessage(String channelId, String message) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    // Get user name from Users collection
    final userDoc = await _firestore.collection('Users').doc(user.uid).get();
    String userName = 'Unknown';
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['name'] != null) {
        userName = userData['name'];
      }
    }

    final newMessage = Message(
      senderID: user.uid,
      senderEmail: user.email ?? 'Unknown',
      senderName: userName,
      receiverID: channelId,
      message: message,
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update last activity
    await _firestore.collection('channels').doc(channelId).update({
      'lastActivity': Timestamp.now(),
    });
  }

  // Get messages for a channel
  Stream<QuerySnapshot> getChannelMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get hub members
  Stream<QuerySnapshot> getHubMembers(String hubId) {
    return _firestore
        .collection('Groups')
        .doc(hubId)
        .snapshots()
        .asyncMap((hubDoc) async {
          if (!hubDoc.exists) return _firestore.collection('Users').where('uid', isEqualTo: 'nonexistent').get();

          final hubData = hubDoc.data() as Map<String, dynamic>;
          final memberIds = List<String>.from(hubData['members'] ?? []);

          if (memberIds.isEmpty) return _firestore.collection('Users').where('uid', isEqualTo: 'nonexistent').get();

          return _firestore
              .collection('Users')
              .where(FieldPath.documentId, whereIn: memberIds)
              .get();
        });
  }

  // Leave hub
  Future<void> leaveHub(String hubId) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    final hubDoc = await _firestore.collection('Groups').doc(hubId).get();
    if (!hubDoc.exists) throw Exception("Hub not found");

    final hubData = hubDoc.data() as Map<String, dynamic>;
    final members = List<String>.from(hubData['members'] ?? []);

    if (!members.contains(user.uid)) {
      throw Exception("You are not a member of this hub");
    }

    members.remove(user.uid);
    await _firestore.collection('Groups').doc(hubId).update({
      'members': members,
      'lastActive': Timestamp.now(),
    });
  }

  // Delete channel (moderator only)
  Future<void> deleteChannel(String channelId) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    final channelDoc = await _firestore.collection('channels').doc(channelId).get();
    if (!channelDoc.exists) throw Exception("Channel not found");

    final channelData = channelDoc.data() as Map<String, dynamic>;
    if (channelData['createdBy'] != user.uid) {
      throw Exception("Only channel creator can delete it");
    }

    // Delete all messages in the channel
    final messages = await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .get();

    for (var message in messages.docs) {
      await message.reference.delete();
    }

    // Delete the channel
    await _firestore.collection('channels').doc(channelId).delete();
  }
}
