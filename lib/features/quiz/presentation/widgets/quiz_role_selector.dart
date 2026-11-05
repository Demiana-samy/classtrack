import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';

class QuizRoleSelector extends StatelessWidget {
  const QuizRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: Roles.teacher,
          label: Text(AppStrings.teacher),
          icon: Icon(Icons.school),
        ),
        ButtonSegment(
          value: Roles.student,
          label: Text(AppStrings.student),
          icon: Icon(Icons.person),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.card,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: onSurface,
      ),
    );
  }
}
