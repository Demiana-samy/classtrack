class AppConstants {
  static const sessionDurationSeconds = 120; // exactly 2 minutes
  static const quizQuestionCount = 5;
  static const defaultRadiusMeters = 50;
  static const minRadiusMeters = 10;
  static const maxRadiusMeters = 500;
}

/// Firestore collection names.
class Col {
  static const users = 'users';
  static const classes = 'classes';
  static const enrollments = 'enrollments';
  static const sessions = 'attendance_sessions';
  static const records = 'attendance_records';
}

class Roles {
  static const teacher = 'teacher';
  static const student = 'student';
}

class Modes {
  static const punchIn = 'punch_in';
  static const quiz = 'quiz';
}
