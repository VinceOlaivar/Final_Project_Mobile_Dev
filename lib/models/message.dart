import 'package:cloud_firestore/cloud_firestore.dart';


class Message{
  final String senderID;
  final String senderEmail;
  final String senderName;
  final String receiverID;
  final String message;
  final Timestamp timestamp;


  Message({
    required this.senderID,
    required this.senderEmail,
    required this.senderName,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  //convert message to map
  Map<String, dynamic> toMap(){
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
    };
  }

  //create message from map
  factory Message.fromMap(Map<String, dynamic> map){
    return Message(
      senderID: map['senderID'],
      senderEmail: map['senderEmail'],
      senderName: map['senderName'] ?? 'Unknown',
      receiverID: map['receiverID'],
      message: map['message'],
      timestamp: map['timestamp'],
    );
  }
}