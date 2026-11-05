import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/data/app_user.dart';

class QuizEntryHeader extends StatelessWidget {
  const QuizEntryHeader({
    super.key,
    required this.isTeacher,
    required this.user,
  });

  final bool isTeacher;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final currentUser = user;
    return Column(
      children: [
        const AppLogo(size: 72),
        const SizedBox(height: 16),
        Text(
          isTeacher ? AppStrings.teacherQuizBuilder : AppStrings.studentQuiz,
          textAlign: TextAlign.center,
          style: AppTextStyles.withColor(
            AppTextStyles.cairo22W700,
            onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          currentUser == null
              ? AppStrings.selectRolePrompt
              : AppStrings.loggedInAs(currentUser.name, currentUser.role),
          textAlign: TextAlign.center,
          style: AppTextStyles.withColor(
            AppTextStyles.cairo14W400,
            AppColors.muted,
          ),
        ),
      ],
    );
  }
}
