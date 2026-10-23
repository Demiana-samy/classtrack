import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../common/todo_screen.dart';

/// #11 Student Home — owner: Member 2
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 11,
      title: 'Student Home',
      owner: 'Member 2',
      detail: 'Active session card + my classes + Join a class.',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => context.read<AuthCubit>().logout(),
        ),
      ],
    );
  }
}
