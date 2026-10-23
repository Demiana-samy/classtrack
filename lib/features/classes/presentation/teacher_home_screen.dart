import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../common/todo_screen.dart';

/// #4 Teacher Home — owner: Member 1
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 4,
      title: 'Teacher Home',
      owner: 'Member 1',
      detail: 'Class list + Create class. Use features/classes/data/mock_classes.dart.',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => context.read<AuthCubit>().logout(),
        ),
      ],
    );
  }
}
