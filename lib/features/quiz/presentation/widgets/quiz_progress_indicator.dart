import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';

class QuizProgressIndicator extends StatelessWidget {
  const QuizProgressIndicator({
    super.key,
    required this.currentIndex,
    this.totalCount = AppConstants.quizQuestionCount,
  });

  /// Zero-based index of the currently displayed question (0..totalCount - 1).
  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 5 small progress segments
        Row(
          children: List.generate(totalCount, (index) {
            Color segmentColor;
            if (index < currentIndex) {
              segmentColor = AppColors.success;
            } else if (index == currentIndex) {
              segmentColor = AppColors.primary;
            } else {
              segmentColor = AppColors.border;
            }

            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(
                  right: index < totalCount - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: segmentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Dynamic Question label e.g. "Question 2 of 5"
        Text(
          AppStrings.questionOf(currentIndex + 1, totalCount),
          style: AppTextStyles.withColor(AppTextStyles.cairo15W500, AppColors.muted),
        ),
      ],
    );
  }
}
