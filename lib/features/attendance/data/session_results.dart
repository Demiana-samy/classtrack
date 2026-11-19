import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';
import '../../classes/data/student_info.dart';
import 'attendance_record.dart';
import 'attendance_session.dart';

/// Final attendance of one student in one session.
class ResultRow extends Equatable {
  const ResultRow({
    required this.studentId,
    required this.name,
    this.studentNumber = '',
    required this.status,
    this.distance,
    this.quizScore,
    this.quizSubmitted = false,
    this.timestamp,
  });

  final String studentId;
  final String name;
  final String studentNumber;
  final String status; // present | rejected | absent
  final double? distance;
  final int? quizScore;
  final bool quizSubmitted;
  final DateTime? timestamp;

  @override
  List<Object?> get props =>
      [studentId, name, studentNumber, status, distance, quizScore, quizSubmitted, timestamp];
}

/// Session Results (#10) logic. Pure Dart, no Firebase, unit tested in
/// `test/session_results_test.dart`.
class SessionResults {
  const SessionResults({required this.session, required this.rows});

  final AttendanceSession session;
  final List<ResultRow> rows;

  int get present => rows.where((r) => r.status == 'present').length;
  int get rejected => rows.where((r) => r.status == 'rejected').length;
  int get absent => rows.where((r) => r.status == 'absent').length;

  /// Average quiz score of present students (null for punch-in sessions).
  double? get averageScore {
    final scores = rows
        .where((r) => r.status == 'present' && r.quizScore != null)
        .map((r) => r.quizScore!)
        .toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Absent = enrolled before the session started AND no present/rejected record.
  /// Students who joined the class after the session are not counted at all.
  ///
  /// Order: present, then rejected, then absent. Inside each group the highest
  /// quiz score comes first, then the closest distance, then the name.
  static SessionResults build({
    required AttendanceSession session,
    required List<StudentInfo> students,
    required List<AttendanceRecord> records,
  }) {
    final byStudent = {for (final r in records) r.studentId: r};
    final rows = <ResultRow>[];
    final seen = <String>{};

    for (final s in students) {
      seen.add(s.id);
      final r = byStudent[s.id];
      final joinedLater = s.joinedAt != null && s.joinedAt!.isAfter(session.startTime);
      if (r == null && joinedLater) continue;
      rows.add(ResultRow(
        studentId: s.id,
        name: s.name,
        studentNumber: s.studentNumber,
        status: r?.status ?? 'absent',
        distance: r?.distance,
        quizScore: r?.quizScore,
        quizSubmitted: r?.quizSubmitted ?? false,
        timestamp: r?.timestamp,
      ));
    }
    // Records of students who are not in the roster anymore (left the class).
    for (final r in records) {
      if (seen.contains(r.studentId)) continue;
      rows.add(ResultRow(
        studentId: r.studentId,
        name: 'Former student',
        status: r.status,
        distance: r.distance,
        quizScore: r.quizScore,
        quizSubmitted: r.quizSubmitted,
        timestamp: r.timestamp,
      ));
    }

    rows.sort(compare);
    return SessionResults(session: session, rows: rows);
  }

  static int _rank(String status) => switch (status) {
        'present' => 0,
        'rejected' => 1,
        _ => 2,
      };

  static int compare(ResultRow a, ResultRow b) {
    final byStatus = _rank(a.status).compareTo(_rank(b.status));
    if (byStatus != 0) return byStatus;
    final byScore = (b.quizScore ?? -1).compareTo(a.quizScore ?? -1);
    if (byScore != 0) return byScore;
    final byDistance = (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity);
    if (byDistance != 0) return byDistance;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// CSV for the "Export CSV" button (bonus feature in the assignment).
  String toCsv({String className = ''}) {
    String cell(Object? v) {
      final t = v?.toString() ?? '';
      return t.contains(RegExp(r'[",\n]')) ? '"${t.replaceAll('"', '""')}"' : t;
    }

    final quiz = session.mode == Modes.quiz;
    final b = StringBuffer()
      ..writeln([
        'Class', 'Session ID', 'Student', 'Student ID', 'Distance (m)',
        if (quiz) 'Quiz',
        if (quiz) 'Score',
        'Attendance',
      ].join(','));
    for (final r in rows) {
      b.writeln([
        cell(className),
        cell(session.id),
        cell(r.name),
        cell(r.studentNumber),
        r.distance == null ? '' : r.distance!.round().toString(),
        if (quiz) r.quizSubmitted ? 'Submitted' : 'Not submitted',
        if (quiz) r.quizScore == null ? '' : '${r.quizScore}/${AppConstants.quizQuestionCount}',
        _label(r.status),
      ].join(','));
    }
    return b.toString();
  }

  static String _label(String status) => switch (status) {
        'present' => 'Present',
        'rejected' => 'Rejected',
        _ => 'Absent',
      };
}
