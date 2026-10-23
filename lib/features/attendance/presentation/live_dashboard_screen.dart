import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #9 Live Dashboard — owner: Member 1
class LiveDashboardScreen extends StatelessWidget {
  const LiveDashboardScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 9,
      title: 'Live Dashboard',
      owner: 'Member 1',
      detail: 'sessionId=$sessionId. Live stream of attendance records.',
    );
  }
}
