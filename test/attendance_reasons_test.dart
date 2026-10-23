import 'package:classtrack/features/attendance/data/attendance_reasons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every server reason code to readable copy', () {
    expect(AttendanceReasons.message('session_expired'), 'This session has ended.');
    expect(AttendanceReasons.message('not_enrolled'), 'You are not enrolled in this class.');
    expect(AttendanceReasons.message('no_gps'), 'Location was not available.');
    expect(AttendanceReasons.message('out_of_range'), 'You are too far from the classroom.');
    expect(AttendanceReasons.message('already_attended'), 'You already punched in.');
    expect(
      AttendanceReasons.message('quiz_incomplete'),
      'Answer all 5 questions before time runs out.',
    );
    expect(AttendanceReasons.message('session_not_found'), 'This session could not be found.');
  });
}
