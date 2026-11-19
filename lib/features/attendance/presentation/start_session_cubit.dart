import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_messages.dart';
import '../../quiz/data/models/quiz_question_model.dart';
import '../../quiz/domain/entities/quiz_question.dart';
import '../data/location_service.dart';
import '../data/session_repository.dart';

enum LocationStatus { loading, ready, error }

class StartSessionState extends Equatable {
  const StartSessionState({
    this.mode = Modes.punchIn,
    this.radius = AppConstants.defaultRadiusMeters,
    this.questions,
    this.locationStatus = LocationStatus.loading,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationError,
    this.settingsProblem,
    this.isStarting = false,
    this.error,
    this.sessionId,
  });

  final String mode;
  final int radius;
  final List<QuizQuestionDraft>? questions;
  final LocationStatus locationStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationError;

  /// Set when GPS is off or permission is blocked; the screen offers "Open settings".
  final LocationProblem? settingsProblem;
  final bool isStarting;
  final String? error;

  /// Set once the Cloud Function created the session. The screen navigates on it.
  final String? sessionId;

  bool get isQuiz => mode == Modes.quiz;
  bool get hasValidQuiz =>
      questions != null && QuizDraftValidator.isValid(questions!);
  bool get canStart =>
      !isStarting &&
      locationStatus == LocationStatus.ready &&
      (!isQuiz || hasValidQuiz);

  StartSessionState copyWith({
    String? mode,
    int? radius,
    List<QuizQuestionDraft>? questions,
    LocationStatus? locationStatus,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? Function()? locationError,
    LocationProblem? Function()? settingsProblem,
    bool? isStarting,
    String? Function()? error,
    String? sessionId,
  }) {
    return StartSessionState(
      mode: mode ?? this.mode,
      radius: radius ?? this.radius,
      questions: questions ?? this.questions,
      locationStatus: locationStatus ?? this.locationStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      locationError: locationError != null ? locationError() : this.locationError,
      settingsProblem: settingsProblem != null ? settingsProblem() : this.settingsProblem,
      isStarting: isStarting ?? this.isStarting,
      error: error != null ? error() : this.error,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        radius,
        questions,
        locationStatus,
        latitude,
        longitude,
        accuracy,
        locationError,
        settingsProblem,
        isStarting,
        error,
        sessionId,
      ];
}

/// #7 Start Session. Teacher picks mode + radius, the app reads GPS,
/// then the `startSession` Cloud Function creates the 2-minute session.
class StartSessionCubit extends Cubit<StartSessionState> {
  StartSessionCubit(SessionRepository sessions, LocationService location)
      : _sessions = sessions,
        _location = location,
        super(const StartSessionState());

  /// In-memory cubit for Design Preview and widget tests. Never calls Firebase or GPS.
  StartSessionCubit.preview()
      : _sessions = null,
        _location = null,
        super(const StartSessionState());

  final SessionRepository? _sessions;
  final LocationService? _location;
  bool get _isPreview => _sessions == null;

  late String _classId;

  Future<void> init({
    required String classId,
    List<QuizQuestionDraft>? questions,
  }) async {
    _classId = classId;
    if (questions != null && questions.isNotEmpty) {
      emit(state.copyWith(mode: Modes.quiz, questions: questions));
    }
    await refreshLocation();
  }

  void setMode(String mode) =>
      emit(state.copyWith(mode: mode, error: () => null));

  void setRadius(int meters) => emit(
        state.copyWith(
          radius: meters.clamp(
            AppConstants.minRadiusMeters,
            AppConstants.maxRadiusMeters,
          ),
        ),
      );

  void setQuestions(List<QuizQuestionDraft> questions) =>
      emit(state.copyWith(questions: questions, error: () => null));

  Future<void> refreshLocation() async {
    emit(state.copyWith(
      locationStatus: LocationStatus.loading,
      locationError: () => null,
      settingsProblem: () => null,
    ));
    if (_isPreview) {
      emit(state.copyWith(
        locationStatus: LocationStatus.ready,
        latitude: 30.0444,
        longitude: 31.2357,
        accuracy: 8,
      ));
      return;
    }
    try {
      final p = await _location!.currentPosition();
      emit(state.copyWith(
        locationStatus: LocationStatus.ready,
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
      ));
    } on LocationException catch (e) {
      emit(state.copyWith(
        locationStatus: LocationStatus.error,
        locationError: () => e.message,
        settingsProblem: () => e.needsSettings ? e.problem : null,
      ));
    } catch (_) {
      emit(state.copyWith(
        locationStatus: LocationStatus.error,
        locationError: () => 'Could not read your location. Try again.',
      ));
    }
  }

  /// Opens system settings, then re-reads the location when the user comes back.
  Future<void> openLocationSettings() async {
    final problem = state.settingsProblem;
    if (problem == null || _isPreview) return;
    await _location!.openSettings(problem);
  }

  Future<void> start() async {
    if (state.isStarting) return;
    if (state.isQuiz && !state.hasValidQuiz) {
      emit(state.copyWith(
        error: () => 'Build the 5 quiz questions before starting.',
      ));
      return;
    }
    if (state.locationStatus != LocationStatus.ready) {
      emit(state.copyWith(error: () => 'Your location is needed to start a session.'));
      return;
    }
    emit(state.copyWith(isStarting: true, error: () => null));

    if (_isPreview) {
      emit(state.copyWith(
        isStarting: false,
        error: () => 'Preview mode: Firebase is not called.',
      ));
      return;
    }

    try {
      // Read GPS again right before starting so the session centre is fresh.
      final p = await _location!.currentPosition();
      final id = await _sessions!.startSession(
        classId: _classId,
        mode: state.mode,
        latitude: p.latitude,
        longitude: p.longitude,
        radius: state.radius,
        questions: state.isQuiz ? state.questions : null,
      );
      emit(state.copyWith(
        isStarting: false,
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        sessionId: id,
      ));
    } on LocationException catch (e) {
      emit(state.copyWith(
        isStarting: false,
        locationStatus: LocationStatus.error,
        locationError: () => e.message,
        settingsProblem: () => e.needsSettings ? e.problem : null,
        error: () => e.message,
      ));
    } on FirebaseFunctionsException catch (e) {
      emit(state.copyWith(
        isStarting: false,
        error: () => ErrorMessages.fromFunctions(e),
      ));
    } catch (_) {
      emit(state.copyWith(isStarting: false, error: () => ErrorMessages.generic));
    }
  }
}
