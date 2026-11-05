import 'package:flutter/material.dart';
import 'pages/quiz_build_screen.dart';

export 'pages/quiz_build_screen.dart';

/// #8 Quiz Builder
///
/// Compatibility wrapper delegating to [QuizBuildScreen].
class QuizBuilderScreen extends StatelessWidget {
  const QuizBuilderScreen({super.key, this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) {
    return QuizBuildScreen(classId: classId);
  }
}
