import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnswerOptionField extends StatelessWidget {
  const AnswerOptionField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isSelected,
    required this.onSelect,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSelected;
  final VoidCallback onSelect;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.success;
    const inactiveBorderColor = AppColors.border;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onSelect,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : AppColors.muted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.success,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              onChanged: onChanged,
              validator: validator,
              style: AppTextStyles.withColor(
                AppTextStyles.cairo15W400,
                onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.withColor(
                    AppTextStyles.cairo15W400, AppColors.muted),
                filled: true,
                fillColor: AppColors.card,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isSelected ? activeColor : inactiveBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isSelected ? activeColor : inactiveBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isSelected ? activeColor : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.danger, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
