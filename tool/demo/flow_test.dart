// Renders each step of the expected ClassTrack workflow (preview cubits, no
// Firebase) plus where the user taps, for the workflow reference video.
// Run: flutter test tool/demo/flow_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/core/router/app_routes.dart';
import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/core/utils/app_strings.dart';
import 'package:classtrack/features/attendance/presentation/active_session_screen.dart';
import 'package:classtrack/features/attendance/presentation/attendance_history_screen.dart';
import 'package:classtrack/features/attendance/presentation/live_dashboard_screen.dart';
import 'package:classtrack/features/attendance/presentation/result_screen.dart';
import 'package:classtrack/features/attendance/presentation/session_results_screen.dart';
import 'package:classtrack/features/attendance/presentation/start_session_screen.dart';
import 'package:classtrack/features/auth/data/app_user.dart';
import 'package:classtrack/features/auth/data/mock_users.dart';
import 'package:classtrack/features/auth/presentation/auth_cubit.dart';
import 'package:classtrack/features/auth/presentation/login_screen.dart';
import 'package:classtrack/features/auth/presentation/splash_screen.dart';
import 'package:classtrack/features/classes/presentation/class_details_screen.dart';
import 'package:classtrack/features/classes/presentation/create_class_screen.dart';
import 'package:classtrack/features/classes/presentation/join_class_screen.dart';
import 'package:classtrack/features/classes/presentation/student_home_screen.dart';
import 'package:classtrack/features/classes/presentation/teacher_home_screen.dart';
import 'package:classtrack/features/quiz/data/mock_quiz.dart';
import 'package:classtrack/features/quiz/data/models/quiz_question_model.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_build_screen.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _root = Key('flow-root');
final _taps = <String, Map<String, double>?>{};

Future<void> _loadFonts() async {
  final cairo = FontLoader('Cairo')..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
  await cairo.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(icons.readAsBytes().then((b) => ByteData.view(b.buffer)));
  await loader.load();
}

Widget _app(Widget home, AppUser? user) => BlocProvider(
      create: (_) => AuthCubit.preview(user: user),
      child: RepaintBoundary(
        key: _root,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );

Future<void> _capture(WidgetTester t, String name, Finder? tap) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump(const Duration(seconds: 1));
  Map<String, double>? rect;
  if (tap != null) {
    final r = t.getRect(tap.first);
    rect = {'x': r.center.dx * 3, 'y': r.center.dy * 3, 'w': r.width * 3, 'h': r.height * 3};
  }
  _taps[name] = rect;
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_root));
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('tool/demo/flow/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _step(String name, Widget home, {AppUser? user, Future<void> Function(WidgetTester t)? act, Finder Function()? tap}) {
  testWidgets(name, (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    t.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(home, user));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    if (act != null) await act(t);
    await _capture(t, name, tap?.call());
  });
}

Future<void> _tapText(WidgetTester t, String text, {bool last = false}) async {
  final f = find.text(text);
  await t.tap(last ? f.last : f.first);
  await t.pump();
  await t.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(_loadFonts);
  tearDownAll(() {
    File('tool/demo/flow/taps.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(_taps));
  });

  const teacher = mockTeacherSara;
  const student = mockStudentMohamed;
  final studentQuestions = mockQuizQuestions
      .map((q) => QuizQuestionDraft(text: q.text, options: q.options, correctIndex: -1))
      .toList();
  Future<void> login(WidgetTester t, String email) async {
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), email);
    await t.enterText(fields.at(1), 'secret123');
    await t.pump();
  }

  // ---------- Teacher: create a class ----------
  _step('t01_splash', const SplashScreen(), user: teacher);
  _step('t02_login', const LoginScreen(), act: (t) => login(t, 'sara@university.edu'), tap: () => find.text('Log in'));
  _step('t03_home', const TeacherHomeScreen(), user: teacher, tap: () => find.byIcon(Icons.add));
  _step('t04_create', const CreateClassScreen(), user: teacher, act: (t) async {
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Mobile Programming');
    await t.enterText(fields.at(1), 'Fall 2026');
    await t.pump();
  }, tap: () => find.text('Copy'));
  _step('t05_create_copied', const CreateClassScreen(), user: teacher, act: (t) async {
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Mobile Programming');
    await t.enterText(fields.at(1), 'Fall 2026');
    await t.pump();
    await _tapText(t, 'Copy');
  }, tap: () => find.text('Create class'));
  _step('t06_details', const ClassDetailsScreen(classId: 'c-mp'), user: teacher, tap: () => find.text('Start session'));
  _step('t07_start', const StartSessionScreen(classId: 'c-mp'), user: teacher, tap: () => find.text('START ATTENDANCE'));
  _step('t08_live', const LiveDashboardScreen(sessionId: 'x'), user: teacher);

  // ---------- Student: join + punch in ----------
  _step('s01_login', const LoginScreen(), act: (t) => login(t, 'mohamed@university.edu'), tap: () => find.text('Log in'));
  _step('s02_home', const StudentHomeScreen(), user: student, tap: () => find.text('Join a class'));
  _step('s03_join_typed', const JoinClassScreen(), user: student, act: (t) async {
    await t.enterText(find.byKey(const Key('join-code-field')), 'MP4K9X');
    await t.pump();
  }, tap: () => find.text('Join class'));
  _step('s04_joined', const JoinClassScreen(), user: student, act: (t) async {
    await t.enterText(find.byKey(const Key('join-code-field')), 'MP4K9X');
    await t.pump();
    await _tapText(t, 'Join class');
  }, tap: () => find.text('Back to my classes'));
  _step('s05_home_live', const StudentHomeScreen(), user: student, tap: () => find.text('Open'));
  _step('s06_active', const ActiveSessionScreen(sessionId: 'x'), user: student, tap: () => find.text('PUNCH IN'));
  _step('s07_accepted', const ResultScreen(accepted: true, distance: 23, radius: 50), tap: () => find.text('Back to home'));
  _step('s08_rejected', const ResultScreen(accepted: false, reason: 'out_of_range', distance: 183, radius: 50),
      tap: () => find.text('Back to home'));

  // ---------- Teacher: live + end ----------
  _step('t09_live', const LiveDashboardScreen(sessionId: 'x'), user: teacher, tap: () => find.text('End session'));
  _step('t10_end_dialog', const LiveDashboardScreen(sessionId: 'x'), user: teacher,
      act: (t) => _tapText(t, 'End session'), tap: () => find.text('End session').last);
  _step('t11_ended', const LiveDashboardScreen(sessionId: 'x'), user: teacher, act: (t) async {
    await _tapText(t, 'End session');
    await _tapText(t, 'End session', last: true);
  }, tap: () => find.text('View results'));

  // ---------- Teacher: Mode 2 quiz ----------
  _step('q01_start', const StartSessionScreen(classId: 'c-mp'), user: teacher, tap: () => find.text('Quiz'));
  _step('q02_quiz_mode', const StartSessionScreen(classId: 'c-mp'), user: teacher,
      act: (t) => _tapText(t, 'Quiz'), tap: () => find.text('Build quiz'));
  _step('q03_builder_q1', const QuizBuildScreen(classId: 'c-mp', initialQuestions: mockQuizQuestions),
      user: teacher, tap: () => find.text(AppStrings.saveAndNext));
  _step('q04_builder_q5', const QuizBuildScreen(classId: 'c-mp', initialQuestions: mockQuizQuestions),
      user: teacher, act: (t) async {
    for (var i = 0; i < 4; i++) {
      await _tapText(t, AppStrings.saveAndNext);
    }
  }, tap: () => find.text(AppStrings.createQuiz));
  _step('q05_builder_done', const QuizBuildScreen(classId: 'c-mp', initialQuestions: mockQuizQuestions),
      user: teacher, act: (t) async {
    for (var i = 0; i < 4; i++) {
      await _tapText(t, AppStrings.saveAndNext);
    }
    await _tapText(t, AppStrings.createQuiz);
  }, tap: () => find.text(AppStrings.finish));
  _step('q06_ready', const StartSessionScreen(classId: 'c-mp', questions: mockQuizQuestions), user: teacher,
      tap: () => find.text('START QUIZ'));

  // ---------- Student: quiz ----------
  _step('q07_student_home', const StudentHomeScreen(), user: student, tap: () => find.text('Open'));
  _step('q08_active_quiz', const ActiveSessionScreen(sessionId: 'x', previewMode: Modes.quiz), user: student,
      tap: () => find.text('START QUIZ'));
  QuizScreen quiz() => QuizScreen(
        questions: studentQuestions,
        expiryTime: DateTime.now().add(const Duration(seconds: 84)),
        onSubmit: (_) {},
      );
  _step('q09_q1', quiz(), user: student, tap: () => find.text(mockQuizQuestions[0].options[0]));
  _step('q10_q1_selected', quiz(), user: student,
      act: (t) => _tapText(t, mockQuizQuestions[0].options[0]), tap: () => find.text(AppStrings.saveAndNext));
  _step('q11_q3', quiz(), user: student, act: (t) async {
    for (var i = 0; i < 2; i++) {
      await _tapText(t, mockQuizQuestions[i].options[0]);
      await _tapText(t, AppStrings.saveAndNext);
    }
    await _tapText(t, mockQuizQuestions[2].options[1]);
  }, tap: () => find.text(AppStrings.saveAndNext));
  _step('q12_q5', quiz(), user: student, act: (t) async {
    for (var i = 0; i < 4; i++) {
      await _tapText(t, mockQuizQuestions[i].options[i == 2 ? 1 : 0]);
      await _tapText(t, AppStrings.saveAndNext);
    }
    await _tapText(t, mockQuizQuestions[4].options[2]);
  }, tap: () => find.text(AppStrings.submit));
  _step('q13_result', const ResultScreen(accepted: true, distance: 18, radius: 50, score: 4),
      tap: () => find.text('Back to home'));

  // ---------- Teacher: results ----------
  _step('r01_results', const SessionResultsScreen(sessionId: 'ATT-2026-0922-001'), user: teacher,
      tap: () => find.text('Export CSV'));
  _step('r02_exported', const SessionResultsScreen(sessionId: 'ATT-2026-0922-001'), user: teacher,
      act: (t) => _tapText(t, 'Export CSV'));

  // ---------- Student: history ----------
  _step('h01_history', const AttendanceHistoryScreen(), user: student);
}
