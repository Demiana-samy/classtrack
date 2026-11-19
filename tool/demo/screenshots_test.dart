// Renders real ClassTrack screens (preview cubits, no Firebase) to PNG for the
// demo video. Run: flutter test tool/demo/screenshots_test.dart --update-goldens
import 'dart:io';
import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/core/router/app_routes.dart';
import 'package:classtrack/core/theme/app_theme.dart';
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
import 'package:classtrack/features/auth/presentation/register_screen.dart';
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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _root = Key('shot-root');

Future<void> _loadFonts() async {
  final cairo = FontLoader('Cairo')..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
  await cairo.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(icons.readAsBytes().then((b) => ByteData.view(b.buffer)));
  await loader.load();
}

Widget _app(Widget home, {AppUser? user}) => BlocProvider(
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

Future<void> _images(WidgetTester t) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump();
}

Future<void> _shot(WidgetTester t, String name) async {
  await _images(t);
  await t.pump(const Duration(seconds: 1)); // let ink splashes finish
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_root));
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('tool/demo/shots/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _case(String name, Widget home, {AppUser? user, Future<void> Function(WidgetTester t)? act}) {
  testWidgets(name, (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(home, user: user));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    if (act != null) await act(t);
    await _shot(t, name);
  });
}

void main() {
  setUpAll(_loadFonts);

  const teacher = mockTeacherSara;
  const student = mockStudentMohamed;

  _case('01_splash', const SplashScreen(), user: teacher);
  _case('02_login', const LoginScreen());
  _case('03_register', const RegisterScreen());
  _case('04_teacher_home', const TeacherHomeScreen(), user: teacher);
  _case('05_create_class', const CreateClassScreen(), user: teacher, act: (t) async {
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Mobile Programming');
    await t.enterText(fields.at(1), 'Fall 2026');
    await t.pump();
  });
  _case('06_class_details', const ClassDetailsScreen(classId: 'c-mp'), user: teacher);
  _case('07_start_punch', const StartSessionScreen(classId: 'c-mp'), user: teacher);
  _case('08_student_home', const StudentHomeScreen(), user: student);
  _case('09_active_punch', const ActiveSessionScreen(sessionId: 'x'), user: student);
  _case('10_result_ok', const ResultScreen(accepted: true, distance: 23, radius: 50));
  _case('11_result_far', const ResultScreen(accepted: false, reason: 'out_of_range', distance: 183, radius: 50));
  _case('12_live', const LiveDashboardScreen(sessionId: 'x'), user: teacher);
  _case('13_start_quiz_empty', const StartSessionScreen(classId: 'c-mp'), user: teacher, act: (t) async {
    await t.tap(find.text('Quiz'));
    await t.pump();
  });
  _case('14_quiz_builder', const QuizBuildScreen(classId: 'c-mp', initialQuestions: mockQuizQuestions),
      user: teacher);
  _case('15_start_quiz_ready', const StartSessionScreen(classId: 'c-mp', questions: mockQuizQuestions),
      user: teacher);
  _case('16_active_quiz', const ActiveSessionScreen(sessionId: 'x', previewMode: Modes.quiz), user: student);
  _case(
    '17_quiz',
    QuizScreen(
      questions: mockQuizQuestions
          .map((q) => QuizQuestionDraft(text: q.text, options: q.options, correctIndex: -1))
          .toList(),
      expiryTime: DateTime.now().add(const Duration(seconds: 49)),
      onSubmit: (_) {},
    ),
    user: student,
    act: (t) async {
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(mockQuizQuestions[i].options[0]));
        await t.pump();
        await t.tap(find.text('Save and next'));
        await t.pump(const Duration(seconds: 1));
      }
      await t.tap(find.text(mockQuizQuestions[2].options[1]));
      await t.pump();
    },
  );
  _case('18_result_score', const ResultScreen(accepted: true, distance: 18, radius: 50, score: 4));
  _case('19_session_results', const SessionResultsScreen(sessionId: 'ATT-2026-0922-001'), user: teacher);
  _case('20_join', const JoinClassScreen(), user: student, act: (t) async {
    await t.enterText(find.byKey(const Key('join-code-field')), 'MP4K9X');
    await t.pump();
    await t.tap(find.text('Join class'));
    await t.pump();
  });
  _case('21_history', const AttendanceHistoryScreen(), user: student);
}
