import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #5 Create Class — owner: Member 1
class CreateClassScreen extends StatelessWidget {
  const CreateClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoScreen(
      number: 5,
      title: 'Create Class',
      owner: 'Member 1',
      detail: 'Name + semester. After create, show the join code (e.g. MP-4K9X).',
    );
  }
}
