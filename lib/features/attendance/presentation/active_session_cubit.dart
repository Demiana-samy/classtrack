import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_messages.dart';
import '../../classes/data/class_repository.dart';
import '../../quiz/data/mock_quiz.dart';
import '../../quiz/data/models/quiz_question_model.dart';
import '../data/attendance_repository.dart';
import '../data/attendance_session.dart';
import '../data/location_service.dart';
import '../data/session_repository.dart';

enum ActiveSessionStatus { loading, ready, notFound, error }

class ActiveSessionState extends Equatable {
  const ActiveSessionState({
    this.status = ActiveSessionStatus.loading,
    this.session,
    this.className,
    required this.now,
    this.isSubmitting = false,
    this.isLoadingQuiz = false,
    this.message,
    this.result,
    this.quizQuestions,
    this.quizRequest = 0,
  });

  final ActiveSessionStatus status;
  final AttendanceSession? session;
  final String? className;

  /// Ticks every second so the countdown redraws. Remaining time is always
  /// `session.expiryTime - now`; expiryTime comes from the server.
  final DateTime now;
  final bool isSubmitting;
  final bool isLoadingQuiz;

  /// Inline problem shown on this screen (GPS off, network error...).
  final String? message;

  /// Answer from submitAttendance. The screen navigates to Result (#15) on it.
  final AttendanceResult? result;

  final List<QuizQuestionDraft>? quizQuestions;

  /// Increases each time the student taps START QUIZ and questions are ready.
  final int quizRequest;

  bool get isOpen => session != null && session!.isOpenAt(now);
  Duration get remaining => session?.remainingAt(now) ?? Duration.zero;
  bool get canAct => isOpen && !isSubmitting && !isLoadingQuiz;

  ActiveSessionState copyWith({
    ActiveSessionStatus? status,
    AttendanceSession? session,
    String? className,
    DateTime? now,
    bool? isSubmitting,
    bool? isLoadingQuiz,
    String? Function()? message,
    AttendanceResult? result,
    List<QuizQuestionDraft>? quizQuestions,
    int? quizRequest,
  }) {
    return ActiveSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      className: className ?? this.className,
      now: now ?? this.now,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingQuiz: isLoadingQuiz ?? this.isLoadingQuiz,
      message: message != null ? message() : this.message,
      result: result ?? this.result,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      quizRequest: quizRequest ?? this.quizRequest,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        className,
        now,
        isSubmitting,
        isLoadingQuiz,
        message,
        result,
        quizQuestions,
        quizRequest,
      ];
}

/// #13 Active Session (student). Shows the live countdown and sends the
/// punch-in or quiz answers to `submitAttendance`. The server decides.
class ActiveSessionCubit extends Cubit<ActiveSessionState> {
  ActiveSessionCubit(
    SessionRepository sessions,
    AttendanceRepository attendance,
    LocationService location,
    ClassRepository classes,
  )   : _sessions = sessions,
        _attendance = attendance,
        _location = location,
        _classes = classes,
        _previewMode = null,
        super(ActiveSessionState(now: DateTime.now()));

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase or GPS.
  ActiveSessionCubit.preview({String mode = Modes.punchIn})
      : _sessions = null,
        _attendance = null,
        _location = null,
        _classes = null,
        _previewMode = mode,
        super(ActiveSessionState(now: DateTime.now()));

  final SessionRepository? _sessions;
  final AttendanceRepository? _attendance;
  final LocationService? _location;
  final ClassRepository? _classes;
  final String? _previewMode;
  bool get _isPreview => _sessions == null;

  StreamSubscription<AttendanceSession?>? _sub;
  Timer? _ticker;
  String _sessionId = '';

  Future<void> init(String sessionId) async {
    _sessionId = sessionId;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) emit(state.copyWith(now: DateTime.now()));
    });

    if (_isPreview) {
      final now = DateTime.now();
      emit(state.copyWith(
        status: ActiveSessionStatus.ready,
        className: 'Mobile Programming',
        session: AttendanceSession(
          id: sessionId,
          classId: 'c-mp',
          mode: _previewMode!,
          radius: 50,
          startTime: now.subtract(const Duration(seconds: 28)),
          expiryTime: now.add(const Duration(seconds: 92)),
          status: 'active',
        ),
      ));
      return;
    }

    if (sessionId.isEmpty) {
      emit(state.copyWith(status: ActiveSessionStatus.notFound));
      return;
    }

    _sub = _sessions!.watchSessionModel(sessionId).listen(
      (session) async {
        if (isClosed) return;
        if (session == null) {
          emit(state.copyWith(status: ActiveSessionStatus.notFound));
          return;
        }
        final first = state.session == null;
        emit(state.copyWith(status: ActiveSessionStatus.ready, session: session));
        if (first) await _loadClassName(session.classId);
      },
      onError: (_) {
        if (!isClosed) {
          emit(state.copyWith(
            status: ActiveSessionStatus.error,
            message: () => 'Could not load this session. Check your connection.',
          ));
        }
      },
    );
  }

  Future<void> _loadClassName(String classId) async {
    try {
      final name = await _classes!.fetchClassName(classId);
      if (!isClosed && name != null) emit(state.copyWith(className: name));
    } catch (_) {
      // The header falls back to a generic title; not worth an error state.
    }
  }

  /// Mode 1: single tap.
  Future<void> punchIn() => _submit();

  /// Mode 2: load the questions (no answers inside) and ask the screen to open the quiz.
  Future<void> openQuiz() async {
    if (!state.canAct) return;
    if (state.quizQuestions != null) {
      emit(state.copyWith(quizRequest: state.quizRequest + 1));
      return;
    }
    emit(state.copyWith(isLoadingQuiz: true, message: () => null));
    try {
      final questions = _isPreview
          ? mockQuizQuestions
              .map((q) => QuizQuestionDraft(text: q.text, options: q.options, correctIndex: -1))
              .toList()
          : await _sessions!.fetchQuizQuestions(_sessionId);
      if (questions.length != AppConstants.quizQuestionCount) {
        emit(state.copyWith(
          isLoadingQuiz: false,
          message: () => 'This quiz is not ready yet. Ask your teacher.',
        ));
        return;
      }
      emit(state.copyWith(
        isLoadingQuiz: false,
        quizQuestions: questions,
        quizRequest: state.quizRequest + 1,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoadingQuiz: false,
        message: () => 'Could not load the quiz. Check your connection.',
      ));
    }
  }

  /// Mode 2: called with the 5 chosen option indexes from the Quiz screen.
  Future<void> submitQuiz(List<int> answers) => _submit(answers: answers);

  Future<void> _submit({List<int>? answers}) async {
    if (state.isSubmitting) return;
    if (!state.isOpen) {
      emit(state.copyWith(message: () => 'This session has ended.'));
      return;
    }
    emit(state.copyWith(isSubmitting: true, message: () => null));

    if (_isPreview) {
      emit(state.copyWith(
        isSubmitting: false,
        result: const AttendanceResult(
          accepted: false,
          status: 'rejected',
          reason: 'out_of_range',
          distance: 183,
          radius: 50,
        ),
      ));
      return;
    }

    try {
      final p = await _location!.currentPosition();
      final result = await _attendance!.submit(
        sessionId: _sessionId,
        latitude: p.latitude,
        longitude: p.longitude,
        answers: answers,
      );
      emit(state.copyWith(isSubmitting: false, result: result));
    } on LocationException catch (e) {
      emit(state.copyWith(isSubmitting: false, message: () => e.message));
    } on FirebaseFunctionsException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        message: () => ErrorMessages.fromFunctions(e),
      ));
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, message: () => ErrorMessages.generic));
    }
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
