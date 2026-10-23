/// Maps `submitAttendance` reason codes from functions/index.js to UI copy.
class AttendanceReasons {
  static const sessionExpired = 'session_expired';
  static const notEnrolled = 'not_enrolled';
  static const noGps = 'no_gps';
  static const outOfRange = 'out_of_range';
  static const alreadyAttended = 'already_attended';
  static const quizIncomplete = 'quiz_incomplete';
  static const sessionNotFound = 'session_not_found';

  static String message(String? code) {
    switch (code) {
      case sessionExpired:
        return 'This session has ended.';
      case notEnrolled:
        return 'You are not enrolled in this class.';
      case noGps:
        return 'Location was not available.';
      case outOfRange:
        return 'You are too far from the classroom.';
      case alreadyAttended:
        return 'You already punched in.';
      case quizIncomplete:
        return 'Answer all 5 questions before time runs out.';
      case sessionNotFound:
        return 'This session could not be found.';
      default:
        return 'Attendance was not accepted.';
    }
  }

  static String distanceLine(double meters) => 'You are ${meters.round()} m away.';

  static String radiusLine(int meters) => 'Allowed radius is $meters m.';
}
