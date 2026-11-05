import '../../../../core/constants/app_constants.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String text;
  final List<String> options;
  final int correctIndex;
}

class QuizDraftValidator {
  static const questionCount = AppConstants.quizQuestionCount;
  static const optionCount = 4;

  static bool isValid(List<QuizQuestion> questions) =>
      validate(questions).isEmpty;

  static List<String> validate(List<QuizQuestion> questions) {
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

class QuizScorer {
  const QuizScorer._();

  static int score(List<QuizQuestion> questions, List<int?> answers) {
    var total = 0;
    for (var i = 0; i < questions.length && i < answers.length; i++) {
      if (answers[i] == questions[i].correctIndex) {
        total++;
      }
    }
    return total;
  }
}
