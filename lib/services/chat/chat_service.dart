import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {

// get instance of firestore & auth
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

//get user stream
Stream<List<Map<String, dynamic>>> getUsersStream() {
  return _firestore.collection("Users").snapshots().map((snapshots) {
    return snapshots.docs.map((doc){
    //go throiugh each individual user
    final user = doc.data(); 

    //return user data
    return user;
  }).toList();
});
}
//send message

Future<void> sendMessage(String recieverID, message)async{

  //get current user
  final String currentUserID = _auth.currentUser!.uid;
  final String currentUserEmail = _auth.currentUser!.email!;
  final Timestamp timestamp = Timestamp.now();

  // Get user name from Users collection
  final userDoc = await _firestore.collection('Users').doc(currentUserID).get();
  String userName = 'Unknown';
  if (userDoc.exists) {
    final userData = userDoc.data();
    if (userData != null && userData['name'] != null) {
      userName = userData['name'];
    }
  }

  //create a new message
  Message newMessage = Message(
    senderID: currentUserID,
    senderEmail: currentUserEmail,
    senderName: userName,
    receiverID: recieverID,
    message: message,
    timestamp: timestamp,
  );
  //construct chat room id for the two users(sorted order)
  List<String> ids = [currentUserID, recieverID];
  ids.sort();
  String chatRoomID = ids.join('_');
  //add new message to database

  await _firestore
  .collection("chat_rooms")
  .doc(chatRoomID)
  .collection("messages")
  .add(newMessage.toMap());
}

//get messages

Stream<QuerySnapshot> getMessages(String userID, otherUserID){
  //construct chatroom ID for the two users
  List<String> ids = [userID, otherUserID];
  ids.sort();
  String chatRoomID = ids.join("_");

  return _firestore.collection("chat_rooms")
  .doc(chatRoomID)
  .collection("messages")
  .orderBy("timestamp", descending:false)
  .snapshots();
}
}