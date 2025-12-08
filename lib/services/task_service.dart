import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_project/models/submission.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new task
  Future<String> createTask({
    required String hubId,
    required String channelId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final taskDoc = await _firestore.collection('tasks').add({
        'hubId': hubId,
        'channelId': channelId,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'createdBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return taskDoc.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get task by ID
  Future<DocumentSnapshot> getTask(String taskId) async {
    try {
      return await _firestore.collection('tasks').doc(taskId).get();
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Get tasks for a hub
  Stream<QuerySnapshot> getTasksStream(String hubId) {
    return _firestore
        .collection('tasks')
        .where('hubId', isEqualTo: hubId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Submit a task
  Future<String> submitTask({
    required String taskId,
    required String channelId,
    required String submissionText,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already submitted
      final existingSubmission = await _firestore
          .collection('submissions')
          .where('taskId', isEqualTo: taskId)
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (existingSubmission.docs.isNotEmpty) {
        throw Exception('Task already submitted');
      }

      final submissionDoc = await _firestore.collection('submissions').add({
        'taskId': taskId,
        'channelId': channelId,
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Unknown',
        'submissionText': submissionText,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
      });

      return submissionDoc.id;
    } catch (e) {
      throw Exception('Failed to submit task: $e');
    }
  }

  // Get user's submission for a task
  Future<Submission?> getUserSubmission(String channelId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('submissions')
          .where('channelId', isEqualTo: channelId)
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Submission.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get user submission: $e');
    }
  }

  // Get all submissions for a task
  Stream<QuerySnapshot> getSubmissionsStream(String channelId) {
    return _firestore
        .collection('submissions')
        .where('channelId', isEqualTo: channelId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Grade a submission
  Future<void> gradeSubmission({
    required String submissionId,
    required int grade,
  }) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
      });
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      // Delete all submissions for this task
      final submissions = await _firestore
          .collection('submissions')
          .where('taskId', isEqualTo: taskId)
          .get();

      for (final submission in submissions.docs) {
        await submission.reference.delete();
      }

      // Delete the task
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
