import 'package:classtrack/features/quiz/data/quiz_question_draft.dart';
import 'package:flutter_test/flutter_test.dart';

QuizQuestionDraft _q({
  String text = 'Question',
  List<String> options = const ['A', 'B', 'C', 'D'],
  int correctIndex = 0,
}) =>
    QuizQuestionDraft(text: text, options: options, correctIndex: correctIndex);

List<QuizQuestionDraft> _five() => List.generate(5, (i) => _q(text: 'Q${i + 1}'));

void main() {
  test('valid 5-question draft matches startSession payload keys', () {
    final questions = _five();
    expect(QuizDraftValidator.isValid(questions), isTrue);
    expect(QuizDraftValidator.validate(questions), isEmpty);

    final map = questions.first.toMap();
    expect(map.keys.toSet(), {'text', 'options', 'correctIndex'});
    expect(map['options'], hasLength(4));
  });

  test('rejects wrong question count', () {
    expect(QuizDraftValidator.validate([_q()]), contains('Quiz needs exactly 5 questions'));
  });

  test('rejects empty text, empty option, and bad correctIndex', () {
    final questions = [
      _q(text: '  '),
      _q(options: const ['A', 'B', '', 'D']),
      _q(correctIndex: 4),
      _q(options: const ['only-one']),
      _q(),
    ];
    final errors = QuizDraftValidator.validate(questions);
    expect(errors, contains('Question 1 text is required'));
    expect(errors, contains('Question 2 option 3 is required'));
    expect(errors, contains('Question 3 must mark a valid correct option'));
    expect(errors, contains('Question 4 must have 4 options'));
  });
}
