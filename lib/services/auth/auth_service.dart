import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthService {

  //instance of auth & firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get current 
  User? getCurrentUser() {
    return _auth.currentUser;
  }


  // sing in
  Future<UserCredential> signInWithEmailAndPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password);

         // save user info if it doesnt already exist
     _firestore.collection("Users").doc(userCredential.user!.uid).set({
    
      "uid": userCredential.user!.uid,
      "email": email,
     });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }

  }
  //sign up

  Future<UserCredential> signUpWithEmailAndPassword(String email, password) async{
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
        );
     
     
     // save user info in a separate doc
     _firestore.collection("Users").doc(userCredential.user!.uid).set({
    
      "uid": userCredential.user!.uid,
      "email": email,
     });
     
     
     
     
     return userCredential;
    } on FirebaseAuthException catch (e){
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> signOut() async {
   return await _auth.signOut();
  }


  //errros
}