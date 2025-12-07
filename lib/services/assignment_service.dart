import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:final_project/models/assignment.dart';
import 'package:final_project/models/submission.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? getCurrentUser() => _auth.currentUser;

  // Create a new assignment
  Future<String> createAssignment({
    required String channelId,
    required String hubId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    final assignmentId = "${channelId}_${DateTime.now().millisecondsSinceEpoch}";

    final assignment = Assignment(
      id: assignmentId,
      channelId: channelId,
      hubId: hubId,
      title: title,
      description: description,
      dueDate: dueDate,
      createdBy: user.uid,
      createdAt: Timestamp.now(),
    );

    await _firestore.collection('assignments').doc(assignmentId).set(assignment.toMap());
    return assignmentId;
  }

  // Get assignments for a channel
  Stream<QuerySnapshot> getAssignmentsStream(String channelId) {
    return _firestore
        .collection('assignments')
        .where('channelId', isEqualTo: channelId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Submit assignment
  Future<void> submitAssignment({
    required String assignmentId,
    required String channelId,
    required String hubId,
    String? submissionText,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    print("Starting assignment submission");
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");
    print("User logged in: ${user.uid}");

    // Get user name
    final userDoc = await _firestore.collection('Users').doc(user.uid).get();
    String userName = 'Unknown';
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['name'] != null) {
        userName = userData['name'];
      }
    }
    print("User name: $userName");

    String? fileUrl;

    if (fileBytes != null && fileName != null) {
      print("Uploading file: $fileName, size: ${fileBytes.length}");
      // Upload file to Firebase Storage
      final storageRef = _storage.ref().child('submissions/$assignmentId/$userName/$fileName');
      try {
        final uploadTask = storageRef.putData(fileBytes);
        print("Starting upload task...");
        await uploadTask;
        print("Upload task completed");
        fileUrl = await storageRef.getDownloadURL();
        print("File uploaded successfully: $fileUrl");
      } catch (e) {
        print("Error uploading file: $e");
        print("Error type: ${e.runtimeType}");
        if (e is FirebaseException) {
          print("Firebase error code: ${e.code}");
          print("Firebase error message: ${e.message}");
        }
        throw e;
      }
    } else {
      print("No file to upload");
    }

    final submissionId = "${assignmentId}_${user.uid}";
    print("Creating submission: $submissionId");

    final submission = Submission(
      id: submissionId,
      assignmentId: assignmentId,
      channelId: channelId,
      hubId: hubId,
      studentId: user.uid,
      studentName: userName,
      fileUrl: fileUrl,
      fileName: fileName,
      submissionText: submissionText,
      status: SubmissionStatus.submitted,
      submittedAt: Timestamp.now(),
    );

    try {
      await _firestore.collection('submissions').doc(submissionId).set(submission.toMap());
      print("Submission saved to Firestore");
    } catch (e) {
      print("Error saving submission: $e");
      throw e;
    }
  }

  // Get submissions for an assignment (moderator only)
  Stream<QuerySnapshot> getSubmissionsStream(String assignmentId) {
    return _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  // Get user's submission for an assignment
  Future<Submission?> getUserSubmission(String assignmentId) async {
    final user = getCurrentUser();
    if (user == null) return null;

    final submissionId = "${assignmentId}_${user.uid}";
    final doc = await _firestore.collection('submissions').doc(submissionId).get();

    if (doc.exists) {
      return Submission.fromMap(doc.data()!);
    }
    return null;
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required int grade,
    String? feedback,
  }) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    await _firestore.collection('submissions').doc(submissionId).update({
      'status': SubmissionStatus.graded.name,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': Timestamp.now(),
      'gradedBy': user.uid,
    });
  }

  // Delete assignment (moderator only)
  Future<void> deleteAssignment(String assignmentId) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    final assignmentDoc = await _firestore.collection('assignments').doc(assignmentId).get();
    if (!assignmentDoc.exists) throw Exception("Assignment not found");

    final assignment = Assignment.fromMap(assignmentDoc.data()!);
    if (assignment.createdBy != user.uid) {
      throw Exception("Only assignment creator can delete it");
    }

    // Delete all submissions
    final submissions = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .get();

    for (var submission in submissions.docs) {
      await submission.reference.delete();
    }

    // Delete the assignment
    await _firestore.collection('assignments').doc(assignmentId).delete();
  }
}
