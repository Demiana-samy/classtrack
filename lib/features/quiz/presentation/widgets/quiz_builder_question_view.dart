import 'package:flutter/material.dart';
import '../../../../core/utils/app_strings.dart';
import 'answer_option_field.dart';
import 'question_input_field.dart';
import 'quiz_progress_indicator.dart';

class QuizBuilderQuestionView extends StatelessWidget {
  const QuizBuilderQuestionView({
    super.key,
    required this.questionController,
    required this.optionControllers,
    required this.correctIndex,
    required this.currentIndex,
    required this.totalCount,
    required this.onSelectOption,
  });

  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final int correctIndex;
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onSelectOption;

  static const _optionLabels = [
    AppStrings.optionA,
    AppStrings.optionB,
    AppStrings.optionC,
    AppStrings.optionD,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizProgressIndicator(
          currentIndex: currentIndex,
          totalCount: totalCount,
        ),
        const SizedBox(height: 16),
        QuestionInputField(controller: questionController),
        const SizedBox(height: 16),
        for (var i = 0; i < optionControllers.length; i++)
          AnswerOptionField(
            controller: optionControllers[i],
            hintText: _optionLabels[i],
            isSelected: correctIndex == i,
            onSelect: () => onSelectOption(i),
          ),
      ],
    );
  }
}
