import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_messages.dart';
import '../data/class_repository.dart';

class CreateClassState extends Equatable {
  const CreateClassState({
    required this.joinCode,
    this.isSaving = false,
    this.createdClassId,
    this.error,
  });

  /// Shown before saving (design screen 5) so the teacher can copy it right away.
  final String joinCode;
  final bool isSaving;
  final String? createdClassId;
  final String? error;

  @override
  List<Object?> get props => [joinCode, isSaving, createdClassId, error];
}

/// #5 Create Class. Name + semester, join code generated on the phone
/// (6 characters, no 0/O/1/I), saved by the teacher (firestore.rules check the role).
class CreateClassCubit extends Cubit<CreateClassState> {
  CreateClassCubit(ClassRepository classes)
      : _classes = classes,
        super(CreateClassState(joinCode: ClassRepository.generateJoinCode()));

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase.
  CreateClassCubit.preview()
      : _classes = null,
        super(const CreateClassState(joinCode: 'MP4K9X'));

  final ClassRepository? _classes;

  void newCode() {
    if (state.isSaving || state.createdClassId != null) return;
    emit(CreateClassState(joinCode: ClassRepository.generateJoinCode()));
  }

  Future<void> create({
    required String name,
    required String semester,
    required String teacherId,
  }) async {
    if (state.isSaving || state.createdClassId != null) return;
    if (name.trim().isEmpty || semester.trim().isEmpty) {
      emit(CreateClassState(joinCode: state.joinCode, error: 'Enter the class name and semester.'));
      return;
    }
    emit(CreateClassState(joinCode: state.joinCode, isSaving: true));

    final repo = _classes;
    if (repo == null) {
      emit(CreateClassState(joinCode: state.joinCode, createdClassId: 'c-preview'));
      return;
    }
    try {
      final id = await repo.createClass(
        name: name,
        semester: semester,
        teacherId: teacherId,
        joinCode: state.joinCode,
      );
      emit(CreateClassState(joinCode: state.joinCode, createdClassId: id));
    } catch (_) {
      emit(CreateClassState(
        joinCode: state.joinCode,
        error: 'Could not create the class. ${ErrorMessages.generic}',
      ));
    }
  }
}
