import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../attendance/data/attendance_session.dart';
import '../data/student_info.dart';
import 'class_details_cubit.dart';

/// #6 Class Details — owner: Member 1
class ClassDetailsScreen extends StatelessWidget {
  const ClassDetailsScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (sl.isRegistered<ClassDetailsCubit>()
          ? sl<ClassDetailsCubit>()
          : ClassDetailsCubit.preview())
        ..init(classId),
      child: _ClassDetailsView(classId: classId),
    );
  }
}

class _ClassDetailsView extends StatelessWidget {
  const _ClassDetailsView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassDetailsCubit, ClassDetailsState>(
      builder: (context, state) {
        switch (state.status) {
          case ClassDetailsStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case ClassDetailsStatus.notFound:
            return Scaffold(
              appBar: AppBar(),
              body: const ErrorView(
                title: 'Class not found',
                message: 'This class does not exist or is not yours.',
              ),
            );
          case ClassDetailsStatus.error:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(message: state.error ?? 'Could not load this class.'),
            );
          case ClassDetailsStatus.ready:
            break;
        }
        final info = state.info!;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(info.name),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(96),
                child: Column(
                  children: [
                    _CodeRow(code: info.joinCode, semester: info.semester),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.muted,
                        tabs: [
                          Tab(height: 36, text: 'Students (${state.students.length})'),
                          Tab(height: 36, text: 'Sessions (${state.sessions.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _StudentsTab(students: state.students),
                        _SessionsTab(sessions: state.sessions),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: PrimaryButton(
                      label: 'Start session',
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.startSession, arguments: classId),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code, required this.semester});

  final String code;
  final String semester;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (semester.isNotEmpty)
            Text(semester, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text('Code $code', style: const TextStyle(color: AppColors.success, letterSpacing: 1)),
          IconButton(
            tooltip: 'Copy join code',
            icon: const Icon(Icons.copy, size: 18, color: AppColors.success),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: AppColors.card, content: Text('Join code $code copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students});

  final List<StudentInfo> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _Empty(
        icon: Icons.group_outlined,
        text: 'No students yet. Share the join code so they can join.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: students.length,
      itemBuilder: (context, i) {
        final s = students[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(s.name)),
              Text(s.studentNumber, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        );
      },
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.sessions});

  final List<AttendanceSession> sessions;

  static final _date = DateFormat('d MMM · HH:mm');

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _Empty(
        icon: Icons.event_note_outlined,
        text: 'No sessions yet. Tap "Start session" in class.',
      );
    }
    final now = DateTime.now();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[i];
        final live = s.isOpenAt(now);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pushNamed(
                live ? AppRoutes.liveDashboard : AppRoutes.sessionResults,
                arguments: s.id,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      s.mode == Modes.quiz ? Icons.quiz_outlined : Icons.touch_app_outlined,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_date.format(s.startTime)),
                          Text(
                            '${s.mode == Modes.quiz ? 'Quiz' : 'Punch-In'} · ${s.radius} m',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    live
                        ? const StatusChip(label: 'Live', color: AppColors.success)
                        : const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
