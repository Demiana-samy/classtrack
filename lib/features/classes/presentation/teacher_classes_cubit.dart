import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/class_info.dart';
import '../data/class_repository.dart';
import '../data/mock_classes.dart';

enum TeacherClassesStatus { loading, ready, error }

class TeacherClassesState extends Equatable {
  const TeacherClassesState({
    this.status = TeacherClassesStatus.loading,
    this.classes = const [],
    this.studentCounts = const {},
    this.error,
  });

  final TeacherClassesStatus status;
  final List<ClassInfo> classes;

  /// classId -> enrolled students. Missing while still loading.
  final Map<String, int> studentCounts;
  final String? error;

  @override
  List<Object?> get props => [status, classes, studentCounts, error];
}

/// Teacher side of classes: my classes, live, with student counts (#4 Teacher Home).
class TeacherClassesCubit extends Cubit<TeacherClassesState> {
  TeacherClassesCubit(ClassRepository classes)
      : _classes = classes,
        super(const TeacherClassesState());

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  TeacherClassesCubit.preview()
      : _classes = null,
        super(const TeacherClassesState());

  final ClassRepository? _classes;
  StreamSubscription<List<ClassInfo>>? _sub;
  String _teacherId = '';

  Future<void> init(String teacherId) async {
    _teacherId = teacherId;
    final repo = _classes;
    if (repo == null) {
      emit(TeacherClassesState(
        status: TeacherClassesStatus.ready,
        classes: mockClasses
            .where((c) => c.teacherName == 'Sara')
            .map((c) => ClassInfo(id: c.id, name: c.name, semester: c.semester, joinCode: c.joinCode))
            .toList(),
        studentCounts: {for (final c in mockClasses) c.id: c.studentCount},
      ));
      return;
    }
    _listen(repo);
  }

  void retry() {
    final repo = _classes;
    if (repo == null) return;
    _sub?.cancel();
    emit(const TeacherClassesState());
    _listen(repo);
  }

  void _listen(ClassRepository repo) {
    _sub = repo.watchTeacherClassInfos(_teacherId).listen(
      (classes) async {
        if (isClosed) return;
        emit(TeacherClassesState(
          status: TeacherClassesStatus.ready,
          classes: classes,
          studentCounts: state.studentCounts,
        ));
        await _loadCounts(repo, classes);
      },
      onError: (_) {
        if (!isClosed) {
          emit(const TeacherClassesState(
            status: TeacherClassesStatus.error,
            error: 'Could not load your classes. Check your connection.',
          ));
        }
      },
    );
  }

  Future<void> _loadCounts(ClassRepository repo, List<ClassInfo> classes) async {
    try {
      final counts = await Future.wait(classes.map((c) => repo.fetchStudentCount(c.id)));
      if (isClosed) return;
      emit(TeacherClassesState(
        status: state.status,
        classes: state.classes,
        studentCounts: {for (var i = 0; i < classes.length; i++) classes[i].id: counts[i]},
      ));
    } catch (_) {
      // Counts are extra info; the list still works without them.
    }
  }

  /// Teacher Home calls this when coming back from Create Class / Class Details.
  Future<void> refreshCounts() async {
    final repo = _classes;
    if (repo != null) await _loadCounts(repo, state.classes);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
