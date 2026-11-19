import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import 'attendance_record.dart';

/// Result returned by the `submitAttendance` Cloud Function.
class AttendanceResult {
  const AttendanceResult({
    required this.accepted,
    required this.status,
    this.reason,
    this.distance,
    this.radius,
    this.quizScore,
  });

  final bool accepted;
  final String status; // present | rejected
  final String? reason; // session_expired | not_enrolled | out_of_range | already_attended | ...
  final double? distance;
  final num? radius;
  final int? quizScore;

  factory AttendanceResult.fromMap(Map<dynamic, dynamic> m) => AttendanceResult(
        accepted: m['accepted'] as bool,
        status: m['status'] as String,
        reason: m['reason'] as String?,
        distance: (m['distance'] as num?)?.toDouble(),
        radius: m['radius'] as num?,
        quizScore: (m['quizScore'] as num?)?.toInt(),
      );
}

class AttendanceRepository {
  AttendanceRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// The ONLY way to create an attendance record. All checks run on the server.
  /// [answers] = chosen option index (0..3) per question, only for quiz mode.
  Future<AttendanceResult> submit({
    required String sessionId,
    required double latitude,
    required double longitude,
    List<int>? answers,
  }) async {
    final res = await _functions.httpsCallable('submitAttendance').call({
      'sessionId': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      if (answers != null) 'answers': answers,
    });
    return AttendanceResult.fromMap(res.data as Map);
  }

  /// Live records for the teacher's dashboard. The `teacherID` filter is
  /// required: firestore.rules only allow records of the teacher's own sessions.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessionRecords(
    String sessionId, {
    required String teacherId,
  }) =>
      _db
          .collection(Col.records)
          .where('sessionID', isEqualTo: sessionId)
          .where('teacherID', isEqualTo: teacherId)
          .snapshots();

  /// The student's own records (firestore.rules allow studentID == me only).
  Future<List<AttendanceRecord>> fetchStudentRecords(String studentId) async {
    final q = await _db.collection(Col.records).where('studentID', isEqualTo: studentId).get();
    return q.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudentRecords(String studentId) => _db
      .collection(Col.records)
      .where('studentID', isEqualTo: studentId)
      .snapshots();
}
