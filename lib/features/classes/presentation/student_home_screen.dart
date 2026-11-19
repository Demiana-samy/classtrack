import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../attendance/data/attendance_session.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../data/class_info.dart';
import 'student_classes_cubit.dart';

/// #11 Student Home — owner: Member 2
///
/// Live session cards (visible to every enrolled student, wherever they are),
/// my classes, and Join a class.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => (sl.isRegistered<StudentClassesCubit>()
          ? sl<StudentClassesCubit>()
          : StudentClassesCubit.preview())
        ..init(studentId),
      child: const _StudentHomeView(),
    );
  }
}

class _StudentHomeView extends StatelessWidget {
  const _StudentHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(firstName.isEmpty ? 'Hi' : 'Hi, $firstName'),
        actions: [
          IconButton(
            tooltip: 'My attendance',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.attendanceHistory),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: BlocBuilder<StudentClassesCubit, StudentClassesState>(
        builder: (context, state) {
          switch (state.status) {
            case StudentClassesStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case StudentClassesStatus.error:
              return ErrorView(
                message: state.error ?? 'Could not load your classes.',
                onRetry: context.read<StudentClassesCubit>().retry,
              );
            case StudentClassesStatus.ready:
              break;
          }

          final live = state.liveSessions;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (live.isEmpty)
                const _NoSessionCard()
              else
                for (final s in live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LiveSessionCard(
                      session: s,
                      className: state.classNameOf(s.classId),
                      remaining: s.remainingAt(state.now),
                    ),
                  ),
              const SizedBox(height: 16),
              const Text('My classes', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              if (state.classes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'You have not joined any class yet. Ask your teacher for the class code.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                )
              else
                for (final c in state.classes) _ClassCard(info: c),
              const SizedBox(height: 8),
              const _JoinButton(),
            ],
          );
        },
      ),
    );
  }
}

String _mmss(Duration d) {
  final s = d.inSeconds.clamp(0, 99 * 60);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({
    required this.session,
    required this.className,
    required this.remaining,
  });

  final AttendanceSession session;
  final String className;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).pushNamed(AppRoutes.activeSession, arguments: session.id);

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.success),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    session.isQuiz ? 'Quiz session active' : 'Session active',
                    style: const TextStyle(color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(className, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _mmss(remaining),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: open,
                    child: const Text('Open'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Open it to punch in. Your location is checked when you tap.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available, color: AppColors.muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No active session right now. It shows here as soon as your teacher starts one.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.info});

  final ClassInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryDark,
            child: Text(
              info.name.isEmpty ? '?' : info.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (info.semester.isNotEmpty)
                  Text(info.semester, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.primaryDark),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.joinClass),
      icon: const Icon(Icons.add),
      label: const Text('Join a class'),
    );
  }
}
