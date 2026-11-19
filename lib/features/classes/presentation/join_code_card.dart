import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Join code with a Copy button (design screen 5). Used on Create Class and Class Details.
class JoinCodeCard extends StatelessWidget {
  const JoinCodeCard({super.key, required this.code, this.onRefresh});

  final String code;

  /// Create Class only: pick another random code before saving.
  final VoidCallback? onRefresh;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(backgroundColor: AppColors.card, content: Text('Join code $code copied')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text('Join code', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            code,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: 6),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.success),
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              if (onRefresh != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('New code'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
