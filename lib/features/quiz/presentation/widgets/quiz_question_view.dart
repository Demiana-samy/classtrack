import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/quiz_question.dart';
import 'quiz_answer_option_tile.dart';

class QuizQuestionView extends StatelessWidget {
  const QuizQuestionView({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelected,
  });

  final QuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            question.text,
            style: AppTextStyles.withColor(
              AppTextStyles.cairo16W500,
              onSurface,
            ).copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          QuizAnswerOptionTile(
            label: question.options[i],
            isSelected: selectedIndex == i,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}
