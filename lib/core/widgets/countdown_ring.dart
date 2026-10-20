import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular countdown. Green > 50%, orange > 20%, red below.
/// Compute [remaining] from the session expiryTime (server time), not the phone clock.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 160,
  });

  final Duration remaining;
  final Duration total;
  final double size;

  double get _fraction =>
      (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

  Color get _color {
    if (_fraction > 0.5) return AppColors.success;
    if (_fraction > 0.2) return AppColors.warning;
    return AppColors.danger;
  }

  String get _label {
    final s = remaining.inSeconds.clamp(0, 99 * 60);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(_fraction, _color),
        child: Center(
          child: Text(
            _label,
            style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color);
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
