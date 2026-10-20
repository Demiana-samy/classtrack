import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/presentation/auth_cubit.dart';

/// Temporary home for both roles. Teacher/Student owners replace this with the real home screens.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.isTeacher});
  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'My classes' : 'Hi, ${user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(isTeacher ? 'Teacher home (TODO)' : 'Student home (TODO)'),
      ),
    );
  }
}
