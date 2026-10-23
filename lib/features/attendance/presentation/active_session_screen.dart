import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #13 Active Session — owner: Leader
class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 13,
      title: 'Active Session',
      owner: 'Leader',
      detail: 'sessionId=$sessionId. Countdown from expiryTime, then punch in.',
    );
  }
}
