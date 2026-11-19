import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../classes/data/class_info.dart';
import '../../classes/data/class_repository.dart';
import '../data/attendance_record.dart';
import '../data/attendance_repository.dart';
import '../data/attendance_session.dart';
import '../data/session_repository.dart';

/// One row of #16 Attendance History.
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.sessionId,
    required this.className,
    required this.date,
    required this.mode,
    required this.status,
    this.distance,
    this.quizScore,
  });

  final String sessionId;
  final String className;
  final DateTime date;
  final String mode;
  final String status; // present | rejected | absent
  final double? distance;
  final int? quizScore;

  @override
  List<Object?> get props => [sessionId, className, date, mode, status, distance, quizScore];
}

enum HistoryStatus { loading, ready, error }

class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState({
    this.status = HistoryStatus.loading,
    this.entries = const [],
    this.error,
  });

  final HistoryStatus status;
  final List<HistoryEntry> entries;
  final String? error;

  int count(String s) => entries.where((e) => e.status == s).length;

  @override
  List<Object?> get props => [status, entries, error];
}

/// Builds the history from my records plus finished sessions I have no record
/// for (those count as **absent**, like "Ali — Not submitted — Absent").
class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit(
    AttendanceRepository attendance,
    SessionRepository sessions,
    ClassRepository classes,
  )   : _attendance = attendance,
        _sessions = sessions,
        _classes = classes,
        super(const AttendanceHistoryState());

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  AttendanceHistoryCubit.preview()
      : _attendance = null,
        _sessions = null,
        _classes = null,
        super(const AttendanceHistoryState());

  final AttendanceRepository? _attendance;
  final SessionRepository? _sessions;
  final ClassRepository? _classes;

  Future<void> load(String studentId) async {
    if (state.status != HistoryStatus.loading) {
      emit(AttendanceHistoryState(entries: state.entries));
    }

    final attendance = _attendance;
    final sessions = _sessions;
    final classes = _classes;
    if (attendance == null || sessions == null || classes == null) {
      emit(AttendanceHistoryState(status: HistoryStatus.ready, entries: _previewEntries()));
      return;
    }

    try {
      final records = await attendance.fetchStudentRecords(studentId);
      final joined = await classes.fetchStudentJoinDates(studentId);
      final enrolled = joined.keys.toList();
      final classIds = {
        ...enrolled,
        ...records.map((r) => r.classId).where((id) => id.isNotEmpty),
      }.toList();

      // A class I left is no longer readable (rules): its name falls back to "Class".
      final infos = await Future.wait(
        classIds.map((id) => classes.fetchClassInfo(id).catchError((_) => null)),
      );
      final names = {
        for (final info in infos.whereType<ClassInfo>()) info.id: info.name,
      };
      // Absent rows only for classes I am still enrolled in.
      final sessionLists = await Future.wait(
        enrolled.map(
          (id) => sessions.fetchSessionHistory(id).catchError((_) => <AttendanceSession>[]),
        ),
      );

      final entries = buildEntries(
        records: records,
        sessions: sessionLists.expand((l) => l).toList(),
        classNames: names,
        joinedAt: joined,
        now: DateTime.now(),
      );
      if (!isClosed) emit(AttendanceHistoryState(status: HistoryStatus.ready, entries: entries));
    } catch (_) {
      if (!isClosed) {
        emit(const AttendanceHistoryState(
          status: HistoryStatus.error,
          error: 'Could not load your attendance. Check your connection.',
        ));
      }
    }
  }

  /// Pure merge step, kept static so it can be unit tested without Firebase.
  static List<HistoryEntry> buildEntries({
    required List<AttendanceRecord> records,
    required List<AttendanceSession> sessions,
    required Map<String, String> classNames,
    Map<String, DateTime?> joinedAt = const {},
    required DateTime now,
  }) {
    final bySession = {for (final r in records) r.sessionId: r};
    final sessionById = {for (final s in sessions) s.id: s};
    final entries = <HistoryEntry>[];

    for (final s in sessions) {
      final r = bySession[s.id];
      if (r == null && s.isOpenAt(now)) continue; // still running: not absent yet
      final since = joinedAt[s.classId];
      if (r == null && since != null && s.startTime.isBefore(since)) continue; // before I joined
      entries.add(HistoryEntry(
        sessionId: s.id,
        className: classNames[s.classId] ?? 'Class',
        date: s.startTime,
        mode: s.mode,
        status: r?.status ?? 'absent',
        distance: r?.distance,
        quizScore: r?.quizScore,
      ));
    }
    // Records whose session is not in the list (e.g. older than the fetch limit).
    for (final r in records) {
      if (sessionById.containsKey(r.sessionId)) continue;
      entries.add(HistoryEntry(
        sessionId: r.sessionId,
        className: classNames[r.classId] ?? 'Class',
        date: r.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0),
        mode: r.quizScore != null || r.quizSubmitted ? Modes.quiz : Modes.punchIn,
        status: r.status,
        distance: r.distance,
        quizScore: r.quizScore,
      ));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static List<HistoryEntry> _previewEntries() => [
        HistoryEntry(
          sessionId: 'p1',
          className: 'Mobile Programming',
          date: DateTime(2026, 9, 22, 9),
          mode: Modes.quiz,
          status: 'present',
          distance: 18,
          quizScore: 5,
        ),
        HistoryEntry(
          sessionId: 'p2',
          className: 'Databases',
          date: DateTime(2026, 9, 21, 11),
          mode: Modes.punchIn,
          status: 'present',
          distance: 12,
        ),
        HistoryEntry(
          sessionId: 'p3',
          className: 'Networks',
          date: DateTime(2026, 9, 20, 10),
          mode: Modes.punchIn,
          status: 'rejected',
          distance: 183,
        ),
        HistoryEntry(
          sessionId: 'p4',
          className: 'Mobile Programming',
          date: DateTime(2026, 9, 15, 9),
          mode: Modes.punchIn,
          status: 'absent',
        ),
      ];
}
