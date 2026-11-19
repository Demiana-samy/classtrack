import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'attendance_history_cubit.dart';

/// #16 Attendance History — owner: Member 2
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => (sl.isRegistered<AttendanceHistoryCubit>()
          ? sl<AttendanceHistoryCubit>()
          : AttendanceHistoryCubit.preview())
        ..load(studentId),
      child: _HistoryView(studentId: studentId),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My attendance')),
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          final cubit = context.read<AttendanceHistoryCubit>();
          switch (state.status) {
            case HistoryStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case HistoryStatus.error:
              return ErrorView(
                message: state.error ?? 'Could not load your attendance.',
                onRetry: () => cubit.load(studentId),
              );
            case HistoryStatus.ready:
              break;
          }

          return RefreshIndicator(
            onRefresh: () => cubit.load(studentId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    _Counter(label: 'Present', value: state.count('present'), color: AppColors.success),
                    const SizedBox(width: 8),
                    _Counter(label: 'Rejected', value: state.count('rejected'), color: AppColors.danger),
                    const SizedBox(width: 8),
                    _Counter(label: 'Absent', value: state.count('absent'), color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No sessions yet. Your attendance shows here after each session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  )
                else
                  for (final e in state.entries) _EntryCard(entry: e),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
            ),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final HistoryEntry entry;

  static final _date = DateFormat('d MMM');

  (String, Color) get _status => switch (entry.status) {
        'present' => ('Present', AppColors.success),
        'rejected' => ('Rejected', AppColors.danger),
        _ => ('Absent', AppColors.muted),
      };

  String get _detail {
    final parts = <String>[_date.format(entry.date)];
    if (entry.mode == Modes.quiz && entry.quizScore != null) {
      parts.add('${entry.quizScore}/${AppConstants.quizQuestionCount}');
    } else if (entry.status == 'rejected' && entry.distance != null) {
      parts.add('${entry.distance!.round()} m');
    } else if (entry.status != 'absent') {
      parts.add(entry.mode == Modes.quiz ? 'Quiz' : 'Punch-In');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.className, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_detail, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
