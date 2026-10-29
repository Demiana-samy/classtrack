import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/quiz_question_draft.dart';
import '../widgets/answer_option_field.dart';
import '../widgets/question_input_field.dart';
import '../widgets/quiz_progress_indicator.dart';

class _QuestionDraftState {
  _QuestionDraftState()
      : questionController = TextEditingController(),
        optionControllers = List.generate(
          QuizDraftValidator.optionCount,
          (_) => TextEditingController(),
        ),
        correctIndex = -1;

  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  int correctIndex;

  void dispose() {
    questionController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }

  QuizQuestionDraft toDraft() => QuizQuestionDraft(
        text: questionController.text.trim(),
        options: optionControllers.map((c) => c.text.trim()).toList(),
        correctIndex: correctIndex,
      );
}

class QuizBuildScreen extends StatefulWidget {
  const QuizBuildScreen({
    super.key,
    this.classId,
    this.onQuizCreated,
  });

  final String? classId;
  final void Function(List<QuizQuestionDraft> questions)? onQuizCreated;

  @override
  State<QuizBuildScreen> createState() => _QuizBuildScreenState();
}

class _QuizBuildScreenState extends State<QuizBuildScreen> {
  static const int _totalQuestions = AppConstants.quizQuestionCount;

  late final List<_QuestionDraftState> _questions;
  int _currentIndex = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _questions = List.generate(_totalQuestions, (_) => _QuestionDraftState());
  }

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentQuestion() {
    final current = _questions[_currentIndex];
    final questionText = current.questionController.text.trim();

    if (questionText.isEmpty) {
      _showError(AppStrings.emptyQuestionError);
      return false;
    }

    for (var i = 0; i < current.optionControllers.length; i++) {
      if (current.optionControllers[i].text.trim().isEmpty) {
        _showError(AppStrings.emptyOptionError);
        return false;
      }
    }

    if (current.correctIndex < 0 || current.correctIndex >= current.optionControllers.length) {
      _showError(AppStrings.noCorrectOptionError);
      return false;
    }

    return true;
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
    if (!_validateCurrentQuestion()) return;

    if (_currentIndex < _totalQuestions - 1) {
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

  void _handleCreateQuiz() {
    if (!_validateCurrentQuestion()) return;

    final drafts = _questions.map((q) => q.toDraft()).toList();
    final validationErrors = QuizDraftValidator.validate(drafts);

    if (validationErrors.isNotEmpty) {
      _showError(validationErrors.first);
      return;
    }

    // Local UI confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: Text(
          AppStrings.quizCreatedSuccess,
          style: AppTextStyles.withColor(AppTextStyles.cairo14W400, AppColors.success),
        ),
      ),
    );

    widget.onQuizCreated?.call(drafts);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.quizCreatedTitle,
          style: AppTextStyles.withColor(AppTextStyles.cairo20W600, Colors.white),
        ),
        content: Text(
          AppStrings.quizCreatedMessage,
          style: AppTextStyles.withColor(AppTextStyles.cairo14W400, AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(drafts);
            },
            child: Text(
              AppStrings.finish,
              style: AppTextStyles.withColor(AppTextStyles.cairo14W600, AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _totalQuestions - 1;

    final optionLabels = [
      AppStrings.optionA,
      AppStrings.optionB,
      AppStrings.optionC,
      AppStrings.optionD,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handlePrevious,
        ),
        title: const Text(AppStrings.quizBuilderTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator with 5 segments and dynamic question label
                      QuizProgressIndicator(
                        currentIndex: _currentIndex,
                        totalCount: _totalQuestions,
                      ),
                      const SizedBox(height: 16),

                      // Question input field
                      QuestionInputField(
                        controller: currentQuestion.questionController,
                      ),
                      const SizedBox(height: 16),

                      // Four answer options
                      for (var i = 0; i < QuizDraftValidator.optionCount; i++)
                        AnswerOptionField(
                          controller: currentQuestion.optionControllers[i],
                          hintText: optionLabels[i],
                          isSelected: currentQuestion.correctIndex == i,
                          onSelect: () {
                            setState(() {
                              currentQuestion.correctIndex = i;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom action button: "Save and next" or "Create Quiz"
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PrimaryButton(
                  label: isLastQuestion ? AppStrings.createQuiz : AppStrings.saveAndNext,
                  onPressed: isLastQuestion ? _handleCreateQuiz : _handleNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
