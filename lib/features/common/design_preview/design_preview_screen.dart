import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/register_screen.dart';
import '../../auth/presentation/splash_screen.dart';
import '../../common/home_shell.dart';
import 'mock_feature_screen.dart';
import 'preview_mocks.dart';

class PreviewEntry {
  const PreviewEntry({
    required this.id,
    required this.title,
    required this.group,
    required this.builder,
  });

  final String id;
  final String title;
  final String group;
  final WidgetBuilder builder;
}

List<PreviewEntry> previewCatalog() => [
      PreviewEntry(
        id: 'splash',
        title: 'Splash',
        group: 'Auth',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const SplashScreen(),
        ),
      ),
      PreviewEntry(
        id: 'login',
        title: 'Login',
        group: 'Auth',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const LoginScreen(),
        ),
      ),
      PreviewEntry(
        id: 'register',
        title: 'Register',
        group: 'Auth',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const RegisterScreen(),
        ),
      ),
      PreviewEntry(
        id: 'bootstrap-error',
        title: 'Bootstrap error',
        group: 'Auth',
        builder: (_) => const Scaffold(
          body: ErrorView(
            title: 'Could not start ClassTrack',
            message:
                'Firebase is not configured yet.\n\nThis is the screen users see instead of a blank view.',
          ),
        ),
      ),
      PreviewEntry(
        id: 'teacher-home',
        title: 'Teacher home',
        group: 'Classes',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(user: mockTeacher),
          child: const MockTeacherHomePreview(),
        ),
      ),
      PreviewEntry(
        id: 'create-class',
        title: 'Create class',
        group: 'Classes',
        builder: (_) => const MockCreateClassPreview(),
      ),
      PreviewEntry(
        id: 'class-details',
        title: 'Class details',
        group: 'Classes',
        builder: (_) => const MockClassDetailsPreview(),
      ),
      PreviewEntry(
        id: 'student-home',
        title: 'Student home',
        group: 'Classes',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(user: mockStudent),
          child: const MockStudentHomePreview(),
        ),
      ),
      PreviewEntry(
        id: 'join-class',
        title: 'Join class',
        group: 'Classes',
        builder: (_) => const MockJoinClassPreview(),
      ),
      PreviewEntry(
        id: 'start-session',
        title: 'Start session',
        group: 'Punch-in',
        builder: (_) => const MockStartSessionPreview(),
      ),
      PreviewEntry(
        id: 'active-session',
        title: 'Active session',
        group: 'Punch-in',
        builder: (_) => const MockActiveSessionPreview(),
      ),
      PreviewEntry(
        id: 'result-ok',
        title: 'Result (accepted)',
        group: 'Punch-in',
        builder: (_) => const MockResultPreview(accepted: true, score: 5),
      ),
      PreviewEntry(
        id: 'result-far',
        title: 'Result (out of range)',
        group: 'Punch-in',
        builder: (_) => const MockResultPreview(
          accepted: false,
          reason: 'out_of_range',
          distance: 210,
          radius: 50,
        ),
      ),
      PreviewEntry(
        id: 'quiz-builder',
        title: 'Quiz builder',
        group: 'Quiz',
        builder: (_) => const MockQuizBuilderPreview(),
      ),
      PreviewEntry(
        id: 'quiz',
        title: 'Student quiz',
        group: 'Quiz',
        builder: (_) => const MockQuizPreview(),
      ),
      PreviewEntry(
        id: 'live',
        title: 'Live dashboard',
        group: 'Management',
        builder: (_) => const MockLiveDashboardPreview(),
      ),
      PreviewEntry(
        id: 'results',
        title: 'Session results',
        group: 'Management',
        builder: (_) => const MockSessionResultsPreview(),
      ),
      PreviewEntry(
        id: 'history',
        title: 'Attendance history',
        group: 'Management',
        builder: (_) => const MockHistoryPreview(),
      ),
      PreviewEntry(
        id: 'home-shell-teacher',
        title: 'Home shell (current placeholder)',
        group: 'Management',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(user: mockTeacher),
          child: const HomeShell(isTeacher: true),
        ),
      ),
    ];

class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = previewCatalog();
    final groups = <String, List<PreviewEntry>>{};
    for (final item in items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Design Preview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Debug only. Screens open with mock data and do not call Firebase.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            for (final group in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              for (final item in group.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: item.builder),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.title, style: const TextStyle(fontSize: 16))),
                            const Icon(Icons.chevron_right, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
