import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #6 Class Details — owner: Member 1
class ClassDetailsScreen extends StatelessWidget {
  const ClassDetailsScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 6,
      title: 'Class Details',
      owner: 'Member 1',
      detail: 'classId=$classId. Students + sessions tabs. Start session from here.',
    );
  }
}
