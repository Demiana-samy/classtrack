import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/error/error_messages.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_logo.dart';
import 'core/widgets/error_view.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    setupDi();
    final auth = sl<AuthCubit>()..start();
    runApp(ClassTrackApp(auth: auth));
  } catch (e) {
    runApp(BootstrapErrorApp(message: ErrorMessages.bootstrap(e)));
  }
}

class ClassTrackApp extends StatefulWidget {
  const ClassTrackApp({super.key, required this.auth});

  final AuthCubit auth;

  @override
  State<ClassTrackApp> createState() => _ClassTrackAppState();
}

class _ClassTrackAppState extends State<ClassTrackApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) syncAuthRoute(widget.auth.state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.auth,
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.user != current.user,
        listener: (context, state) => syncAuthRoute(state),
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'ClassTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
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
    return BlocProvider(
      create: (_) => AuthCubit.preview(),
      child: MaterialApp(
        title: 'ClassTrack Design Preview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.designPreview,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
