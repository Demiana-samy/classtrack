import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_messages.dart';
import '../data/class_repository.dart';

enum JoinStatus { editing, joining, joined, failed }

class JoinClassState extends Equatable {
  const JoinClassState({
    this.code = '',
    this.status = JoinStatus.editing,
    this.className,
    this.alreadyJoined = false,
    this.error,
  });

  static const codeLength = 6;

  final String code;
  final JoinStatus status;
  final String? className;
  final bool alreadyJoined;
  final String? error;

  bool get isComplete => code.length == codeLength;
  bool get canJoin => isComplete && status != JoinStatus.joining && status != JoinStatus.joined;

  @override
  List<Object?> get props => [code, status, className, alreadyJoined, error];
}

/// #12 Join Class. The code is checked by the `joinClass` Cloud Function.
class JoinClassCubit extends Cubit<JoinClassState> {
  JoinClassCubit(ClassRepository classes)
      : _classes = classes,
        super(const JoinClassState());

  /// In-memory cubit for Design Preview and widget tests: `MP4K9X` is the valid code.
  JoinClassCubit.preview()
      : _classes = null,
        super(const JoinClassState());

  final ClassRepository? _classes;

  static const previewCode = 'MP4K9X';

  /// Keeps letters and digits only, uppercase, max 6.
  static String normalize(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return cleaned.length > JoinClassState.codeLength
        ? cleaned.substring(0, JoinClassState.codeLength)
        : cleaned;
  }

  void setCode(String raw) {
    if (state.status == JoinStatus.joining || state.status == JoinStatus.joined) return;
    emit(JoinClassState(code: normalize(raw)));
  }

  Future<void> join() async {
    if (!state.canJoin) return;
    final code = state.code;
    emit(JoinClassState(code: code, status: JoinStatus.joining));

    if (_classes == null) {
      emit(code == previewCode
          ? JoinClassState(code: code, status: JoinStatus.joined, className: 'Mobile Programming')
          : JoinClassState(
              code: code,
              status: JoinStatus.failed,
              error: 'That class code is not valid.',
            ));
      return;
    }

    try {
      final r = await _classes.joinByCode(code);
      emit(JoinClassState(
        code: code,
        status: JoinStatus.joined,
        className: r.className,
        alreadyJoined: r.alreadyJoined,
      ));
    } on FirebaseFunctionsException catch (e) {
      emit(JoinClassState(
        code: code,
        status: JoinStatus.failed,
        error: ErrorMessages.fromFunctions(e),
      ));
    } catch (_) {
      emit(JoinClassState(code: code, status: JoinStatus.failed, error: ErrorMessages.generic));
    }
  }
}
