import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

/// One document from `attendance_sessions` (written only by the startSession Cloud Function).
class AttendanceSession extends Equatable {
  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.mode,
    required this.radius,
    required this.startTime,
    required this.expiryTime,
    required this.status,
  });

  final String id;
  final String classId;
  final String mode; // Modes.punchIn | Modes.quiz
  final int radius;
  final DateTime startTime;
  final DateTime expiryTime;
  final String status; // 'active' | 'closed'

  bool get isQuiz => mode == Modes.quiz;

  /// Active means the server says active AND the expiry time has not passed.
  bool isOpenAt(DateTime now) => status == 'active' && now.isBefore(expiryTime);

  Duration remainingAt(DateTime now) {
    final left = expiryTime.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  factory AttendanceSession.fromMap(String id, Map<String, dynamic> m) {
    DateTime time(Object? v) =>
        v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    return AttendanceSession(
      id: id,
      classId: m['classID'] as String? ?? '',
      mode: m['mode'] as String? ?? Modes.punchIn,
      radius: (m['radius'] as num?)?.toInt() ?? AppConstants.defaultRadiusMeters,
      startTime: time(m['startTime']),
      expiryTime: time(m['expiryTime']),
      status: m['status'] as String? ?? 'closed',
    );
  }

  @override
  List<Object?> get props => [id, classId, mode, radius, startTime, expiryTime, status];
}
