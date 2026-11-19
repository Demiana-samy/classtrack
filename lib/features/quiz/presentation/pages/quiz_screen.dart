import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/quiz_question_model.dart';
import '../../domain/entities/quiz_question.dart';
import '../widgets/quiz_completed_view.dart';
import '../widgets/quiz_feedback.dart';
import '../widgets/quiz_progress_indicator.dart';
import '../widgets/quiz_question_view.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    this.sessionId,
    this.questions,
    this.onSubmit,
    this.expiryTime,
  });

  final String? sessionId;
  final List<QuizQuestionDraft>? questions;
  final void Function(List<int> answers)? onSubmit;

  /// Session end from the server (`attendance_sessions.expiryTime`). When set,
  /// a countdown is shown and the quiz closes when time is up.
  final DateTime? expiryTime;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  late final List<int?> _selectedAnswers;
  bool _isSubmitted = false;
  Timer? _timer;
  Duration? _remaining;
  bool _timeUp = false;

  List<QuizQuestionDraft> get _questions => widget.questions ?? const [];

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int?>.filled(_questions.length, null);
    if (widget.expiryTime != null) {
      _remaining = _left();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      if (_remaining == Duration.zero) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
      }
    }
  }

  Duration _left() {
    final left = widget.expiryTime!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final remaining = _left();
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero && !_timeUp) {
      _timeUp = true;
      _timer?.cancel();
      QuizFeedback.showError(context, AppStrings.quizTimeUp);
      // In a real session, go back: Active Session shows that the session ended.
      if (widget.onSubmit != null) Navigator.of(context).maybePop();
    }
  }

  void _handleNext() {
    if (_selectedAnswers[_currentIndex] == null) {
      QuizFeedback.showError(context, AppStrings.selectAnswerToContinue);
      return;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _handleSubmit() {
    if (_timeUp) {
      QuizFeedback.showError(context, AppStrings.quizTimeUp);
      return;
    }
    if (_selectedAnswers[_currentIndex] == null) {
      QuizFeedback.showError(context, AppStrings.selectAnswerToContinue);
      return;
    }

    final answers = _selectedAnswers.whereType<int>().toList();

    // Real sessions: students never get the answer key, so the score comes
    // from submitAttendance. The caller (Active Session #13) shows Result #15.
    if (widget.onSubmit != null) {
      widget.onSubmit!(answers);
      return;
    }

    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(AppStrings.quizTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppStrings.noQuestionsAvailable,
              textAlign: TextAlign.center,
              style: AppTextStyles.withColor(
                AppTextStyles.cairo16W400,
                AppColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    if (_isSubmitted) {
      final score = QuizScorer.score(_questions, _selectedAnswers);
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(AppStrings.quizTitle),
        ),
        body: QuizCompletedView(
          score: score,
          total: _questions.length,
          onFinish: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handlePrevious,
        ),
        title: const Text(AppStrings.quizTitle),
        actions: [
          if (_remaining != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _TimerChip(remaining: _remaining!)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuizProgressIndicator(
                      currentIndex: _currentIndex,
                      totalCount: _questions.length,
                    ),
                    const SizedBox(height: 16),
                    QuizQuestionView(
                      question: currentQuestion,
                      selectedIndex: _selectedAnswers[_currentIndex],
                      onSelected: (index) {
                        setState(() {
                          _selectedAnswers[_currentIndex] = index;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label:
                    isLastQuestion ? AppStrings.submit : AppStrings.saveAndNext,
                onPressed: isLastQuestion ? _handleSubmit : _handleNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Countdown chip (design screen 14). Orange under 30 s, red under 10 s.
class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final s = remaining.inSeconds;
    final color = s <= 10
        ? AppColors.danger
        : s <= 30
            ? AppColors.warning
            : AppColors.success;
    final label =
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return Container(
      key: const Key('quiz-timer'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
