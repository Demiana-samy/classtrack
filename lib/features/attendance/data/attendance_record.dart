import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// One document from `attendance_records` (written only by submitAttendance).
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.sessionId,
    required this.studentId,
    required this.classId,
    required this.status,
    this.timestamp,
    this.distance,
    this.quizScore,
    this.quizSubmitted = false,
  });

  final String sessionId;
  final String studentId;
  final String classId;
  final String status; // present | rejected | absent
  final DateTime? timestamp;
  final double? distance;
  final int? quizScore;
  final bool quizSubmitted;

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
        sessionId: m['sessionID'] as String? ?? '',
        studentId: m['studentID'] as String? ?? '',
        classId: m['classID'] as String? ?? '',
        status: m['status'] as String? ?? 'rejected',
        timestamp: (m['timestamp'] as Timestamp?)?.toDate(),
        distance: (m['distance'] as num?)?.toDouble(),
        quizScore: (m['quizScore'] as num?)?.toInt(),
        quizSubmitted: m['quizSubmitted'] == true,
      );

  @override
  List<Object?> get props =>
      [sessionId, studentId, classId, status, timestamp, distance, quizScore, quizSubmitted];
}
