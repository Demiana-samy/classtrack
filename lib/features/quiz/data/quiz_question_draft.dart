import '../../../core/constants/app_constants.dart';

/// Teacher-authored quiz question. Payload matches `startSession` in functions/index.js:
/// `{ text, options[4], correctIndex }`.
class QuizQuestionDraft {
  const QuizQuestionDraft({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String text;
  final List<String> options;
  final int correctIndex;

  Map<String, dynamic> toMap() => {
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
      };
}

/// Quiz Builder (#8) must return exactly 5 valid [QuizQuestionDraft] items.
class QuizDraftValidator {
  static const questionCount = AppConstants.quizQuestionCount;
  static const optionCount = 4;

  static bool isValid(List<QuizQuestionDraft> questions) => validate(questions).isEmpty;

  static List<String> validate(List<QuizQuestionDraft> questions) {
    final errors = <String>[];
    if (questions.length != questionCount) {
      errors.add('Quiz needs exactly $questionCount questions');
    }
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final n = i + 1;
      if (q.text.trim().isEmpty) {
        errors.add('Question $n text is required');
      }
      if (q.options.length != optionCount) {
        errors.add('Question $n must have $optionCount options');
      } else {
        for (var j = 0; j < q.options.length; j++) {
          if (q.options[j].trim().isEmpty) {
            errors.add('Question $n option ${j + 1} is required');
          }
        }
      }
      if (q.correctIndex < 0 || q.correctIndex > optionCount - 1) {
        errors.add('Question $n must mark a valid correct option');
      }
    }
    return errors;
  }
}
