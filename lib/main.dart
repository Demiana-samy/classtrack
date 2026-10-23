import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/error/error_messages.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_logo.dart';
import 'core/widgets/error_view.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/common/design_preview/design_preview_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    setupDi();
    final auth = sl<AuthCubit>()..start();
    runApp(ClassTrackApp(auth: auth));
  } catch (e) {
    runApp(BootstrapErrorApp(message: ErrorMessages.bootstrap(e)));
  }
}

class ClassTrackApp extends StatelessWidget {
  ClassTrackApp({super.key, required this.auth}) : _router = buildRouter(auth);

  final AuthCubit auth;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: auth,
      child: MaterialApp.router(
        title: 'ClassTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}

/// Shown when Firebase cannot start. Never leaves the user on a blank screen.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 48),
            const AppLogo(size: 72),
            Expanded(
              child: ErrorView(
                title: 'Could not start ClassTrack',
                message: message,
              ),
            ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: TextButton(
                  onPressed: () {
                    runApp(const DesignPreviewApp());
                  },
                  child: const Text('Open Design Preview'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Standalone preview shell used when Firebase init failed (debug only).
class DesignPreviewApp extends StatelessWidget {
  const DesignPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/design-preview',
      routes: [
        GoRoute(path: AppRoutes.designPreview, builder: (_, __) => const DesignPreviewScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      ],
    );
    return BlocProvider(
      create: (_) => AuthCubit.preview(),
      child: MaterialApp.router(
        title: 'ClassTrack Design Preview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
