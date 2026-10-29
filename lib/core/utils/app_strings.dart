/// Centralized application strings for the ClassTrack project.
abstract final class AppStrings {
  const AppStrings._();

  static const String quizPortal = 'Quiz Portal';
  static const String quizBuilderTitle = 'Quiz builder';
  static const String quizTitle = 'Quiz';
  static const String teacherQuizBuilder = 'Teacher Quiz Builder';
  static const String studentQuiz = 'Student Quiz';
  static const String teacher = 'Teacher';
  static const String student = 'Student';
  static const String logOut = 'Log out';
  static const String signIn = 'Sign In';
  static const String selectRolePrompt = 'Select role and enter ID to continue';
  static const String classId = 'Class ID';
  static const String sessionId = 'Session ID';
  static const String questionHint = 'Type the question';
  static const String optionA = 'Option A';
  static const String optionB = 'Option B';
  static const String optionC = 'Option C';
  static const String optionD = 'Option D';
  static const String openQuizBuilder = 'Open Quiz Builder';
  static const String takeQuiz = 'Take Quiz';
  static const String buildQuizDirectly = 'Build Quiz directly (no Class ID)';
  static const String openQuizDirectly = 'Open Quiz directly (no Session ID)';
  static const String saveAndNext = 'Save and next';
  static const String createQuiz = 'Create Quiz';
  static const String submit = 'Submit';
  static const String finish = 'Finish';
  static const String enterValidClassId = 'Please enter a valid Class ID';
  static const String enterValidSessionId = 'Please enter a valid Session ID';
  static const String emptyQuestionError = 'Please enter question text before continuing.';
  static const String emptyOptionError = 'Please complete all four answer options.';
  static const String noCorrectOptionError = 'Please select the correct answer for this question.';
  static const String selectAnswerToContinue = 'Please select an answer before continuing.';
  static const String quizCreatedSuccess = 'Quiz created successfully with 5 questions!';
  static const String quizCreatedTitle = 'Quiz Created';
  static const String quizCreatedMessage = 'All 5 questions have been configured successfully.';
  static const String quizCompleted = 'Quiz Completed';
  static const String quizCompletedDesc = 'You have answered all 5 questions.';
  static const String noQuestionsAvailable = 'No quiz questions available for this session.';
  static String questionOf(int current, int total) => 'Question $current of $total';
  static String loggedInAs(String name, String role) => 'Logged in as $name ($role)';
  static String scoreOf(int score, int total) => 'Score: $score / $total';
}
