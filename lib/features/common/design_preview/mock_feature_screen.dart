import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/countdown_ring.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../attendance/data/mock_attendance.dart';
import '../../classes/data/mock_classes.dart';

/// Review-only layout used until the real feature screen is built.
/// Data is constructor-driven so later phases can swap this for the real widget.
class MockFeatureScreen extends StatelessWidget {
  const MockFeatureScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.body,
  });

  final String title;
  final String subtitle;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mock preview',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            body ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class MockTeacherHomePreview extends StatelessWidget {
  const MockTeacherHomePreview({super.key, this.classes = mockClasses});

  final List<MockClassInfo> classes;

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'My classes',
      subtitle: 'Teacher home streams classes. FAB opens Create class.',
      body: Column(
        children: [
          for (final c in classes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(c.semester, style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(label: c.joinCode, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('${c.studentCount} students',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MockCreateClassPreview extends StatelessWidget {
  const MockCreateClassPreview({super.key, this.joinCode = 'MP-4K9X'});

  final String joinCode;

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'Create class',
      subtitle: 'After create, show the join code with Copy and Share.',
      body: _Card(
        child: Column(
          children: [
            const Text('Join code', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(joinCode, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 4)),
            const SizedBox(height: 16),
            const PrimaryButton(label: 'Copy code', onPressed: _noop),
          ],
        ),
      ),
    );
  }
}

class MockClassDetailsPreview extends StatelessWidget {
  const MockClassDetailsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mobile Programming'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Students'), Tab(text: 'Sessions')],
          ),
        ),
        body: const TabBarView(
          children: [
            _StudentTab(),
            _SessionTab(),
          ],
        ),
        bottomNavigationBar: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: PrimaryButton(label: 'Start session', onPressed: _noop),
          ),
        ),
      ),
    );
  }
}

class _StudentTab extends StatelessWidget {
  const _StudentTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(title: Text('Mohamed'), subtitle: Text('20231234')),
        ListTile(title: Text('Ahmed'), subtitle: Text('20230011')),
      ],
    );
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Punch-in · closed'),
          subtitle: Text('Oct 17, 2026'),
          trailing: StatusChip(label: '12 present', color: AppColors.success),
        ),
      ],
    );
  }
}

class MockStudentHomePreview extends StatelessWidget {
  const MockStudentHomePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Hi, Mohamed',
      subtitle: 'Active session card + my classes + Join a class.',
      body: Column(
        children: [
          _Card(
            child: Column(
              children: [
                Text('Attendance is open', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Mobile Programming', style: TextStyle(color: AppColors.muted)),
                SizedBox(height: 12),
                CountdownRing(
                  remaining: Duration(seconds: 87),
                  total: Duration(seconds: AppConstants.sessionDurationSeconds),
                  size: 120,
                ),
                SizedBox(height: 12),
                PrimaryButton(label: 'Open', onPressed: _noop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MockJoinClassPreview extends StatelessWidget {
  const MockJoinClassPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Join a class',
      subtitle: '6-character uppercase code. Success and error states live here.',
      body: _Card(
        child: Text('MP-4K9X', style: TextStyle(fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class MockStartSessionPreview extends StatelessWidget {
  const MockStartSessionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'Start session',
      subtitle: 'Mode segmented control, radius slider, GPS row, then START.',
      body: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Radius: 50 m'),
            Slider(value: 50, min: 10, max: 500, onChanged: (_) {}),
            const Text('Using your location', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            const PrimaryButton(label: 'Start attendance', onPressed: _noop),
          ],
        ),
      ),
    );
  }
}

class MockActiveSessionPreview extends StatelessWidget {
  const MockActiveSessionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Punch in',
      subtitle: 'Countdown from expiryTime. Server decides accept/reject.',
      body: Column(
        children: [
          Text('Mobile Programming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 16),
          CountdownRing(
            remaining: Duration(seconds: 64),
            total: Duration(seconds: AppConstants.sessionDurationSeconds),
          ),
          SizedBox(height: 16),
          _Card(child: Text('You can open this even if you are far away.')),
        ],
      ),
    );
  }
}

class MockResultPreview extends StatelessWidget {
  const MockResultPreview({
    super.key,
    required this.accepted,
    this.reason,
    this.distance = 12.4,
    this.radius = 50,
    this.score,
  });

  final bool accepted;
  final String? reason;
  final double distance;
  final int radius;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'Result',
      subtitle: accepted
          ? 'Accepted: distance vs radius, plus quiz score when in quiz mode.'
          : 'Rejected: map server reason codes to a clear sentence.',
      body: _Card(
        child: Column(
          children: [
            Icon(
              accepted ? Icons.check_circle : Icons.cancel,
              color: accepted ? AppColors.success : AppColors.danger,
              size: 72,
            ),
            const SizedBox(height: 8),
            Text(accepted ? 'You are present' : _reasonText(reason)),
            Text(
              '${distance.toStringAsFixed(1)} m / $radius m',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (score != null) Text('Score $score / ${AppConstants.quizQuestionCount}'),
          ],
        ),
      ),
    );
  }

  String _reasonText(String? code) {
    switch (code) {
      case 'out_of_range':
        return 'Too far from class (${distance.toStringAsFixed(0)} m, allowed $radius m).';
      case 'session_expired':
        return 'This session has ended.';
      case 'not_enrolled':
        return 'You are not enrolled in this class.';
      case 'no_gps':
        return 'Location was not available.';
      case 'already_attended':
        return 'You already punched in.';
      case 'quiz_incomplete':
        return 'Answer all 5 questions before time runs out.';
      case 'session_not_found':
        return 'This session could not be found.';
      default:
        return 'Attendance was not accepted.';
    }
  }
}

class MockQuizBuilderPreview extends StatelessWidget {
  const MockQuizBuilderPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Quiz builder',
      subtitle: 'Exactly 5 questions, 4 options, one correct. Then startSession.',
      body: _Card(child: Text('Question 1 of 5')),
    );
  }
}

class MockQuizPreview extends StatelessWidget {
  const MockQuizPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'Quiz',
      subtitle: 'One question per page. Submit only when all 5 are answered.',
      body: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(value: 0.4),
            const SizedBox(height: 12),
            const Text('What is the capital of Egypt?'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Text('Cairo'),
            ),
          ],
        ),
      ),
    );
  }
}

class MockLiveDashboardPreview extends StatelessWidget {
  const MockLiveDashboardPreview({super.key, this.records = mockAttendanceRecords});

  final List<MockAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return MockFeatureScreen(
      title: 'Live session',
      subtitle: 'N / total present, live list, End session, View results.',
      body: Column(
        children: [
          const LinearProgressIndicator(value: 2 / 28),
          const SizedBox(height: 8),
          const Text('2 / 28 present'),
          const SizedBox(height: 12),
          for (final r in records)
            ListTile(
              title: Text(r.name),
              subtitle: Text('${r.distance?.toStringAsFixed(1) ?? '—'} m'),
              trailing: StatusChip(
                label: r.status,
                color: r.status == 'present' ? AppColors.success : AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class MockSessionResultsPreview extends StatelessWidget {
  const MockSessionResultsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Session results',
      subtitle: 'Present / rejected / absent (enrolled minus present). Quiz scores when quiz mode.',
      body: Column(
        children: [
          ListTile(title: Text('Present'), trailing: Text('2')),
          ListTile(title: Text('Rejected'), trailing: Text('1')),
          ListTile(title: Text('Absent'), trailing: Text('25')),
        ],
      ),
    );
  }
}

class MockHistoryPreview extends StatelessWidget {
  const MockHistoryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MockFeatureScreen(
      title: 'Attendance history',
      subtitle: 'My records: class, date, status chip, score/distance.',
      body: Column(
        children: [
          ListTile(
            title: Text('Mobile Programming'),
            subtitle: Text('Oct 17 · 12.4 m'),
            trailing: StatusChip(label: 'present', color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

void _noop() {}
