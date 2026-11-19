import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../attendance/data/attendance_session.dart';
import '../../attendance/data/session_repository.dart';
import '../data/class_info.dart';
import '../data/class_repository.dart';
import '../data/mock_classes.dart';

enum StudentClassesStatus { loading, ready, error }

class StudentClassesState extends Equatable {
  const StudentClassesState({
    this.status = StudentClassesStatus.loading,
    this.classes = const [],
    this.sessions = const [],
    required this.now,
    this.error,
  });

  final StudentClassesStatus status;
  final List<ClassInfo> classes;

  /// Every session the server marks active for my classes. Use [liveSessions]
  /// in the UI: it also drops sessions whose expiryTime has passed.
  final List<AttendanceSession> sessions;
  final DateTime now;
  final String? error;

  /// Assignment section 4: every enrolled student sees active sessions,
  /// wherever they are. Location is only checked when they punch in.
  List<AttendanceSession> get liveSessions =>
      sessions.where((s) => s.isOpenAt(now)).toList()
        ..sort((a, b) => a.expiryTime.compareTo(b.expiryTime));

  String classNameOf(String classId) {
    for (final c in classes) {
      if (c.id == classId) return c.name;
    }
    return 'Class';
  }

  StudentClassesState copyWith({
    StudentClassesStatus? status,
    List<ClassInfo>? classes,
    List<AttendanceSession>? sessions,
    DateTime? now,
    String? Function()? error,
  }) {
    return StudentClassesState(
      status: status ?? this.status,
      classes: classes ?? this.classes,
      sessions: sessions ?? this.sessions,
      now: now ?? this.now,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [status, classes, sessions, now, error];
}

/// Student side of classes: my enrolled classes + their live sessions (#11 Student Home).
class StudentClassesCubit extends Cubit<StudentClassesState> {
  StudentClassesCubit(ClassRepository classes, SessionRepository sessions)
      : _classes = classes,
        _sessions = sessions,
        previewWithSession = false,
        super(StudentClassesState(now: DateTime.now()));

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  StudentClassesCubit.preview({this.previewWithSession = true})
      : _classes = null,
        _sessions = null,
        super(StudentClassesState(now: DateTime.now()));

  final ClassRepository? _classes;
  final SessionRepository? _sessions;
  /// Preview only: show one live session card.
  final bool previewWithSession;
  bool get _isPreview => _classes == null;

  StreamSubscription<List<String>>? _idsSub;
  StreamSubscription<List<AttendanceSession>>? _sessionsSub;
  Timer? _ticker;
  final Map<String, ClassInfo> _infoCache = {};
  String _studentId = '';

  Future<void> init(String studentId) async {
    _studentId = studentId;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) emit(state.copyWith(now: DateTime.now()));
    });

    if (_isPreview) {
      final now = DateTime.now();
      emit(state.copyWith(
        status: StudentClassesStatus.ready,
        classes: mockClasses
            .map((c) => ClassInfo(id: c.id, name: c.name, semester: c.semester))
            .toList(),
        sessions: previewWithSession
            ? [
                AttendanceSession(
                  id: 'session-preview',
                  classId: 'c-mp',
                  mode: Modes.punchIn,
                  radius: 50,
                  startTime: now.subtract(const Duration(seconds: 28)),
                  expiryTime: now.add(const Duration(seconds: 92)),
                  status: 'active',
                ),
              ]
            : const [],
      ));
      return;
    }
    _listen();
  }

  /// Re-subscribes after an error ("Try again").
  void retry() {
    _idsSub?.cancel();
    _sessionsSub?.cancel();
    emit(state.copyWith(status: StudentClassesStatus.loading, error: () => null));
    _listen();
  }

  void _listen() {
    _idsSub = _classes!.watchStudentClassIds(_studentId).listen(
      _onClassIds,
      onError: (_) => _fail('Could not load your classes. Check your connection.'),
    );
  }

  Future<void> _onClassIds(List<String> ids) async {
    try {
      final infos = await Future.wait(ids.map(_info));
      if (isClosed) return;
      emit(state.copyWith(
        status: StudentClassesStatus.ready,
        classes: infos.whereType<ClassInfo>().toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        error: () => null,
      ));
    } catch (_) {
      _fail('Could not load your classes. Check your connection.');
      return;
    }

    await _sessionsSub?.cancel();
    _sessionsSub = _sessions!.watchActiveSessionModels(ids).listen(
      (sessions) {
        if (!isClosed) emit(state.copyWith(sessions: sessions));
      },
      onError: (_) => _fail('Could not load active sessions. Check your connection.'),
    );
  }

  Future<ClassInfo?> _info(String classId) async {
    final cached = _infoCache[classId];
    if (cached != null) return cached;
    final info = await _classes!.fetchClassInfo(classId);
    if (info != null) _infoCache[classId] = info;
    return info;
  }

  void _fail(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: StudentClassesStatus.error, error: () => message));
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _idsSub?.cancel();
    await _sessionsSub?.cancel();
    return super.close();
  }
}
