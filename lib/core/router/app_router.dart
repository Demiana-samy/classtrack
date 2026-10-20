import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/common/design_preview/design_preview_screen.dart';
import '../../features/common/home_shell.dart';
import '../../features/common/todo_screen.dart';

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

GoRouter buildRouter(AuthCubit auth) {
  const authPaths = {'/splash', '/login', '/register'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final s = auth.state;
      final loc = state.matchedLocation;

      if (kDebugMode && loc.startsWith('/design-preview')) return null;
      if (!kDebugMode && loc.startsWith('/design-preview')) {
        return s.status == AuthStatus.authenticated
            ? (s.user!.isTeacher ? '/teacher' : '/student')
            : '/login';
      }

      if (s.status == AuthStatus.unknown || s.status == AuthStatus.failed) {
        return loc == '/splash' ? null : '/splash';
      }
      if (s.status == AuthStatus.unauthenticated) {
        return (loc == '/login' || loc == '/register') ? null : '/login';
      }
      final home = s.user!.isTeacher ? '/teacher' : '/student';
      if (authPaths.contains(loc)) return home;
      if (s.user!.isTeacher && loc.startsWith('/student')) return home;
      if (!s.user!.isTeacher && loc.startsWith('/teacher')) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/design-preview',
        builder: (_, __) => const DesignPreviewScreen(),
      ),

      // ---------------- Teacher ----------------
      GoRoute(
        path: '/teacher',
        builder: (_, __) => const HomeShell(isTeacher: true), // TODO Member 2
        routes: [
          GoRoute(
            path: 'create-class',
            builder: (_, __) => const TodoScreen(title: 'Create class', owner: 'Member 2'),
          ),
          GoRoute(
            path: 'class/:classId',
            builder: (_, s) => TodoScreen(
                title: 'Class details (${s.pathParameters['classId']})', owner: 'Member 2'),
          ),
          GoRoute(
            path: 'start-session/:classId',
            builder: (_, __) => const TodoScreen(title: 'Start session', owner: 'Member 3'),
          ),
          GoRoute(
            path: 'quiz-builder/:classId',
            builder: (_, __) => const TodoScreen(title: 'Quiz builder', owner: 'Member 4'),
          ),
          GoRoute(
            path: 'live/:sessionId',
            builder: (_, __) => const TodoScreen(title: 'Live dashboard', owner: 'Member 5'),
          ),
          GoRoute(
            path: 'results/:sessionId',
            builder: (_, __) => const TodoScreen(title: 'Session results', owner: 'Member 5'),
          ),
        ],
      ),

      // ---------------- Student ----------------
      GoRoute(
        path: '/student',
        builder: (_, __) => const HomeShell(isTeacher: false), // TODO Member 2
        routes: [
          GoRoute(
            path: 'join',
            builder: (_, __) => const TodoScreen(title: 'Join class', owner: 'Member 2'),
          ),
          GoRoute(
            path: 'session/:sessionId',
            builder: (_, __) => const TodoScreen(title: 'Active session', owner: 'Member 3'),
          ),
          GoRoute(
            path: 'quiz/:sessionId',
            builder: (_, __) => const TodoScreen(title: 'Quiz', owner: 'Member 4'),
          ),
          GoRoute(
            path: 'result',
            builder: (_, __) => const TodoScreen(title: 'Result', owner: 'Member 3'),
          ),
          GoRoute(
            path: 'history',
            builder: (_, __) => const TodoScreen(title: 'Attendance history', owner: 'Member 5'),
          ),
        ],
      ),
    ],
  );
}
