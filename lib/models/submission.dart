import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus { notSubmitted, submitted, graded }

class Submission {
  final String id;
  final String taskId;
  final String channelId;
  final String hubId;
  final String studentId;
  final String studentName;
  final String? fileUrl;
  final String? fileName;
  final String? submissionText;
  final SubmissionStatus status;
  final int? grade;
  final String? feedback;
  final Timestamp submittedAt;
  final Timestamp? gradedAt;
  final String? gradedBy;

  Submission({
    required this.id,
    required this.taskId,
    required this.channelId,
    required this.hubId,
    required this.studentId,
    required this.studentName,
    this.fileUrl,
    this.fileName,
    this.submissionText,
    required this.status,
    this.grade,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
    this.gradedBy,
  });

  // Convert submission to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'channelId': channelId,
      'hubId': hubId,
      'studentId': studentId,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submissionText': submissionText,
      'status': status.name,
      'grade': grade,
      'feedback': feedback,
      'submittedAt': submittedAt,
      'gradedAt': gradedAt,
      'gradedBy': gradedBy,
    };
  }

  // Create submission from map
  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      id: map['id'],
      taskId: map['taskId'],
      channelId: map['channelId'],
      hubId: map['hubId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      submissionText: map['submissionText'],
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubmissionStatus.notSubmitted,
      ),
      grade: map['grade'],
      feedback: map['feedback'],
      submittedAt: map['submittedAt'],
      gradedAt: map['gradedAt'],
      gradedBy: map['gradedBy'],
    );
  }
}
