import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Placeholder body for screens that are not built yet.
/// Replace the contents of your screen file; do not edit `app_router.dart`.
class TodoScreen extends StatelessWidget {
  const TodoScreen({
    super.key,
    required this.number,
    required this.title,
    required this.owner,
    this.detail,
    this.actions,
  });

  final int number;
  final String title;
  final String owner;
  final String? detail;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$number  $title'),
        actions: actions,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                'TODO: #$number $title',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(owner, style: const TextStyle(color: AppColors.muted)),
              if (detail != null) ...[
                const SizedBox(height: 12),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
