import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/core/utils/app_strings.dart';
import 'package:classtrack/features/quiz/data/mock_quiz.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_build_screen.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_screen.dart';
import 'package:classtrack/features/quiz/presentation/pages/role_based_quiz_screen.dart';
import 'package:classtrack/features/auth/data/mock_users.dart';
import 'package:classtrack/features/auth/presentation/auth_cubit.dart';
import 'package:classtrack/features/quiz/presentation/pages/quiz_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {AuthCubit? auth}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: auth != null ? BlocProvider.value(value: auth, child: child) : child,
  );
}

void main() {
  group('RoleBasedQuizScreen', () {
    testWidgets('displays QuizBuildScreen when role is teacher',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoleBasedQuizScreen(
            role: Roles.teacher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.quizBuilderTitle), findsOneWidget);
      expect(find.text('Question 1 of 5'), findsOneWidget);
    });

    testWidgets('displays QuizScreen when role is student', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoleBasedQuizScreen(
            role: Roles.student,
            questions: mockQuizQuestions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.quizTitle), findsOneWidget);
      expect(find.text('Question 1 of 5'), findsOneWidget);
    });
  });

  group('Teacher QuizBuildScreen', () {
    testWidgets('validates empty inputs and preserves data across navigation',
        (tester) async {
      await tester.pumpWidget(_wrap(const QuizBuildScreen()));
      await tester.pumpAndSettle();

      // Starts at Question 1 of 5
      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.text(AppStrings.saveAndNext), findsOneWidget);

      // Attempt to proceed without entering question -> validation error
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pump();
      expect(find.text(AppStrings.emptyQuestionError), findsOneWidget);

      // Fill Question 1 text
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5)); // 1 question + 4 options

      await tester.enterText(textFields.at(0), 'What is Flutter?');
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pump();
      expect(find.text(AppStrings.emptyOptionError), findsOneWidget);

      // Fill all 4 options
      await tester.enterText(textFields.at(1), 'A framework');
      await tester.enterText(textFields.at(2), 'A database');
      await tester.enterText(textFields.at(3), 'An OS');
      await tester.enterText(textFields.at(4), 'A browser');

      // Attempt without selecting correct option
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pump();
      expect(find.text(AppStrings.noCorrectOptionError), findsOneWidget);

      // Select Option A (first option circle)
      final selectionCircles = find.byType(GestureDetector);
      await tester.tap(selectionCircles.at(0));
      await tester.pump();

      // Now "Save and next" succeeds and moves to Question 2
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pumpAndSettle();
      expect(find.text('Question 2 of 5'), findsOneWidget);

      // Back navigation returns to Question 1 and preserves all entries
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.text('What is Flutter?'), findsOneWidget);
      expect(find.text('A framework'), findsOneWidget);
      expect(find.text('A database'), findsOneWidget);
      expect(find.text('An OS'), findsOneWidget);
      expect(find.text('A browser'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets(
        'shows Create Quiz on Question 5 and handles completion locally',
        (tester) async {
      await tester.pumpWidget(_wrap(const QuizBuildScreen()));
      await tester.pumpAndSettle();

      // Fill all 5 questions
      for (var q = 0; q < 5; q++) {
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Question ${q + 1}');
        await tester.enterText(textFields.at(1), 'Opt A');
        await tester.enterText(textFields.at(2), 'Opt B');
        await tester.enterText(textFields.at(3), 'Opt C');
        await tester.enterText(textFields.at(4), 'Opt D');

        // Select first option
        final selectionCircles = find.byType(GestureDetector);
        await tester.tap(selectionCircles.at(0));
        await tester.pump();

        if (q < 4) {
          await tester.tap(find.text(AppStrings.saveAndNext));
          await tester.pumpAndSettle();
        }
      }

      // On Question 5
      expect(find.text('Question 5 of 5'), findsOneWidget);
      expect(find.text(AppStrings.createQuiz), findsOneWidget);

      // Tap Create Quiz
      await tester.tap(find.text(AppStrings.createQuiz));
      await tester.pumpAndSettle();

      // Shows local confirmation dialog
      expect(find.text(AppStrings.quizCreatedTitle), findsOneWidget);
      expect(find.text(AppStrings.quizCreatedMessage), findsOneWidget);
      expect(find.text(AppStrings.finish), findsOneWidget);
    });
  });

  group('Student QuizScreen', () {
    testWidgets('shows empty state when no questions provided', (tester) async {
      await tester.pumpWidget(_wrap(const QuizScreen()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noQuestionsAvailable), findsOneWidget);
    });

    testWidgets('allows answering questions and shows local score upon submit',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QuizScreen(
            questions: mockQuizQuestions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.text('What does GPS stand for?'), findsOneWidget);

      // Tap next without selecting answer -> error
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pump();
      expect(find.text(AppStrings.selectAnswerToContinue), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(QuizScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();

      // Select 'Global Positioning System'
      await tester.tap(find.text('Global Positioning System'));
      await tester.pumpAndSettle();

      // Proceed to question 2
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pumpAndSettle();
      expect(find.text('Question 2 of 5'), findsOneWidget);

      // Go back to question 1 -> selection is preserved
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Advance through remaining questions
      await tester.tap(find.text(AppStrings.saveAndNext));
      await tester.pumpAndSettle();

      for (var q = 1; q < 5; q++) {
        // Select first option for each
        final firstOptionText = mockQuizQuestions[q].options[0];
        await tester.tap(find.text(firstOptionText));
        await tester.pump();

        if (q < 4) {
          await tester.tap(find.text(AppStrings.saveAndNext));
          await tester.pumpAndSettle();
        }
      }

      // On Question 5
      expect(find.text('Question 5 of 5'), findsOneWidget);
      expect(find.text(AppStrings.submit), findsOneWidget);

      // Submit
      await tester.tap(find.text(AppStrings.submit));
      await tester.pumpAndSettle();

      // Shows local completion state
      expect(find.text(AppStrings.quizCompleted), findsOneWidget);
      expect(find.text(AppStrings.quizCompletedDesc), findsOneWidget);
      expect(find.textContaining('Score:'), findsOneWidget);
      expect(find.text(AppStrings.finish), findsOneWidget);
    });
  });

  group('QuizEntryScreen', () {
    testWidgets(
        'teacher user sees Teacher Quiz Builder and continues with Class ID',
        (tester) async {
      final auth = AuthCubit.preview(user: mockTeacherSara);
      await tester.pumpWidget(_wrap(const QuizEntryScreen(), auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Quiz Builder'), findsOneWidget);
      expect(find.text('Logged in as Sara (teacher)'), findsOneWidget);
      expect(find.text('Class ID'), findsOneWidget);

      // Tap continue without entering ID -> validation error
      await tester.tap(find.text('Open Quiz Builder'));
      await tester.pump();
      expect(find.text('Please enter a valid Class ID'), findsOneWidget);

      // Enter Class ID and continue
      await tester.enterText(find.byType(TextFormField), 'CS101');
      await tester.tap(find.text('Open Quiz Builder'));
      await tester.pumpAndSettle();

      // Navigated to QuizBuilderScreen
      expect(find.text(AppStrings.quizBuilderTitle), findsOneWidget);
      expect(find.text('Question 1 of 5'), findsOneWidget);
    });

    testWidgets('student user sees Student Quiz and continues with Session ID',
        (tester) async {
      final auth = AuthCubit.preview(user: mockStudentMohamed);
      await tester.pumpWidget(_wrap(const QuizEntryScreen(), auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Student Quiz'), findsOneWidget);
      expect(find.text('Logged in as Mohamed (student)'), findsOneWidget);
      expect(find.text('Session ID'), findsOneWidget);

      // Tap continue without entering ID -> validation error
      await tester.tap(find.text('Take Quiz'));
      await tester.pump();
      expect(find.text('Please enter a valid Session ID'), findsOneWidget);

      // Enter Session ID and continue
      await tester.enterText(find.byType(TextFormField), 'session-abc');
      await tester.tap(find.text('Take Quiz'));
      await tester.pumpAndSettle();

      // Navigated to QuizScreen
      expect(find.text(AppStrings.quizTitle), findsOneWidget);
    });

    testWidgets('unauthenticated user sees role toggle and can choose role',
        (tester) async {
      final auth = AuthCubit.preview();
      await tester.pumpWidget(_wrap(const QuizEntryScreen(), auth: auth));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Quiz Builder'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Select role and enter ID to continue'), findsOneWidget);

      // Switch to Student
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      expect(find.text('Student Quiz'), findsOneWidget);
      expect(find.text('Session ID'), findsOneWidget);
    });
  });
}
