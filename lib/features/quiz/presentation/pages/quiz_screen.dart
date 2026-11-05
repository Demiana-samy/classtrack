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
  });

  final String? sessionId;
  final List<QuizQuestionDraft>? questions;
  final void Function(List<int> answers)? onSubmit;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  late final List<int?> _selectedAnswers;
  bool _isSubmitted = false;

  List<QuizQuestionDraft> get _questions => widget.questions ?? const [];

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int?>.filled(_questions.length, null);
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
    if (_selectedAnswers[_currentIndex] == null) {
      QuizFeedback.showError(context, AppStrings.selectAnswerToContinue);
      return;
    }

    final answers = _selectedAnswers.whereType<int>().toList();
    widget.onSubmit?.call(answers);

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
