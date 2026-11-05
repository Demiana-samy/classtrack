import '../../domain/entities/quiz_question.dart';

class QuizQuestionDraft extends QuizQuestion {
  const QuizQuestionDraft({
    required super.text,
    required super.options,
    required super.correctIndex,
  });

  factory QuizQuestionDraft.fromMap(Map<String, dynamic> map) {
    return QuizQuestionDraft(
      text: map['text'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? const []),
      correctIndex: map['correctIndex'] as int? ?? 0,
    );
  }

  factory QuizQuestionDraft.fromEntity(QuizQuestion entity) {
    return QuizQuestionDraft(
      text: entity.text,
      options: entity.options,
      correctIndex: entity.correctIndex,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
      };
}
