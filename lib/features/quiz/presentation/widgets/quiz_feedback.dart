import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';

abstract final class QuizFeedback {
  const QuizFeedback._();

  static void showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
        content: Text(
          message,
          style: AppTextStyles.withColor(
              AppTextStyles.cairo14W400, AppColors.danger),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: Text(
          message,
          style: AppTextStyles.withColor(
              AppTextStyles.cairo14W400, AppColors.success),
        ),
      ),
    );
  }

  static Future<void> showCreatedDialog(
    BuildContext context,
    VoidCallback onFinish,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final onSurface = Theme.of(dialogContext).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppStrings.quizCreatedTitle,
            style:
                AppTextStyles.withColor(AppTextStyles.cairo20W600, onSurface),
          ),
          content: Text(
            AppStrings.quizCreatedMessage,
            style: AppTextStyles.withColor(
                AppTextStyles.cairo14W400, AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onFinish();
              },
              child: Text(
                AppStrings.finish,
                style: AppTextStyles.withColor(
                    AppTextStyles.cairo14W600, AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
