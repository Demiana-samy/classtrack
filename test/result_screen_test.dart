import 'package:classtrack/core/theme/app_theme.dart';
import 'package:classtrack/features/attendance/presentation/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: child,
  );
}

void main() {
  testWidgets('rejected result matches out-of-range copy', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ResultScreen(
          accepted: false,
          reason: 'out_of_range',
          distance: 183,
          radius: 50,
        ),
      ),
    );

    expect(find.text('Not accepted'), findsOneWidget);
    expect(find.text('You are too far from the classroom.'), findsOneWidget);
    expect(find.text('You are 183 m away.'), findsOneWidget);
    expect(find.text('Allowed radius is 50 m.'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('accepted result shows check, distance, radius, and score', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ResultScreen(
          accepted: true,
          distance: 12.4,
          radius: 50,
          score: 4,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('You are 12 m away.'), findsOneWidget);
    expect(find.text('Allowed radius is 50 m.'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });
}
