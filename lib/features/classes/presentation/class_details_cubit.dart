import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../attendance/data/attendance_session.dart';
import '../../attendance/data/session_repository.dart';
import '../data/class_info.dart';
import '../data/class_repository.dart';
import '../data/student_info.dart';

enum ClassDetailsStatus { loading, ready, notFound, error }

class ClassDetailsState extends Equatable {
  const ClassDetailsState({
    this.status = ClassDetailsStatus.loading,
    this.info,
    this.students = const [],
    this.sessions = const [],
    this.error,
  });

  final ClassDetailsStatus status;
  final ClassInfo? info;
  final List<StudentInfo> students;
  final List<AttendanceSession> sessions;
  final String? error;

  ClassDetailsState copyWith({
    ClassDetailsStatus? status,
    ClassInfo? info,
    List<StudentInfo>? students,
    List<AttendanceSession>? sessions,
    String? error,
  }) =>
      ClassDetailsState(
        status: status ?? this.status,
        info: info ?? this.info,
        students: students ?? this.students,
        sessions: sessions ?? this.sessions,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, info, students, sessions, error];
}

/// #6 Class Details: class info + join code, students tab, sessions tab.
class ClassDetailsCubit extends Cubit<ClassDetailsState> {
  ClassDetailsCubit(ClassRepository classes, SessionRepository sessions)
      : _classes = classes,
        _sessions = sessions,
        super(const ClassDetailsState());

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  ClassDetailsCubit.preview()
      : _classes = null,
        _sessions = null,
        super(const ClassDetailsState());

  final ClassRepository? _classes;
  final SessionRepository? _sessions;
  StreamSubscription<List<StudentInfo>>? _studentsSub;
  StreamSubscription<List<AttendanceSession>>? _sessionsSub;

  Future<void> init(String classId) async {
    final classes = _classes;
    final sessions = _sessions;
    if (classes == null || sessions == null) {
      emit(_preview(classId));
      return;
    }
    try {
      final info = await classes.fetchClassInfo(classId);
      if (isClosed) return;
      if (info == null) {
        emit(const ClassDetailsState(status: ClassDetailsStatus.notFound));
        return;
      }
      emit(state.copyWith(status: ClassDetailsStatus.ready, info: info));
    } catch (_) {
      _fail();
      return;
    }
    _studentsSub = classes.watchClassStudents(classId).listen(
      (list) {
        if (!isClosed) emit(state.copyWith(students: list));
      },
      onError: (_) => _fail(),
    );
    _sessionsSub = sessions.watchClassSessions(classId).listen(
      (list) {
        if (!isClosed) emit(state.copyWith(sessions: list));
      },
      onError: (_) => _fail(),
    );
  }

  void _fail() {
    if (isClosed) return;
    emit(state.copyWith(
      status: ClassDetailsStatus.error,
      error: 'Could not load this class. Check your connection.',
    ));
  }

  static ClassDetailsState _preview(String classId) {
    final now = DateTime.now();
    AttendanceSession s(String id, int daysAgo, String mode) => AttendanceSession(
          id: id,
          classId: classId,
          mode: mode,
          radius: 50,
          startTime: now.subtract(Duration(days: daysAgo)),
          expiryTime: now.subtract(Duration(days: daysAgo)).add(const Duration(minutes: 2)),
          status: 'closed',
        );
    return ClassDetailsState(
      status: ClassDetailsStatus.ready,
      info: ClassInfo(id: classId, name: 'Mobile Programming', semester: 'Fall 2026', joinCode: 'MP4K9X'),
      students: const [
        StudentInfo(id: 's1', name: 'Ahmed', studentNumber: '2024001'),
        StudentInfo(id: 's2', name: 'Ali', studentNumber: '2024004'),
        StudentInfo(id: 's3', name: 'Mohamed', studentNumber: '2024003'),
        StudentInfo(id: 's4', name: 'Sara', studentNumber: '2024002'),
      ],
      sessions: [s('x1', 1, Modes.quiz), s('x2', 8, Modes.punchIn)],
    );
  }

  @override
  Future<void> close() async {
    await _studentsSub?.cancel();
    await _sessionsSub?.cancel();
    return super.close();
  }
}
