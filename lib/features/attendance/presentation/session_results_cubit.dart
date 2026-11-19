import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../classes/data/class_info.dart';
import '../../classes/data/class_repository.dart';
import '../../classes/data/student_info.dart';
import '../data/attendance_record.dart';
import '../data/attendance_repository.dart';
import '../data/attendance_session.dart';
import '../data/session_repository.dart';
import '../data/session_results.dart';

enum ResultsStatus { loading, ready, notFound, error }

class SessionResultsState extends Equatable {
  const SessionResultsState({
    this.status = ResultsStatus.loading,
    this.results,
    this.className = '',
    this.error,
  });

  final ResultsStatus status;
  final SessionResults? results;
  final String className;
  final String? error;

  @override
  List<Object?> get props => [status, results?.rows, results?.session, className, error];
}

/// #10 Session Results: present, rejected and absent students, ordered by score.
class SessionResultsCubit extends Cubit<SessionResultsState> {
  SessionResultsCubit(
    SessionRepository sessions,
    AttendanceRepository attendance,
    ClassRepository classes,
  )   : _sessions = sessions,
        _attendance = attendance,
        _classes = classes,
        super(const SessionResultsState());

  /// In-memory cubit for Design Preview and widget tests (assignment example data).
  SessionResultsCubit.preview()
      : _sessions = null,
        _attendance = null,
        _classes = null,
        super(const SessionResultsState());

  final SessionRepository? _sessions;
  final AttendanceRepository? _attendance;
  final ClassRepository? _classes;

  Future<void> load({required String sessionId, required String teacherId}) async {
    emit(const SessionResultsState());
    final sessions = _sessions;
    final attendance = _attendance;
    final classes = _classes;
    if (sessions == null || attendance == null || classes == null) {
      emit(SessionResultsState(
        status: ResultsStatus.ready,
        className: 'Mobile Programming',
        results: previewResults(sessionId),
      ));
      return;
    }
    try {
      final session = await sessions.fetchSession(sessionId);
      if (session == null) {
        if (!isClosed) emit(const SessionResultsState(status: ResultsStatus.notFound));
        return;
      }
      final loaded = await Future.wait<Object?>([
        classes.fetchClassStudents(session.classId),
        attendance.fetchSessionRecords(sessionId, teacherId: teacherId),
        classes.fetchClassInfo(session.classId),
      ]);
      final info = loaded[2] as ClassInfo?;
      if (isClosed) return;
      emit(SessionResultsState(
        status: ResultsStatus.ready,
        className: info?.name ?? '',
        results: SessionResults.build(
          session: session,
          students: loaded[0] as List<StudentInfo>,
          records: loaded[1] as List<AttendanceRecord>,
        ),
      ));
    } catch (_) {
      if (!isClosed) {
        emit(const SessionResultsState(
          status: ResultsStatus.error,
          error: 'Could not load the results. Check your connection.',
        ));
      }
    }
  }

  /// The "Example Session Results" table from the assignment (section 3.2).
  static SessionResults previewResults(String sessionId) {
    final start = DateTime(2026, 9, 22, 9);
    final session = AttendanceSession(
      id: sessionId,
      classId: 'c-mp',
      mode: Modes.quiz,
      radius: 50,
      startTime: start,
      expiryTime: start.add(const Duration(minutes: 2)),
      status: 'closed',
    );
    AttendanceRecord r(String id, String status, double d, int score) => AttendanceRecord(
          sessionId: sessionId,
          studentId: id,
          classId: 'c-mp',
          status: status,
          distance: d,
          quizScore: score,
          quizSubmitted: true,
        );
    return SessionResults.build(
      session: session,
      students: const [
        StudentInfo(id: 's1', name: 'Ahmed', studentNumber: '2024001'),
        StudentInfo(id: 's2', name: 'Sara', studentNumber: '2024002'),
        StudentInfo(id: 's3', name: 'Mohamed', studentNumber: '2024003'),
        StudentInfo(id: 's4', name: 'Ali', studentNumber: '2024004'),
      ],
      records: [
        r('s1', 'present', 18, 4),
        r('s2', 'present', 31, 5),
        r('s3', 'rejected', 124, 5),
      ],
    );
  }
}
