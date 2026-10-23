import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/attendance_reasons.dart';

/// Extra payload for [AppRoutes.result]. Teammates pass this; do not edit the router.
class ResultArgs {
  const ResultArgs({
    required this.accepted,
    this.reason,
    this.distance,
    this.radius,
    this.score,
  });

  final bool accepted;
  final String? reason;
  final double? distance;
  final int? radius;
  final int? score;
}

/// #15 Result — owner: Leader
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.accepted,
    this.reason,
    this.distance,
    this.radius,
    this.score,
  });

  final bool accepted;
  final String? reason;
  final double? distance;
  final int? radius;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (accepted) const _AcceptedMark() else const _RejectedMark(),
              const SizedBox(height: 24),
              Text(
                accepted ? 'Accepted' : 'Not accepted',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              if (!accepted) ...[
                const SizedBox(height: 8),
                Text(
                  AttendanceReasons.message(reason),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
                ),
              ],
              if (distance != null) ...[
                const SizedBox(height: 16),
                Text(
                  AttendanceReasons.distanceLine(distance!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              if (radius != null) ...[
                const SizedBox(height: 6),
                Text(
                  AttendanceReasons.radiusLine(radius!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              ],
              if (accepted && score != null) ...[
                const SizedBox(height: 20),
                Text(
                  '$score/${AppConstants.quizQuestionCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Back to home',
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    router.go(AppRoutes.studentHome);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectedMark extends StatelessWidget {
  const _RejectedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.danger, width: 2),
      ),
      child: const Icon(Icons.close, size: 56, color: AppColors.danger),
    );
  }
}

class _AcceptedMark extends StatefulWidget {
  const _AcceptedMark();

  @override
  State<_AcceptedMark> createState() => _AcceptedMarkState();
}

class _AcceptedMarkState extends State<_AcceptedMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.check, size: 56, color: AppColors.success),
        ),
      ),
    );
  }
}
