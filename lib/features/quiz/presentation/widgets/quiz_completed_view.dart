import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';

class QuizCompletedView extends StatelessWidget {
  const QuizCompletedView({
    super.key,
    required this.score,
    required this.total,
    required this.onFinish,
  });

  final int score;
  final int total;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.check_circle_outline,
              size: 72,
              color: AppColors.success,
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.quizCompleted,
              style: AppTextStyles.withColor(
                AppTextStyles.cairo22W600,
                onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.quizCompletedDesc,
              textAlign: TextAlign.center,
              style: AppTextStyles.withColor(
                AppTextStyles.cairo16W400,
                AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                AppStrings.scoreOf(score, total),
                style: AppTextStyles.withColor(
                  AppTextStyles.cairo18W600,
                  AppColors.success,
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(label: AppStrings.finish, onPressed: onFinish),
          ],
        ),
      ),
    );
  }
}
