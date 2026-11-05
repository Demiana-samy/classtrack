import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/quiz_question_model.dart';
import '../../domain/entities/quiz_question.dart';
import '../widgets/quiz_builder_question_view.dart';
import '../widgets/quiz_feedback.dart';

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
    for (final controller in optionControllers) {
      controller.dispose();
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

  @override
  void initState() {
    super.initState();
    _questions = List.generate(_totalQuestions, (_) => _QuestionDraftState());
  }

  @override
  void dispose() {
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentQuestion() {
    final current = _questions[_currentIndex];
    final questionText = current.questionController.text.trim();

    if (questionText.isEmpty) {
      QuizFeedback.showError(context, AppStrings.emptyQuestionError);
      return false;
    }

    for (final controller in current.optionControllers) {
      if (controller.text.trim().isEmpty) {
        QuizFeedback.showError(context, AppStrings.emptyOptionError);
        return false;
      }
    }

    if (current.correctIndex < 0 ||
        current.correctIndex >= current.optionControllers.length) {
      QuizFeedback.showError(context, AppStrings.noCorrectOptionError);
      return false;
    }

    return true;
  }

  void _handleNext() {
    if (!_validateCurrentQuestion()) {
      return;
    }

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
    if (!_validateCurrentQuestion()) {
      return;
    }

    final drafts = _questions.map((question) => question.toDraft()).toList();
    final validationErrors = QuizDraftValidator.validate(drafts);

    if (validationErrors.isNotEmpty) {
      QuizFeedback.showError(context, validationErrors.first);
      return;
    }

    QuizFeedback.showSuccess(context, AppStrings.quizCreatedSuccess);
    widget.onQuizCreated?.call(drafts);
    QuizFeedback.showCreatedDialog(
      context,
      () => Navigator.of(context).pop(drafts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _totalQuestions - 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handlePrevious,
        ),
        title: const Text(AppStrings.quizBuilderTitle),
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
                child: QuizBuilderQuestionView(
                  questionController: currentQuestion.questionController,
                  optionControllers: currentQuestion.optionControllers,
                  correctIndex: currentQuestion.correctIndex,
                  currentIndex: _currentIndex,
                  totalCount: _totalQuestions,
                  onSelectOption: (index) {
                    setState(() {
                      currentQuestion.correctIndex = index;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: isLastQuestion
                    ? AppStrings.createQuiz
                    : AppStrings.saveAndNext,
                onPressed: isLastQuestion ? _handleCreateQuiz : _handleNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef QuizBuilderScreen = QuizBuildScreen;
