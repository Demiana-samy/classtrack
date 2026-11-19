import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/core/router/app_routes.dart';
import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/features/attendance/data/attendance_record.dart';
import 'package:classtrack/features/attendance/data/attendance_session.dart';
import 'package:classtrack/features/attendance/presentation/attendance_history_cubit.dart';
import 'package:classtrack/features/attendance/presentation/attendance_history_screen.dart';
import 'package:classtrack/features/auth/data/mock_users.dart';
import 'package:classtrack/features/auth/presentation/auth_cubit.dart';
import 'package:classtrack/features/classes/presentation/join_class_cubit.dart';
import 'package:classtrack/features/classes/presentation/join_class_screen.dart';
import 'package:classtrack/features/classes/presentation/student_classes_cubit.dart';
import 'package:classtrack/features/classes/presentation/student_home_screen.dart';
import 'package:classtrack/features/quiz/data/mock_quiz.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// No Firebase: screens use their preview cubits because get_it is empty.

Widget _app(Widget home) => BlocProvider(
      create: (_) => AuthCubit.preview(user: mockStudentMohamed),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        routes: {
          AppRoutes.joinClass: (_) => const JoinClassScreen(),
          AppRoutes.attendanceHistory: (_) => const AttendanceHistoryScreen(),
        },
      ),
    );

AttendanceSession _session(String id, DateTime start, {String classId = 'c1'}) => AttendanceSession(
      id: id,
      classId: classId,
      mode: Modes.punchIn,
      radius: 50,
      startTime: start,
      expiryTime: start.add(const Duration(minutes: 2)),
      status: 'closed',
    );

void main() {
  group('JoinClassCubit', () {
    test('normalize keeps 6 uppercase letters/digits', () {
      expect(JoinClassCubit.normalize('mp-4k9x!'), 'MP4K9X');
      expect(JoinClassCubit.normalize('abcdefgh'), 'ABCDEF');
    });

    test('preview joins with the right code and fails with a wrong one', () async {
      final ok = JoinClassCubit.preview()..setCode('mp4k9x');
      await ok.join();
      expect(ok.state.status, JoinStatus.joined);
      expect(ok.state.className, 'Mobile Programming');

      final bad = JoinClassCubit.preview()..setCode('ZZZZZZ');
      await bad.join();
      expect(bad.state.status, JoinStatus.failed);
      await ok.close();
      await bad.close();
    });

    test('cannot join before 6 characters', () {
      final cubit = JoinClassCubit.preview()..setCode('MP4');
      expect(cubit.state.canJoin, isFalse);
      cubit.close();
    });
  });

  group('AttendanceHistoryCubit.buildEntries', () {
    final now = DateTime(2026, 9, 30, 12);

    test('present, rejected and absent rows, newest first', () {
      final entries = AttendanceHistoryCubit.buildEntries(
        records: const [
          AttendanceRecord(sessionId: 's1', studentId: 'u', classId: 'c1', status: 'present', distance: 18),
          AttendanceRecord(sessionId: 's2', studentId: 'u', classId: 'c1', status: 'rejected', distance: 183),
        ],
        sessions: [
          _session('s1', DateTime(2026, 9, 22, 9)),
          _session('s2', DateTime(2026, 9, 21, 9)),
          _session('s3', DateTime(2026, 9, 20, 9)),
        ],
        classNames: const {'c1': 'Mobile Programming'},
        now: now,
      );
      expect(entries.map((e) => e.status), ['present', 'rejected', 'absent']);
      expect(entries.first.className, 'Mobile Programming');
    });

    test('a running session is not absent yet', () {
      final running = AttendanceSession(
        id: 'live',
        classId: 'c1',
        mode: Modes.punchIn,
        radius: 50,
        startTime: now.subtract(const Duration(seconds: 30)),
        expiryTime: now.add(const Duration(seconds: 90)),
        status: 'active',
      );
      final entries = AttendanceHistoryCubit.buildEntries(
        records: const [],
        sessions: [running],
        classNames: const {},
        now: now,
      );
      expect(entries, isEmpty);
    });

    test('sessions before I joined the class are not absent', () {
      final entries = AttendanceHistoryCubit.buildEntries(
        records: const [],
        sessions: [_session('old', DateTime(2026, 9, 1)), _session('new', DateTime(2026, 9, 25))],
        classNames: const {},
        joinedAt: {'c1': DateTime(2026, 9, 10)},
        now: now,
      );
      expect(entries.map((e) => e.sessionId), ['new']);
    });
  });

  group('StudentClassesCubit (preview)', () {
    test('shows classes and one live session', () async {
      final cubit = StudentClassesCubit.preview();
      await cubit.init('u');
      expect(cubit.state.classes, isNotEmpty);
      expect(cubit.state.liveSessions, hasLength(1));
      expect(cubit.state.classNameOf('c-mp'), 'Mobile Programming');
      await cubit.close();
    });
  });

  group('Student Home screen', () {
    testWidgets('greets the student and shows the live session card', (tester) async {
      await tester.pumpWidget(_app(const StudentHomeScreen()));
      await tester.pump();

      expect(find.text('Hi, Mohamed'), findsOneWidget);
      expect(find.text('Session active'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('My classes'), findsOneWidget);
      expect(find.text('Databases'), findsOneWidget);
      expect(find.text('Join a class'), findsOneWidget);
    });

    testWidgets('Join a class opens the join screen', (tester) async {
      await tester.pumpWidget(_app(const StudentHomeScreen()));
      await tester.pump();
      await tester.ensureVisible(find.text('Join a class'));
      await tester.tap(find.text('Join a class'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Enter the 6-character code from your teacher'), findsOneWidget);
    });
  });

  group('Join Class screen', () {
    testWidgets('typing the code fills the boxes and joins', (tester) async {
      await tester.pumpWidget(_app(const JoinClassScreen()));
      await tester.enterText(find.byKey(const Key('join-code-field')), 'mp4k9x');
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);

      await tester.tap(find.text('Join class'));
      await tester.pump();
      expect(find.text('Joined Mobile Programming'), findsOneWidget);
    });

    testWidgets('wrong code shows an error', (tester) async {
      await tester.pumpWidget(_app(const JoinClassScreen()));
      await tester.enterText(find.byKey(const Key('join-code-field')), 'zzzzzz');
      await tester.pump();
      await tester.tap(find.text('Join class'));
      await tester.pump();

      expect(find.text('That class code is not valid.'), findsOneWidget);
    });
  });

  group('Attendance History screen', () {
    testWidgets('lists present, rejected and absent rows with counters', (tester) async {
      await tester.pumpWidget(_app(const AttendanceHistoryScreen()));
      await tester.pump();

      expect(find.text('My attendance'), findsOneWidget);
      expect(find.text('Rejected'), findsNWidgets(2)); // counter + row
      expect(find.text('22 Sep · 5/5'), findsOneWidget);
      expect(find.text('20 Sep · 183 m'), findsOneWidget);
      expect(find.text('21 Sep · Punch-In'), findsOneWidget);
    });
  });

  group('Quiz countdown', () {
    testWidgets('shows the time left from expiryTime', (tester) async {
      await tester.pumpWidget(_app(QuizScreen(
        questions: mockQuizQuestions,
        expiryTime: DateTime.now().add(const Duration(seconds: 48)),
        onSubmit: (_) {},
      )));
      await tester.pump();

      expect(find.byKey(const Key('quiz-timer')), findsOneWidget);
      expect(find.textContaining('00:4'), findsOneWidget);
    });

    testWidgets('no timer when there is no expiryTime', (tester) async {
      await tester.pumpWidget(_app(const QuizScreen(questions: mockQuizQuestions)));
      await tester.pump();
      expect(find.byKey(const Key('quiz-timer')), findsNothing);
    });
  });
}
