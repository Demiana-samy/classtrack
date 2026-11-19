import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/core/router/app_routes.dart';
import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/features/attendance/data/attendance_session.dart';
import 'package:classtrack/features/attendance/presentation/active_session_cubit.dart';
import 'package:classtrack/features/attendance/presentation/active_session_screen.dart';
import 'package:classtrack/features/attendance/presentation/start_session_cubit.dart';
import 'package:classtrack/features/attendance/presentation/start_session_screen.dart';
import 'package:classtrack/features/quiz/data/mock_quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// No Firebase in tests: the screens fall back to their preview cubits
// because nothing is registered in get_it.

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.dark,
      home: home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );

void main() {
  group('AttendanceSession', () {
    final start = DateTime(2026, 9, 22, 9);
    final session = AttendanceSession(
      id: 's1',
      classId: 'c1',
      mode: Modes.punchIn,
      radius: 50,
      startTime: start,
      expiryTime: start.add(const Duration(minutes: 2)),
      status: 'active',
    );

    test('open only before expiry while active', () {
      expect(session.isOpenAt(start.add(const Duration(seconds: 28))), isTrue);
      expect(session.isOpenAt(start.add(const Duration(minutes: 2))), isFalse);
    });

    test('remaining time never goes negative', () {
      expect(
        session.remainingAt(start.add(const Duration(seconds: 28))),
        const Duration(seconds: 92),
      );
      expect(session.remainingAt(start.add(const Duration(minutes: 5))), Duration.zero);
    });
  });

  group('StartSessionCubit (preview)', () {
    test('quiz mode needs a valid 5-question quiz before it can start', () async {
      final cubit = StartSessionCubit.preview();
      await cubit.init(classId: 'c-mp');
      expect(cubit.state.canStart, isTrue);

      cubit.setMode(Modes.quiz);
      expect(cubit.state.canStart, isFalse);

      cubit.setQuestions(mockQuizQuestions);
      expect(cubit.state.hasValidQuiz, isTrue);
      expect(cubit.state.canStart, isTrue);
      await cubit.close();
    });

    test('radius is clamped to the allowed range', () async {
      final cubit = StartSessionCubit.preview();
      cubit.setRadius(5);
      expect(cubit.state.radius, AppConstants.minRadiusMeters);
      cubit.setRadius(9000);
      expect(cubit.state.radius, AppConstants.maxRadiusMeters);
      await cubit.close();
    });
  });

  group('ActiveSessionCubit (preview)', () {
    test('punch in returns the server result', () async {
      final cubit = ActiveSessionCubit.preview();
      await cubit.init('session-preview');
      expect(cubit.state.isOpen, isTrue);
      await cubit.punchIn();
      expect(cubit.state.result?.accepted, isFalse);
      expect(cubit.state.result?.reason, 'out_of_range');
      await cubit.close();
    });

    test('quiz mode loads 5 questions without answers', () async {
      final cubit = ActiveSessionCubit.preview(mode: Modes.quiz);
      await cubit.init('session-preview');
      await cubit.openQuiz();
      expect(cubit.state.quizQuestions, hasLength(AppConstants.quizQuestionCount));
      expect(cubit.state.quizQuestions!.every((q) => q.correctIndex == -1), isTrue);
      expect(cubit.state.quizRequest, 1);
      await cubit.close();
    });
  });

  group('Start Session screen', () {
    testWidgets('shows mode, radius, location and start button', (tester) async {
      await tester.pumpWidget(_app(const StartSessionScreen(classId: 'c-mp')));
      await tester.pump();

      expect(find.text('New session'), findsOneWidget);
      expect(find.text('Punch-In'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('50 m'), findsOneWidget);
      expect(find.textContaining('Using your location'), findsOneWidget);
      expect(find.text('START ATTENDANCE'), findsOneWidget);
    });

    testWidgets('quiz mode asks for the quiz first', (tester) async {
      await tester.pumpWidget(_app(const StartSessionScreen(classId: 'c-mp')));
      await tester.pump();

      await tester.tap(find.text('Quiz'));
      await tester.pump();

      expect(find.text('START QUIZ'), findsOneWidget);
      expect(find.text('Build quiz'), findsOneWidget);
    });

    testWidgets('questions from Quiz Builder show as ready', (tester) async {
      await tester.pumpWidget(
        _app(const StartSessionScreen(classId: 'c-mp', questions: mockQuizQuestions)),
      );
      await tester.pump();

      expect(find.text('5 questions ready'), findsOneWidget);
      expect(find.text('START QUIZ'), findsOneWidget);
    });
  });

  group('Active Session screen', () {
    testWidgets('punch-in mode shows countdown, button and radius', (tester) async {
      await tester.pumpWidget(_app(const ActiveSessionScreen(sessionId: 'session-preview')));
      await tester.pump();

      expect(find.text('Mobile Programming'), findsOneWidget);
      expect(find.text('Session active'), findsOneWidget);
      expect(find.text('PUNCH IN'), findsOneWidget);
      expect(find.text('Radius 50 m'), findsOneWidget);
      expect(find.textContaining('01:3'), findsOneWidget);
    });

    testWidgets('punch in opens the result screen', (tester) async {
      await tester.pumpWidget(_app(const ActiveSessionScreen(sessionId: 'session-preview')));
      await tester.pump();

      await tester.tap(find.text('PUNCH IN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Not accepted'), findsOneWidget);
      expect(find.text('You are 183 m away.'), findsOneWidget);
    });

    testWidgets('quiz mode shows START QUIZ', (tester) async {
      await tester.pumpWidget(
        _app(const ActiveSessionScreen(sessionId: 'session-preview', previewMode: Modes.quiz)),
      );
      await tester.pump();

      expect(find.text('START QUIZ'), findsOneWidget);
      expect(find.text('Attendance quiz'), findsOneWidget);
    });
  });
}
