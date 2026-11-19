import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../data/attendance_record.dart';
import 'live_dashboard_cubit.dart';

/// #9 Live Dashboard — owner: Member 1
class LiveDashboardScreen extends StatelessWidget {
  const LiveDashboardScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => (sl.isRegistered<LiveDashboardCubit>()
          ? sl<LiveDashboardCubit>()
          : LiveDashboardCubit.preview())
        ..init(sessionId: sessionId, teacherId: teacherId),
      child: _LiveView(sessionId: sessionId),
    );
  }
}

class _LiveView extends StatelessWidget {
  const _LiveView({required this.sessionId});

  final String sessionId;

  void _results(BuildContext context) => Navigator.of(context)
      .pushReplacementNamed(AppRoutes.sessionResults, arguments: sessionId);

  Future<void> _confirmEnd(BuildContext context) async {
    final cubit = context.read<LiveDashboardCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('End session now?'),
        content: const Text(
          'Students who have not punched in yet will be marked absent.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End session', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.endSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiveDashboardCubit, LiveDashboardState>(
      listenWhen: (p, c) => c.error != null && p.error != c.error && c.status == LiveStatus.ready,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          content: Text(state.error!, style: const TextStyle(color: AppColors.danger)),
        ),
      ),
      builder: (context, state) {
        switch (state.status) {
          case LiveStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case LiveStatus.notFound:
            return Scaffold(
              appBar: AppBar(),
              body: const ErrorView(
                title: 'Session not found',
                message: 'This session does not exist anymore.',
              ),
            );
          case LiveStatus.error:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(message: state.error ?? 'Could not load the live session.'),
            );
          case LiveStatus.ready:
            break;
        }

        final session = state.session!;
        final open = state.isOpen;
        final total = state.enrolledCount;
        final present = state.presentCount;
        final attempts = state.attempts;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live session'),
                if (state.className != null)
                  Text(
                    '${state.className} · ${session.isQuiz ? 'Quiz' : 'Punch-In'} · ${session.radius} m',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _TimerChip(remaining: state.remaining, open: open)),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _PresentCard(present: present, total: total),
                ),
                if (!open)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: AppColors.muted, size: 18),
                        SizedBox(width: 8),
                        Text('Session ended. No more punch-ins.', style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                Expanded(
                  child: attempts.isEmpty
                      ? const Center(
                          child: Text(
                            'Waiting for students to punch in...',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: attempts.length,
                          itemBuilder: (context, i) => _AttemptRow(
                            record: attempts[i],
                            name: state.nameOf(attempts[i].studentId),
                            radius: session.radius,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: open
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: state.isEnding ? null : () => _confirmEnd(context),
                          child: state.isEnding
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Text('End session'),
                        )
                      : PrimaryButton(label: 'View results', onPressed: () => _results(context)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.remaining, required this.open});

  final Duration remaining;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final s = remaining.inSeconds;
    final color = !open
        ? AppColors.muted
        : s <= 30
            ? AppColors.danger
            : AppColors.success;
    final label = open
        ? '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}'
        : 'Ended';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PresentCard extends StatelessWidget {
  const _PresentCard({required this.present, required this.total});

  final int present;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (present / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$present', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ $total present', style: const TextStyle(color: AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.record, required this.name, required this.radius});

  final AttendanceRecord record;
  final String name;
  final int radius;

  @override
  Widget build(BuildContext context) {
    final ok = record.status == 'present';
    final color = ok ? AppColors.success : AppColors.danger;
    final details = [
      if (record.distance != null) '${record.distance!.round()} m',
      if (record.quizScore != null) '${record.quizScore}/${AppConstants.quizQuestionCount}',
    ].join(' · ');
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
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  ok ? 'Present' : 'Rejected (outside $radius m)',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(details, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
