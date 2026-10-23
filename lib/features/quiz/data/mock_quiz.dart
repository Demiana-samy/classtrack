import 'quiz_question_draft.dart';

/// Sample 5-question quiz for UI work without Firebase.
const mockQuizQuestions = <QuizQuestionDraft>[
  QuizQuestionDraft(
    text: 'What does GPS stand for?',
    options: [
      'Global Positioning System',
      'General Packet Service',
      'Grouped Protocol Stack',
      'Geo Point Sampler',
    ],
    correctIndex: 0,
  ),
  QuizQuestionDraft(
    text: 'Which collection stores live attendance windows?',
    options: [
      'users',
      'attendance_sessions',
      'enrollments',
      'classes',
    ],
    correctIndex: 1,
  ),
  QuizQuestionDraft(
    text: 'How long is a ClassTrack session?',
    options: ['30 seconds', '1 minute', '2 minutes', '5 minutes'],
    correctIndex: 2,
  ),
  QuizQuestionDraft(
    text: 'Who computes the quiz score?',
    options: ['The student phone', 'The teacher phone', 'Cloud Functions', 'Firestore rules'],
    correctIndex: 2,
  ),
  QuizQuestionDraft(
    text: 'A student 183 m away from a 50 m radius is…',
    options: ['present', 'late', 'out of range', 'enrolled only'],
    correctIndex: 2,
  ),
];
