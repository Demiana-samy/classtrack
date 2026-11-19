import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../quiz/data/models/quiz_question_model.dart';
import 'start_session_cubit.dart';

/// #7 Start Session — owner: Leader
///
/// In quiz mode, [questions] is the list returned by Quiz Builder (#8).
/// It is sent unchanged to `SessionRepository.startSession` (`text`, `options`, `correctIndex`).
class StartSessionScreen extends StatelessWidget {
  const StartSessionScreen({
    super.key,
    required this.classId,
    this.questions,
  });

  final String classId;
  final List<QuizQuestionDraft>? questions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (sl.isRegistered<StartSessionCubit>()
          ? sl<StartSessionCubit>()
          : StartSessionCubit.preview())
        ..init(classId: classId, questions: questions),
      child: _StartSessionView(classId: classId),
    );
  }
}

class _StartSessionView extends StatelessWidget {
  const _StartSessionView({required this.classId});

  final String classId;

  Future<void> _openQuizBuilder(BuildContext context) async {
    final cubit = context.read<StartSessionCubit>();
    final result = await Navigator.of(context)
        .pushNamed(AppRoutes.quizBuilder, arguments: classId);
    if (result is List) {
      final drafts = result.whereType<QuizQuestionDraft>().toList();
      if (drafts.isNotEmpty) cubit.setQuestions(drafts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartSessionCubit, StartSessionState>(
      listenWhen: (p, c) =>
          (c.sessionId != null && p.sessionId != c.sessionId) ||
          (c.error != null && p.error != c.error),
      listener: (context, state) {
        if (state.sessionId != null) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.liveDashboard,
            arguments: state.sessionId,
          );
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.card,
              content: Text(
                state.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          );
      },
      builder: (context, state) {
        final cubit = context.read<StartSessionCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('New session')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      const _Label('Mode'),
                      _ModeSegment(mode: state.mode, onChanged: cubit.setMode),
                      const SizedBox(height: 8),
                      Text(
                        state.isQuiz
                            ? 'Students in range answer 5 questions before time runs out.'
                            : 'Students in range tap PUNCH IN once to be marked present.',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      const _Label('Radius'),
                      _RadiusCard(radius: state.radius, onChanged: cubit.setRadius),
                      if (state.isQuiz) ...[
                        const SizedBox(height: 20),
                        const _Label('Quiz'),
                        _QuizCard(
                          questions: state.questions,
                          ready: state.hasValidQuiz,
                          onBuild: () => _openQuizBuilder(context),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _LocationRow(
                        state: state,
                        onRetry: cubit.refreshLocation,
                        onOpenSettings: cubit.openLocationSettings,
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 18, color: AppColors.muted),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The session stays open for exactly 2 minutes.',
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: PrimaryButton(
                    label: state.isQuiz ? 'START QUIZ' : 'START ATTENDANCE',
                    loading: state.isStarting,
                    onPressed: state.canStart ? cubit.start : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.mode, required this.onChanged});

  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _option(label: 'Punch-In', value: Modes.punchIn, icon: Icons.touch_app_outlined),
          _option(label: 'Quiz', value: Modes.quiz, icon: Icons.quiz_outlined),
        ],
      ),
    );
  }

  Widget _option({required String label, required String value, required IconData icon}) {
    final selected = mode == value;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadiusCard extends StatelessWidget {
  const _RadiusCard({required this.radius, required this.onChanged});

  final int radius;
  final ValueChanged<int> onChanged;

  static const _min = AppConstants.minRadiusMeters;
  static const _max = AppConstants.maxRadiusMeters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$radius m',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: radius.toDouble(),
              min: _min.toDouble(),
              max: _max.toDouble(),
              divisions: (_max - _min) ~/ 5,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          const Row(
            children: [
              Text('$_min m', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              Spacer(),
              Text('$_max m', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.questions,
    required this.ready,
    required this.onBuild,
  });

  final List<QuizQuestionDraft>? questions;
  final bool ready;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ready ? AppColors.success : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.edit_note,
            color: ready ? AppColors.success : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ready
                  ? '${questions!.length} questions ready'
                  : 'No quiz yet. Add ${AppConstants.quizQuestionCount} questions.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ready ? Colors.white : AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: onBuild,
            child: Text(ready ? 'Rebuild' : 'Build quiz'),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.state,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final StartSessionState state;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    switch (state.locationStatus) {
      case LocationStatus.loading:
        return const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
            ),
            SizedBox(width: 8),
            Text('Getting your location...', style: TextStyle(color: AppColors.muted)),
          ],
        );
      case LocationStatus.ready:
        final acc = state.accuracy;
        return Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                acc == null
                    ? 'Using your location'
                    : 'Using your location (accuracy ${acc.round()} m)',
                style: const TextStyle(color: AppColors.success),
              ),
            ),
          ],
        );
      case LocationStatus.error:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.locationError ?? 'Location is not available.',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              if (state.settingsProblem != null)
                TextButton(onPressed: onOpenSettings, child: const Text('Settings')),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        );
    }
  }
}
