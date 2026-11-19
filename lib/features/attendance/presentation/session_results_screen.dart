import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../data/session_results.dart';
import 'session_results_cubit.dart';

/// #10 Session Results — owner: Member 3
///
/// Present / rejected / absent (enrolled with no record), ordered by status
/// then quiz score. Logic lives in `SessionResults` (unit tested).
class SessionResultsScreen extends StatelessWidget {
  const SessionResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => (sl.isRegistered<SessionResultsCubit>()
          ? sl<SessionResultsCubit>()
          : SessionResultsCubit.preview())
        ..load(sessionId: sessionId, teacherId: teacherId),
      child: _ResultsView(sessionId: sessionId, teacherId: teacherId),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.sessionId, required this.teacherId});

  final String sessionId;
  final String teacherId;

  static final _date = DateFormat('d MMM yyyy · HH:mm');

  Future<void> _exportCsv(BuildContext context, SessionResultsState state) async {
    final csv = state.results!.toCsv(className: state.className);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.card,
        content: Text('CSV copied. Paste it into Excel or Google Sheets.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: BlocBuilder<SessionResultsCubit, SessionResultsState>(
        builder: (context, state) {
          final cubit = context.read<SessionResultsCubit>();
          Future<void> reload() => cubit.load(sessionId: sessionId, teacherId: teacherId);
          switch (state.status) {
            case ResultsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ResultsStatus.notFound:
              return const ErrorView(
                title: 'Session not found',
                message: 'This session does not exist anymore.',
              );
            case ResultsStatus.error:
              return ErrorView(message: state.error ?? 'Could not load the results.', onRetry: reload);
            case ResultsStatus.ready:
              break;
          }

          final r = state.results!;
          final quiz = r.session.mode == Modes.quiz;
          final avg = r.averageScore;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        if (state.className.isNotEmpty)
                          Text(
                            state.className,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        Text(
                          '${_date.format(r.session.startTime)} · ${quiz ? 'Quiz' : 'Punch-In'} · ${r.session.radius} m',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Counter(value: r.present, label: 'present', color: AppColors.success),
                            const SizedBox(width: 8),
                            _Counter(value: r.rejected, label: 'rejected', color: AppColors.warning),
                            const SizedBox(width: 8),
                            _Counter(value: r.absent, label: 'absent', color: AppColors.danger),
                          ],
                        ),
                        if (quiz && avg != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Average score of present students: ${avg.toStringAsFixed(1)}/${AppConstants.quizQuestionCount}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (r.rows.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Text(
                              'No students in this class yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        else
                          for (final row in r.rows) _ResultTile(row: row, quiz: quiz),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: PrimaryButton(
                    label: 'Export CSV',
                    onPressed: r.rows.isEmpty ? null : () => _exportCsv(context, state),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label, required this.color});

  final int value;
  final String label;
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
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.row, required this.quiz});

  final ResultRow row;
  final bool quiz;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (row.status) {
      'present' => ('Present', AppColors.success),
      'rejected' => ('Rejected', AppColors.warning),
      _ => ('Absent', AppColors.danger),
    };
    final details = [
      if (row.distance != null) '${row.distance!.round()} m',
      if (quiz) row.quizSubmitted ? 'Submitted' : 'Not submitted',
      if (row.studentNumber.isNotEmpty) row.studentNumber,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (details.isNotEmpty)
                  Text(details, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          if (quiz)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                row.quizScore == null ? '—' : '${row.quizScore}/${AppConstants.quizQuestionCount}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
