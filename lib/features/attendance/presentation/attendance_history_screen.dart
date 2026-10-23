import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #16 Attendance History — owner: Member 2
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoScreen(
      number: 16,
      title: 'Attendance History',
      owner: 'Member 2',
      detail: 'Student records: class, date, status, score/distance.',
    );
  }
}
