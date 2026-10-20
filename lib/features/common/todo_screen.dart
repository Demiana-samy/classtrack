import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Placeholder for screens that are not built yet.
/// Replace the route in app_router.dart with the real screen when you implement it.
class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key, required this.title, required this.owner});
  final String title;
  final String owner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('TODO: $title', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(owner, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
