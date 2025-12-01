import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instance of auth & firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign up - SIMPLIFIED VERSION
  // Note: The 'role' parameter has been removed from the function signature.
  Future<UserCredential> signUpWithEmailAndPassword(
    String email, 
    String password,
    Map<String, dynamic> userData, // Flexible map for profile data
  ) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );

      // 2. Prepare the base data, defaulting role to 'General'
      Map<String, dynamic> finalData = {
        "uid": userCredential.user!.uid,
        "email": email,
        "role": "General", // <-- Default role for all new signups
        "createdAt": Timestamp.now(),
      };

      // 3. Merge with the specific user data
      // Only include non-empty values from userData to keep Firestore clean
      userData.forEach((key, value) {
        if (value.toString().isNotEmpty) {
          finalData[key] = value;
        }
      });

      // 4. Save to Firestore
      await _firestore.collection("Users").doc(userCredential.user!.uid).set(finalData);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // NEW: Method to update user's role upon group creation
  // This will be used in home_page.dart when a 'General' user creates a Class or Organization.
  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('Users').doc(userId).update({'role': newRole});
  }
}