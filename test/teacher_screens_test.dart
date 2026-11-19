import 'package:classtrack/core/router/app_routes.dart';
import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/features/attendance/presentation/live_dashboard_cubit.dart';
import 'package:classtrack/features/attendance/presentation/live_dashboard_screen.dart';
import 'package:classtrack/features/attendance/presentation/session_results_screen.dart';
import 'package:classtrack/features/auth/data/mock_users.dart';
import 'package:classtrack/features/auth/presentation/auth_cubit.dart';
import 'package:classtrack/features/classes/presentation/class_details_screen.dart';
import 'package:classtrack/features/classes/presentation/create_class_cubit.dart';
import 'package:classtrack/features/classes/presentation/create_class_screen.dart';
import 'package:classtrack/features/classes/presentation/teacher_classes_cubit.dart';
import 'package:classtrack/features/classes/presentation/teacher_home_screen.dart';
import 'package:classtrack/features/quiz/data/mock_quiz.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_build_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// No Firebase: screens use their preview cubits because get_it is empty.

Widget _app(Widget home) => BlocProvider(
      create: (_) => AuthCubit.preview(user: mockTeacherSara),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        routes: {AppRoutes.createClass: (_) => const CreateClassScreen()},
      ),
    );

void main() {
  group('Teacher cubits (preview)', () {
    test('TeacherClassesCubit lists my classes with student counts', () async {
      final cubit = TeacherClassesCubit.preview();
      await cubit.init('t');
      expect(cubit.state.status, TeacherClassesStatus.ready);
      expect(cubit.state.classes.map((c) => c.name), contains('Mobile Programming'));
      expect(cubit.state.studentCounts['c-mp'], 28);
      await cubit.close();
    });

    test('CreateClassCubit needs name and semester', () async {
      final cubit = CreateClassCubit.preview();
      await cubit.create(name: ' ', semester: 'Fall', teacherId: 't');
      expect(cubit.state.error, isNotNull);
      await cubit.create(name: 'Networks', semester: 'Fall 2026', teacherId: 't');
      expect(cubit.state.createdClassId, isNotNull);
      await cubit.close();
    });

    test('LiveDashboardCubit counts present and can end the session', () async {
      final cubit = LiveDashboardCubit.preview();
      await cubit.init(sessionId: 'x', teacherId: 't');
      expect(cubit.state.presentCount, 2);
      expect(cubit.state.enrolledCount, 4);
      expect(cubit.state.isOpen, isTrue);
      await cubit.endSession();
      expect(cubit.state.isOpen, isFalse);
      await cubit.close();
    });
  });

  group('Teacher Home', () {
    testWidgets('shows my classes with code and students', (tester) async {
      await tester.pumpWidget(_app(const TeacherHomeScreen()));
      await tester.pump();

      expect(find.text('My classes'), findsOneWidget);
      expect(find.text('Mobile Programming'), findsOneWidget);
      expect(find.text('Code MP-4K9X'), findsOneWidget);
      expect(find.text('Fall 2026 · 28 students'), findsOneWidget);
    });
  });

  group('Create Class', () {
    testWidgets('shows the join code with Copy and validates fields', (tester) async {
      await tester.pumpWidget(_app(const CreateClassScreen()));
      await tester.pump();

      expect(find.text('New class'), findsOneWidget);
      expect(find.text('MP4K9X'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Create class'));
      await tester.pump();
      expect(find.text('Enter the class name'), findsOneWidget);
    });
  });

  group('Class Details', () {
    testWidgets('students tab, sessions tab and Start session', (tester) async {
      await tester.pumpWidget(_app(const ClassDetailsScreen(classId: 'c-mp')));
      await tester.pump();

      expect(find.text('Mobile Programming'), findsOneWidget);
      expect(find.text('Students (4)'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('2024001'), findsOneWidget);
      expect(find.text('Start session'), findsOneWidget);

      await tester.tap(find.text('Sessions (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Quiz ·'), findsOneWidget);
      expect(find.textContaining('Punch-In ·'), findsOneWidget);
    });
  });

  group('Live Dashboard', () {
    testWidgets('present count, rows and End session', (tester) async {
      await tester.pumpWidget(_app(const LiveDashboardScreen(sessionId: 'x')));
      await tester.pump();

      expect(find.text('Live session'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('/ 4 present'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('124 m'), findsOneWidget);
      expect(find.text('End session'), findsOneWidget);

      await tester.tap(find.text('End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('End session').last); // dialog confirm
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('View results'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });
  });

  group('Session Results', () {
    testWidgets('assignment example: 2 present, 1 rejected, 1 absent, by score', (tester) async {
      await tester.pumpWidget(_app(const SessionResultsScreen(sessionId: 'x')));
      await tester.pump();

      expect(find.text('Results'), findsOneWidget);
      expect(find.text('present'), findsOneWidget);
      expect(find.text('absent'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);

      final sara = tester.getTopLeft(find.text('Sara')).dy;
      final ahmed = tester.getTopLeft(find.text('Ahmed')).dy;
      final ali = tester.getTopLeft(find.text('Ali')).dy;
      expect(sara < ahmed, isTrue, reason: 'Sara 5/5 above Ahmed 4/5');
      expect(ahmed < ali, isTrue, reason: 'absent at the bottom');
    });
  });

  group('Quiz Builder', () {
    testWidgets('Rebuild fills in the previous questions', (tester) async {
      await tester.pumpWidget(_app(const QuizBuildScreen(
        classId: 'c-mp',
        initialQuestions: mockQuizQuestions,
      )));
      await tester.pump();

      expect(find.text(mockQuizQuestions.first.text), findsOneWidget);
      expect(find.text(mockQuizQuestions.first.options.first), findsOneWidget);
    });
  });
}
