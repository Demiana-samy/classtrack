import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../attendance/data/mock_attendance.dart';
import '../../attendance/presentation/active_session_screen.dart';
import '../../attendance/presentation/attendance_history_screen.dart';
import '../../attendance/presentation/live_dashboard_screen.dart';
import '../../attendance/presentation/result_screen.dart';
import '../../attendance/presentation/session_results_screen.dart';
import '../../attendance/presentation/start_session_screen.dart';
import '../../auth/data/mock_users.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/register_screen.dart';
import '../../auth/presentation/splash_screen.dart';
import '../../classes/presentation/class_details_screen.dart';
import '../../classes/presentation/create_class_screen.dart';
import '../../classes/presentation/join_class_screen.dart';
import '../../classes/presentation/student_home_screen.dart';
import '../../classes/presentation/teacher_home_screen.dart';
import '../../quiz/data/mock_quiz.dart';
import '../../quiz/presentation/quiz_builder_screen.dart';
import '../../quiz/presentation/quiz_screen.dart';

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
        id: '1-splash',
        title: '1 Splash',
        group: 'Leader',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const SplashScreen(),
        ),
      ),
      PreviewEntry(
        id: '2-login',
        title: '2 Login',
        group: 'Leader',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const LoginScreen(),
        ),
      ),
      PreviewEntry(
        id: '3-register',
        title: '3 Register',
        group: 'Leader',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(),
          child: const RegisterScreen(),
        ),
      ),
      PreviewEntry(
        id: '7-start-session',
        title: '7 Start Session',
        group: 'Leader',
        builder: (_) => const StartSessionScreen(
          classId: 'c-mp',
          questions: mockQuizQuestions,
        ),
      ),
      PreviewEntry(
        id: '13-active-session',
        title: '13 Active Session',
        group: 'Leader',
        builder: (_) => const ActiveSessionScreen(sessionId: 'session-preview'),
      ),
      PreviewEntry(
        id: '15-result-ok',
        title: '15 Result (accepted)',
        group: 'Leader',
        builder: (_) => const ResultScreen(
          accepted: true,
          distance: 12.4,
          radius: mockAllowedRadius,
          score: 4,
        ),
      ),
      PreviewEntry(
        id: '15-result-far',
        title: '15 Result (rejected)',
        group: 'Leader',
        builder: (_) => const ResultScreen(
          accepted: false,
          reason: 'out_of_range',
          distance: mockRejectedDistance,
          radius: mockAllowedRadius,
        ),
      ),
      PreviewEntry(
        id: '4-teacher-home',
        title: '4 Teacher Home',
        group: 'Member 1',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(user: mockTeacherSara),
          child: const TeacherHomeScreen(),
        ),
      ),
      PreviewEntry(
        id: '5-create-class',
        title: '5 Create Class',
        group: 'Member 1',
        builder: (_) => const CreateClassScreen(),
      ),
      PreviewEntry(
        id: '6-class-details',
        title: '6 Class Details',
        group: 'Member 1',
        builder: (_) => const ClassDetailsScreen(classId: 'c-mp'),
      ),
      PreviewEntry(
        id: '9-live',
        title: '9 Live Dashboard',
        group: 'Member 1',
        builder: (_) => const LiveDashboardScreen(sessionId: 'session-preview'),
      ),
      PreviewEntry(
        id: '11-student-home',
        title: '11 Student Home',
        group: 'Member 2',
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit.preview(user: mockStudentMohamed),
          child: const StudentHomeScreen(),
        ),
      ),
      PreviewEntry(
        id: '12-join-class',
        title: '12 Join Class',
        group: 'Member 2',
        builder: (_) => const JoinClassScreen(),
      ),
      PreviewEntry(
        id: '14-quiz',
        title: '14 Quiz',
        group: 'Member 2',
        builder: (_) => const QuizScreen(sessionId: 'session-preview'),
      ),
      PreviewEntry(
        id: '16-history',
        title: '16 Attendance History',
        group: 'Member 2',
        builder: (_) => const AttendanceHistoryScreen(),
      ),
      PreviewEntry(
        id: '8-quiz-builder',
        title: '8 Quiz Builder',
        group: 'Member 3',
        builder: (_) => const QuizBuilderScreen(classId: 'c-mp'),
      ),
      PreviewEntry(
        id: '10-results',
        title: '10 Session Results',
        group: 'Member 3',
        builder: (_) => const SessionResultsScreen(sessionId: 'session-preview'),
      ),
      PreviewEntry(
        id: 'bootstrap-error',
        title: 'Bootstrap error',
        group: 'System',
        builder: (_) => const Scaffold(
          body: ErrorView(
            title: 'Could not start ClassTrack',
            message:
                'Firebase is not configured yet.\n\nThis is the screen users see instead of a blank view.',
          ),
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
                            Expanded(
                              child: Text(item.title, style: const TextStyle(fontSize: 16)),
                            ),
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
