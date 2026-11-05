import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../../data/models/quiz_question_model.dart';
import 'quiz_build_screen.dart';
import 'quiz_screen.dart';

class RoleBasedQuizScreen extends StatelessWidget {
  const RoleBasedQuizScreen({
    super.key,
    this.classId,
    this.sessionId,
    this.questions,
    this.role,
    this.onQuizCreated,
    this.onSubmit,
  });

  final String? classId;
  final String? sessionId;
  final List<QuizQuestionDraft>? questions;
  final String? role;
  final void Function(List<QuizQuestionDraft> questions)? onQuizCreated;
  final void Function(List<int> answers)? onSubmit;

  @override
  Widget build(BuildContext context) {
    if (role != null) {
      if (role == Roles.teacher) {
        return QuizBuildScreen(
          classId: classId,
          onQuizCreated: onQuizCreated,
        );
      }
      return QuizScreen(
        sessionId: sessionId,
        questions: questions,
        onSubmit: onSubmit,
      );
    }

    var isTeacher = false;
    try {
      isTeacher = context.watch<AuthCubit>().state.user?.isTeacher ?? false;
    } catch (_) {
      isTeacher = false;
    }

    if (isTeacher) {
      return QuizBuildScreen(
        classId: classId,
        onQuizCreated: onQuizCreated,
      );
    }

    return QuizScreen(
      sessionId: sessionId,
      questions: questions,
      onSubmit: onSubmit,
    );
  }
}
