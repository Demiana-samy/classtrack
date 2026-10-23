import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #10 Session Results — owner: Member 3
class SessionResultsScreen extends StatelessWidget {
  const SessionResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 10,
      title: 'Session Results',
      owner: 'Member 3',
      detail:
          'sessionId=$sessionId. Present / rejected / absent '
          '(enrolled minus present).',
    );
  }
}
