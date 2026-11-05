import 'package:flutter/material.dart';

import '../../features/attendance/presentation/active_session_screen.dart';
import '../../features/attendance/presentation/attendance_history_screen.dart';
import '../../features/attendance/presentation/live_dashboard_screen.dart';
import '../../features/attendance/presentation/result_screen.dart';
import '../../features/attendance/presentation/session_results_screen.dart';
import '../../features/attendance/presentation/start_session_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/classes/presentation/class_details_screen.dart';
import '../../features/classes/presentation/create_class_screen.dart';
import '../../features/classes/presentation/join_class_screen.dart';
import '../../features/classes/presentation/student_home_screen.dart';
import '../../features/classes/presentation/teacher_home_screen.dart';
import '../../features/common/design_preview/design_preview_screen.dart';
import '../../features/quiz/data/models/quiz_question_model.dart';
import '../../features/quiz/presentation/quiz_builder_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';

/// Named routes for every screen. Navigate with [Navigator.pushNamed].
class AppRoutes {
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const designPreview = 'design-preview';

  static const teacherHome = 'teacher';
  static const createClass = 'teacher/create-class';
  static const classDetails = 'teacher/class';
  static const startSession = 'teacher/start-session';
  static const quizBuilder = 'teacher/quiz-builder';
  static const liveDashboard = 'teacher/live';
  static const sessionResults = 'teacher/results';

  static const studentHome = 'student';
  static const joinClass = 'student/join';
  static const activeSession = 'student/session';
  static const quiz = 'student/quiz';
  static const result = 'student/result';
  static const attendanceHistory = 'student/history';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    designPreview: (context) => const DesignPreviewScreen(),
    teacherHome: (context) => const TeacherHomeScreen(),
    createClass: (context) => const CreateClassScreen(),
    studentHome: (context) => const StudentHomeScreen(),
    joinClass: (context) => const JoinClassScreen(),
    attendanceHistory: (context) => const AttendanceHistoryScreen(),
  };

  /// Builds screens that need route arguments.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case classDetails:
        return _page(
          settings,
          ClassDetailsScreen(classId: _stringArg(settings.arguments) ?? ''),
        );
      case startSession:
        final args = _mapArg(settings.arguments);
        return _page(
          settings,
          StartSessionScreen(
            classId: _stringFrom(args, 'classId') ??
                _stringArg(settings.arguments) ??
                '',
            questions: _questionsArg(args?['questions']),
          ),
        );
      case quizBuilder:
        return _page(
          settings,
          QuizBuilderScreen(classId: _stringArg(settings.arguments)),
        );
      case liveDashboard:
        return _page(
          settings,
          LiveDashboardScreen(sessionId: _stringArg(settings.arguments) ?? ''),
        );
      case sessionResults:
        return _page(
          settings,
          SessionResultsScreen(sessionId: _stringArg(settings.arguments) ?? ''),
        );
      case activeSession:
        return _page(
          settings,
          ActiveSessionScreen(sessionId: _stringArg(settings.arguments) ?? ''),
        );
      case quiz:
        final args = _mapArg(settings.arguments);
        return _page(
          settings,
          QuizScreen(
            sessionId: _stringFrom(args, 'sessionId') ??
                _stringArg(settings.arguments),
            questions: _questionsArg(args?['questions']),
          ),
        );
      case result:
        return _page(settings, _resultFromArgs(settings.arguments));
      default:
        return null;
    }
  }

  static MaterialPageRoute<dynamic> _page(
      RouteSettings settings, Widget child) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }

  static String? _stringArg(Object? arguments) =>
      arguments is String ? arguments : null;

  static Map<String, dynamic>? _mapArg(Object? arguments) =>
      arguments is Map ? Map<String, dynamic>.from(arguments) : null;

  static String? _stringFrom(Map<String, dynamic>? arguments, String key) =>
      arguments?[key] as String?;

  static List<QuizQuestionDraft>? _questionsArg(Object? value) {
    if (value is List<QuizQuestionDraft>) return value;
    if (value is List) return value.whereType<QuizQuestionDraft>().toList();
    return null;
  }

  static ResultScreen _resultFromArgs(Object? arguments) {
    if (arguments is ResultArgs) {
      return ResultScreen(
        accepted: arguments.accepted,
        reason: arguments.reason,
        distance: arguments.distance,
        radius: arguments.radius,
        score: arguments.score,
      );
    }
    final map = _mapArg(arguments);
    return ResultScreen(
      accepted: map?['accepted'] == true,
      reason: map?['reason'] as String?,
      distance: _doubleFrom(map?['distance']),
      radius: _intFrom(map?['radius']),
      score: _intFrom(map?['score']),
    );
  }

  static double? _doubleFrom(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
