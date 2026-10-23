/// Path constants for every screen. Teammates navigate with these;
/// do not edit [buildRouter] in `app_router.dart`.
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const designPreview = '/design-preview';

  static const teacherHome = '/teacher';
  static const createClass = '/teacher/create-class';
  static const classDetails = '/teacher/class/:classId';
  static const startSession = '/teacher/start-session/:classId';
  static const quizBuilder = '/teacher/quiz-builder/:classId';
  static const liveDashboard = '/teacher/live/:sessionId';
  static const sessionResults = '/teacher/results/:sessionId';

  static const studentHome = '/student';
  static const joinClass = '/student/join';
  static const activeSession = '/student/session/:sessionId';
  static const quiz = '/student/quiz/:sessionId';
  static const result = '/student/result';
  static const attendanceHistory = '/student/history';

  static String classDetailsPath(String classId) => '/teacher/class/$classId';
  static String startSessionPath(String classId) => '/teacher/start-session/$classId';
  static String quizBuilderPath(String classId) => '/teacher/quiz-builder/$classId';
  static String liveDashboardPath(String sessionId) => '/teacher/live/$sessionId';
  static String sessionResultsPath(String sessionId) => '/teacher/results/$sessionId';
  static String activeSessionPath(String sessionId) => '/student/session/$sessionId';
  static String quizPath(String sessionId) => '/student/quiz/$sessionId';
}
