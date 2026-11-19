import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../classes/data/class_repository.dart';
import '../../classes/data/student_info.dart';
import '../data/attendance_record.dart';
import '../data/attendance_repository.dart';
import '../data/attendance_session.dart';
import '../data/session_repository.dart';

enum LiveStatus { loading, ready, notFound, error }

class LiveDashboardState extends Equatable {
  const LiveDashboardState({
    this.status = LiveStatus.loading,
    this.session,
    this.className,
    this.students = const [],
    this.records = const [],
    required this.now,
    this.isEnding = false,
    this.error,
  });

  final LiveStatus status;
  final AttendanceSession? session;
  final String? className;
  final List<StudentInfo> students;
  final List<AttendanceRecord> records;
  final DateTime now;
  final bool isEnding;
  final String? error;

  bool get isOpen => session != null && session!.isOpenAt(now);
  Duration get remaining => session?.remainingAt(now) ?? Duration.zero;

  int get presentCount => records.where((r) => r.status == 'present').length;
  int get enrolledCount => students.length;

  String nameOf(String studentId) {
    for (final s in students) {
      if (s.id == studentId) return s.name;
    }
    return 'Student';
  }

  /// Newest attempt first, absent rows hidden (they only appear after closing).
  List<AttendanceRecord> get attempts => records.where((r) => r.status != 'absent').toList()
    ..sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));

  LiveDashboardState copyWith({
    LiveStatus? status,
    AttendanceSession? session,
    String? className,
    List<StudentInfo>? students,
    List<AttendanceRecord>? records,
    DateTime? now,
    bool? isEnding,
    String? Function()? error,
  }) =>
      LiveDashboardState(
        status: status ?? this.status,
        session: session ?? this.session,
        className: className ?? this.className,
        students: students ?? this.students,
        records: records ?? this.records,
        now: now ?? this.now,
        isEnding: isEnding ?? this.isEnding,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props =>
      [status, session, className, students, records, now, isEnding, error];
}

/// #9 Live Dashboard: who punched in, in real time, and "End session".
class LiveDashboardCubit extends Cubit<LiveDashboardState> {
  LiveDashboardCubit(
    SessionRepository sessions,
    AttendanceRepository attendance,
    ClassRepository classes,
  )   : _sessions = sessions,
        _attendance = attendance,
        _classes = classes,
        super(LiveDashboardState(now: DateTime.now()));

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  LiveDashboardCubit.preview()
      : _sessions = null,
        _attendance = null,
        _classes = null,
        super(LiveDashboardState(now: DateTime.now()));

  final SessionRepository? _sessions;
  final AttendanceRepository? _attendance;
  final ClassRepository? _classes;

  StreamSubscription<AttendanceSession?>? _sessionSub;
  StreamSubscription<List<AttendanceRecord>>? _recordsSub;
  StreamSubscription<List<StudentInfo>>? _studentsSub;
  Timer? _ticker;
  String _sessionId = '';

  Future<void> init({required String sessionId, required String teacherId}) async {
    _sessionId = sessionId;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) emit(state.copyWith(now: DateTime.now()));
    });

    final sessions = _sessions;
    final attendance = _attendance;
    final classes = _classes;
    if (sessions == null || attendance == null || classes == null) {
      emit(_preview(sessionId));
      return;
    }
    if (sessionId.isEmpty) {
      emit(state.copyWith(status: LiveStatus.notFound));
      return;
    }

    _sessionSub = sessions.watchSessionModel(sessionId).listen(
      (s) async {
        if (isClosed) return;
        if (s == null) {
          emit(state.copyWith(status: LiveStatus.notFound));
          return;
        }
        final first = state.session == null;
        emit(state.copyWith(status: LiveStatus.ready, session: s));
        if (first) {
          _studentsSub = classes.watchClassStudents(s.classId).listen(
            (list) {
              if (!isClosed) emit(state.copyWith(students: list));
            },
            onError: (_) {},
          );
          try {
            final info = await classes.fetchClassInfo(s.classId);
            if (!isClosed && info != null) emit(state.copyWith(className: info.name));
          } catch (_) {}
        }
      },
      onError: (_) => _fail(),
    );
    _recordsSub = attendance.watchSessionRecordModels(sessionId, teacherId: teacherId).listen(
      (list) {
        if (!isClosed) emit(state.copyWith(records: list));
      },
      onError: (_) => _fail(),
    );
  }

  void _fail() {
    if (isClosed) return;
    emit(state.copyWith(
      status: LiveStatus.error,
      error: () => 'Could not load the live session. Check your connection.',
    ));
  }

  /// Closes the session now (status -> closed). Late students are then rejected
  /// with "session_expired" by submitAttendance.
  Future<void> endSession() async {
    if (state.isEnding || !state.isOpen) return;
    emit(state.copyWith(isEnding: true, error: () => null));
    final sessions = _sessions;
    if (sessions == null) {
      final s = state.session!;
      emit(state.copyWith(
        isEnding: false,
        session: AttendanceSession(
          id: s.id,
          classId: s.classId,
          mode: s.mode,
          radius: s.radius,
          startTime: s.startTime,
          expiryTime: s.expiryTime,
          status: 'closed',
        ),
      ));
      return;
    }
    try {
      await sessions.closeSession(_sessionId);
      emit(state.copyWith(isEnding: false));
    } catch (_) {
      emit(state.copyWith(isEnding: false, error: () => 'Could not end the session. Try again.'));
    }
  }

  static LiveDashboardState _preview(String sessionId) {
    final now = DateTime.now();
    AttendanceRecord r(String id, String status, double d, int secondsAgo) => AttendanceRecord(
          sessionId: sessionId,
          studentId: id,
          classId: 'c-mp',
          status: status,
          distance: d,
          timestamp: now.subtract(Duration(seconds: secondsAgo)),
        );
    return LiveDashboardState(
      status: LiveStatus.ready,
      now: now,
      className: 'Mobile Programming',
      session: AttendanceSession(
        id: sessionId,
        classId: 'c-mp',
        mode: Modes.punchIn,
        radius: 50,
        startTime: now.subtract(const Duration(seconds: 99)),
        expiryTime: now.add(const Duration(seconds: 21)),
        status: 'active',
      ),
      students: const [
        StudentInfo(id: 's1', name: 'Ahmed'),
        StudentInfo(id: 's2', name: 'Sara'),
        StudentInfo(id: 's3', name: 'Mohamed'),
        StudentInfo(id: 's4', name: 'Ali'),
      ],
      records: [
        r('s1', 'present', 18, 10),
        r('s2', 'present', 31, 30),
        r('s3', 'rejected', 124, 50),
      ],
    );
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _sessionSub?.cancel();
    await _recordsSub?.cancel();
    await _studentsSub?.cancel();
    return super.close();
  }
}
