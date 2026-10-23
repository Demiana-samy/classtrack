import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #12 Join Class — owner: Member 2
class JoinClassScreen extends StatelessWidget {
  const JoinClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoScreen(
      number: 12,
      title: 'Join Class',
      owner: 'Member 2',
      detail: 'Join by code (e.g. MP-4K9X). Show success and error states.',
    );
  }
}
