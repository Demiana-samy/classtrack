import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/core/constants/app_constants.dart';

void main() {
  test('session lasts exactly 2 minutes', () {
    expect(AppConstants.sessionDurationSeconds, 120);
  });
}
