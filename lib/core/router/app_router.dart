import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/active_session_screen.dart';
import '../../features/attendance/presentation/attendance_history_screen.dart';
import '../../features/attendance/presentation/live_dashboard_screen.dart';
import '../../features/attendance/presentation/result_screen.dart';
import '../../features/attendance/presentation/session_results_screen.dart';
import '../../features/attendance/presentation/start_session_screen.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/classes/presentation/class_details_screen.dart';
import '../../features/classes/presentation/create_class_screen.dart';
import '../../features/classes/presentation/join_class_screen.dart';
import '../../features/classes/presentation/student_home_screen.dart';
import '../../features/classes/presentation/teacher_home_screen.dart';
import '../../features/common/design_preview/design_preview_screen.dart';
import '../../features/quiz/data/quiz_question_draft.dart';
import '../../features/quiz/presentation/quiz_builder_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import 'app_routes.dart';

export 'app_routes.dart';

/// Re-runs the router redirect whenever the auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

List<QuizQuestionDraft>? _questionsExtra(Object? extra) {
  if (extra is List<QuizQuestionDraft>) return extra;
  if (extra is List) return extra.whereType<QuizQuestionDraft>().toList();
  return null;
}

ResultScreen _resultFromState(GoRouterState s) {
  final extra = s.extra;
  if (extra is ResultArgs) {
    return ResultScreen(
      accepted: extra.accepted,
      reason: extra.reason,
      distance: extra.distance,
      radius: extra.radius,
      score: extra.score,
    );
  }
  final q = s.uri.queryParameters;
  return ResultScreen(
    accepted: q['accepted'] == 'true',
    reason: q['reason'],
    distance: double.tryParse(q['distance'] ?? ''),
    radius: int.tryParse(q['radius'] ?? ''),
    score: int.tryParse(q['score'] ?? ''),
  );
}

GoRouter buildRouter(AuthCubit auth) {
  const authPaths = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final s = auth.state;
      final loc = state.matchedLocation;

      if (kDebugMode && loc.startsWith(AppRoutes.designPreview)) return null;
      if (!kDebugMode && loc.startsWith(AppRoutes.designPreview)) {
        return s.status == AuthStatus.authenticated
            ? (s.user!.isTeacher ? AppRoutes.teacherHome : AppRoutes.studentHome)
            : AppRoutes.login;
      }

      if (s.status == AuthStatus.unknown || s.status == AuthStatus.failed) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (s.status == AuthStatus.unauthenticated) {
        return (loc == AppRoutes.login || loc == AppRoutes.register) ? null : AppRoutes.login;
      }
      final home = s.user!.isTeacher ? AppRoutes.teacherHome : AppRoutes.studentHome;
      if (authPaths.contains(loc)) return home;
      if (s.user!.isTeacher && loc.startsWith(AppRoutes.studentHome)) return home;
      if (!s.user!.isTeacher && loc.startsWith(AppRoutes.teacherHome)) return home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.designPreview,
        builder: (_, __) => const DesignPreviewScreen(),
      ),

      GoRoute(
        path: AppRoutes.teacherHome,
        builder: (_, __) => const TeacherHomeScreen(),
        routes: [
          GoRoute(
            path: 'create-class',
            builder: (_, __) => const CreateClassScreen(),
          ),
          GoRoute(
            path: 'class/:classId',
            builder: (_, s) => ClassDetailsScreen(classId: s.pathParameters['classId']!),
          ),
          GoRoute(
            path: 'start-session/:classId',
            builder: (_, s) => StartSessionScreen(
              classId: s.pathParameters['classId']!,
              questions: _questionsExtra(s.extra),
            ),
          ),
          GoRoute(
            path: 'quiz-builder/:classId',
            builder: (_, s) => QuizBuilderScreen(classId: s.pathParameters['classId']!),
          ),
          GoRoute(
            path: 'live/:sessionId',
            builder: (_, s) => LiveDashboardScreen(sessionId: s.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: 'results/:sessionId',
            builder: (_, s) => SessionResultsScreen(sessionId: s.pathParameters['sessionId']!),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.studentHome,
        builder: (_, __) => const StudentHomeScreen(),
        routes: [
          GoRoute(
            path: 'join',
            builder: (_, __) => const JoinClassScreen(),
          ),
          GoRoute(
            path: 'session/:sessionId',
            builder: (_, s) => ActiveSessionScreen(sessionId: s.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: 'quiz/:sessionId',
            builder: (_, s) => QuizScreen(sessionId: s.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: 'result',
            builder: (_, s) => _resultFromState(s),
          ),
          GoRoute(
            path: 'history',
            builder: (_, __) => const AttendanceHistoryScreen(),
          ),
        ],
      ),
    ],
  );
}
