import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/quiz_question_model.dart';
import '../widgets/quiz_progress_indicator.dart';

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
        content: Text(
          message,
          style: AppTextStyles.withColor(AppTextStyles.cairo14W400, AppColors.danger),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_selectedAnswers[_currentIndex] == null) {
      _showError(AppStrings.selectAnswerToContinue);
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
      _showError(AppStrings.selectAnswerToContinue);
      return;
    }

    final answers = _selectedAnswers.whereType<int>().toList();
    widget.onSubmit?.call(answers);

    setState(() {
      _isSubmitted = true;
    });
  }

  int _calculateScore() {
    var score = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (i < _selectedAnswers.length &&
          _selectedAnswers[i] != null &&
          _selectedAnswers[i] == _questions[i].correctIndex) {
        score++;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              style: AppTextStyles.withColor(AppTextStyles.cairo16W400, AppColors.muted),
            ),
          ),
        ),
      );
    }

    if (_isSubmitted) {
      final score = _calculateScore();
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(AppStrings.quizTitle),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: AppColors.success,
                ),
                const SizedBox(height: 18),
                Text(
                  AppStrings.quizCompleted,
                  style: AppTextStyles.withColor(AppTextStyles.cairo22W600, Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.quizCompletedDesc,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.withColor(AppTextStyles.cairo16W400, AppColors.muted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    AppStrings.scoreOf(score, _questions.length),
                    style: AppTextStyles.withColor(AppTextStyles.cairo18W600, AppColors.success),
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: AppStrings.finish,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;
    final selectedOption = _selectedAnswers[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handlePrevious,
        ),
        title: const Text(AppStrings.quizTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuizProgressIndicator(
                      currentIndex: _currentIndex,
                      totalCount: _questions.length,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        currentQuestion.text,
                        style: AppTextStyles.withColor(AppTextStyles.cairo16W500, Colors.white)
                            .copyWith(height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),

                    for (var i = 0; i < currentQuestion.options.length; i++) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAnswers[_currentIndex] = i;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedOption == i
                                        ? AppColors.success
                                        : AppColors.muted,
                                    width: 2,
                                  ),
                                ),
                                child: selectedOption == i
                                    ? const Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.success,
                                        ),
                                      )
                                    : null,
                              ),

                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedOption == i
                                          ? AppColors.success
                                          : AppColors.border,
                                      width: selectedOption == i ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    currentQuestion.options[i],
                                    style: AppTextStyles.withColor(AppTextStyles.cairo15W400, Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: isLastQuestion ? AppStrings.submit : AppStrings.saveAndNext,
                onPressed: isLastQuestion ? _handleSubmit : _handleNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
