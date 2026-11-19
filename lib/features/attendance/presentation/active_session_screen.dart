import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/countdown_ring.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../quiz/presentation/pages/quiz_screen.dart';
import 'active_session_cubit.dart';
import 'result_screen.dart';

/// #13 Active Session — owner: Leader
///
/// Every enrolled student can open this, wherever they are (assignment section 4).
/// Only the server decides if the punch-in / quiz is accepted.
class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key, required this.sessionId, this.previewMode});

  final String sessionId;

  /// Design Preview only: `Modes.punchIn` or `Modes.quiz`. Ignored when Firebase is set up.
  final String? previewMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (sl.isRegistered<ActiveSessionCubit>()
          ? sl<ActiveSessionCubit>()
          : ActiveSessionCubit.preview(mode: previewMode ?? Modes.punchIn))
        ..init(sessionId),
      child: const _ActiveSessionView(),
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView();

  void _goHome(BuildContext context) => Navigator.of(context)
      .pushNamedAndRemoveUntil(AppRoutes.studentHome, (route) => false);

  Future<void> _openQuiz(BuildContext context, ActiveSessionState state) async {
    final cubit = context.read<ActiveSessionCubit>();
    final answers = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (quizContext) => QuizScreen(
          sessionId: state.session?.id,
          questions: state.quizQuestions,
          expiryTime: state.session?.expiryTime,
          onSubmit: (answers) => Navigator.of(quizContext).pop(answers),
        ),
      ),
    );
    if (answers != null && answers.length == AppConstants.quizQuestionCount) {
      await cubit.submitQuiz(answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveSessionCubit, ActiveSessionState>(
      listenWhen: (p, c) =>
          (c.result != null && p.result != c.result) ||
          p.quizRequest != c.quizRequest,
      listener: (context, state) {
        final r = state.result;
        if (r != null) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.result,
            arguments: ResultArgs(
              accepted: r.accepted,
              reason: r.reason,
              distance: r.distance,
              radius: r.radius?.toInt(),
              score: r.quizScore,
            ),
          );
          return;
        }
        _openQuiz(context, state);
      },
      builder: (context, state) {
        final cubit = context.read<ActiveSessionCubit>();
        switch (state.status) {
          case ActiveSessionStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case ActiveSessionStatus.notFound:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                title: 'Session not found',
                message: 'This attendance session does not exist anymore.',
                retryLabel: 'Back to home',
                onRetry: () => _goHome(context),
              ),
            );
          case ActiveSessionStatus.error:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                message: state.message ?? 'Could not load this session.',
                retryLabel: 'Back to home',
                onRetry: () => _goHome(context),
              ),
            );
          case ActiveSessionStatus.ready:
            break;
        }

        final session = state.session!;
        final total = session.expiryTime.difference(session.startTime);
        final open = state.isOpen;

        return Scaffold(
          appBar: AppBar(title: Text(state.className ?? 'Attendance session')),
          body: SafeArea(
            // Scrolls on small phones; Spacers still center content on tall ones.
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 24),
                  child: IntrinsicHeight(
                    child: Column(
                children: [
                  open
                      ? const StatusChip(label: 'Session active', color: AppColors.success)
                      : const StatusChip(label: 'Session ended', color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text(
                    session.isQuiz ? 'Attendance quiz' : 'Location punch-in',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const Spacer(),
                  CountdownRing(
                    remaining: state.remaining,
                    total: total > Duration.zero
                        ? total
                        : const Duration(seconds: AppConstants.sessionDurationSeconds),
                    size: 170,
                  ),
                  const SizedBox(height: 32),
                  _ActionButton(
                    label: session.isQuiz ? 'START QUIZ' : 'PUNCH IN',
                    icon: session.isQuiz ? Icons.quiz_outlined : Icons.location_on,
                    busy: state.isSubmitting || state.isLoadingQuiz,
                    onTap: state.canAct
                        ? (session.isQuiz ? cubit.openQuiz : cubit.punchIn)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    !open
                        ? 'Time is up for this session.'
                        : session.isQuiz
                            ? 'Answer all ${AppConstants.quizQuestionCount} questions before time runs out.'
                            : 'Tap once. Your location is checked by the server.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (state.message != null) ...[
                    const SizedBox(height: 12),
                    _MessageCard(
                      message: state.message!,
                      onOpenSettings: state.settingsProblem != null
                          ? cubit.openLocationSettings
                          : null,
                    ),
                  ],
                  const Spacer(),
                  _InfoCard(radius: session.radius),
                  if (!open) ...[
                    const SizedBox(height: 12),
                    PrimaryButton(label: 'Back to home', onPressed: () => _goHome(context)),
                  ],
                ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Big round button from the design (screen 13).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.primaryDark : AppColors.border,
            width: 2,
          ),
        ),
        child: Material(
          color: enabled ? AppColors.primary : AppColors.card,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onTap,
            child: SizedBox(
              width: 132,
              height: 132,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 34, color: enabled ? Colors.white : AppColors.muted),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: enabled ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.radius});

  final int radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.success),
          const SizedBox(width: 10),
          Text('Radius $radius m', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onOpenSettings});

  final String message;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.danger)),
          ),
          if (onOpenSettings != null)
            TextButton(onPressed: onOpenSettings, child: const Text('Open settings')),
        ],
      ),
    );
  }
}
