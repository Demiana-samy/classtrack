import 'package:classtrack/core/constants/app_constants.dart';
import 'package:classtrack/features/attendance/data/attendance_record.dart';
import 'package:classtrack/features/attendance/data/attendance_session.dart';
import 'package:classtrack/features/attendance/data/session_results.dart';
import 'package:classtrack/features/attendance/presentation/session_results_cubit.dart';
import 'package:classtrack/features/classes/data/class_repository.dart';
import 'package:classtrack/features/classes/data/student_info.dart';
import 'package:classtrack/features/quiz/data/models/quiz_question_model.dart';
import 'package:classtrack/features/quiz/domain/entities/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 9, 22, 9);

AttendanceSession _session({String mode = Modes.quiz}) => AttendanceSession(
      id: 'ATT-2026-0922-001',
      classId: 'c-mp',
      mode: mode,
      radius: 50,
      startTime: _start,
      expiryTime: _start.add(const Duration(minutes: 2)),
      status: 'closed',
    );

AttendanceRecord _rec(String id, String status, {double? d, int? score, bool submitted = true}) =>
    AttendanceRecord(
      sessionId: 'ATT-2026-0922-001',
      studentId: id,
      classId: 'c-mp',
      status: status,
      distance: d,
      quizScore: score,
      quizSubmitted: submitted,
    );

const _ahmed = StudentInfo(id: 'a', name: 'Ahmed', studentNumber: '2024001');
const _sara = StudentInfo(id: 's', name: 'Sara', studentNumber: '2024002');
const _mohamed = StudentInfo(id: 'm', name: 'Mohamed', studentNumber: '2024003');
const _ali = StudentInfo(id: 'l', name: 'Ali', studentNumber: '2024004');

void main() {
  group('SessionResults.build (assignment section 3.2 example)', () {
    final results = SessionResults.build(
      session: _session(),
      students: const [_ahmed, _sara, _mohamed, _ali],
      records: [
        _rec('a', 'present', d: 18, score: 4),
        _rec('s', 'present', d: 31, score: 5),
        _rec('m', 'rejected', d: 124, score: 5),
      ],
    );

    test('counts present, rejected and absent', () {
      expect(results.present, 2);
      expect(results.rejected, 1);
      expect(results.absent, 1);
    });

    test('Ali has no record, so he is absent and not submitted', () {
      final ali = results.rows.firstWhere((r) => r.studentId == 'l');
      expect(ali.status, 'absent');
      expect(ali.quizSubmitted, isFalse);
      expect(ali.quizScore, isNull);
    });

    test('ordered: present by score (high first), then rejected, then absent', () {
      expect(results.rows.map((r) => r.name), ['Sara', 'Ahmed', 'Mohamed', 'Ali']);
    });

    test('average score uses present students only', () {
      expect(results.averageScore, 4.5);
    });
  });

  group('SessionResults ordering', () {
    test('same score: closer student first, then by name', () {
      final r = SessionResults.build(
        session: _session(),
        students: const [
          StudentInfo(id: '1', name: 'Zeina'),
          StudentInfo(id: '2', name: 'Bassem'),
          StudentInfo(id: '3', name: 'Adel'),
        ],
        records: [
          _rec('1', 'present', d: 40, score: 3),
          _rec('2', 'present', d: 10, score: 3),
          _rec('3', 'present', d: 10, score: 3),
        ],
      );
      expect(r.rows.map((x) => x.name), ['Adel', 'Bassem', 'Zeina']);
    });

    test('punch-in sessions sort by distance inside each group', () {
      final r = SessionResults.build(
        session: _session(mode: Modes.punchIn),
        students: const [_ahmed, _sara],
        records: [_rec('a', 'present', d: 30, submitted: false), _rec('s', 'present', d: 5, submitted: false)],
      );
      expect(r.rows.map((x) => x.name), ['Sara', 'Ahmed']);
      expect(r.averageScore, isNull);
    });
  });

  group('Absent calculation', () {
    test('a student who joined after the session started is not absent', () {
      final r = SessionResults.build(
        session: _session(),
        students: [
          _ahmed.withJoinedAt(_start.subtract(const Duration(days: 3))),
          _sara.withJoinedAt(_start.add(const Duration(hours: 1))),
        ],
        records: const [],
      );
      expect(r.rows.map((x) => x.name), ['Ahmed']);
      expect(r.absent, 1);
    });

    test('a stored "absent" record (written by markAbsentees) stays absent', () {
      final r = SessionResults.build(
        session: _session(),
        students: const [_ali],
        records: [_rec('l', 'absent', submitted: false)],
      );
      expect(r.absent, 1);
      expect(r.rows.single.status, 'absent');
    });

    test('records of students who left the class still show', () {
      final r = SessionResults.build(
        session: _session(),
        students: const [_ahmed],
        records: [_rec('a', 'present', d: 9, score: 5), _rec('gone', 'present', d: 12, score: 2)],
      );
      expect(r.rows, hasLength(2));
      expect(r.rows.last.name, 'Former student');
    });

    test('empty class gives empty results', () {
      final r = SessionResults.build(session: _session(), students: const [], records: const []);
      expect(r.rows, isEmpty);
      expect(r.present + r.rejected + r.absent, 0);
    });
  });

  group('CSV export', () {
    test('has a header and one line per student, matching the example table', () {
      final csv = SessionResultsCubit.previewResults('ATT-1').toCsv(className: 'Mobile Programming');
      final lines = csv.trim().split('\n');
      expect(lines.first, 'Class,Session ID,Student,Student ID,Distance (m),Quiz,Score,Attendance');
      expect(lines, hasLength(5));
      expect(lines, contains('Mobile Programming,ATT-1,Mohamed,2024003,124,Submitted,5/5,Rejected'));
      expect(lines.last, 'Mobile Programming,ATT-1,Ali,2024004,,Not submitted,,Absent');
    });

    test('values with commas are quoted', () {
      final csv = SessionResults.build(
        session: _session(mode: Modes.punchIn),
        students: const [StudentInfo(id: 'x', name: 'Ali, Jr.')],
        records: const [],
      ).toCsv();
      expect(csv, contains('"Ali, Jr."'));
    });
  });

  group('Join code', () {
    test('6 characters from the readable alphabet (no 0/O/1/I)', () {
      for (var i = 0; i < 200; i++) {
        final code = ClassRepository.generateJoinCode();
        expect(code, hasLength(6));
        expect(RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(code), isTrue, reason: code);
      }
    });
  });

  group('Quiz Builder rules (5 questions, 4 options, one correct)', () {
    QuizQuestionDraft q({String text = 'Q', List<String>? options, int correct = 0}) =>
        QuizQuestionDraft(text: text, options: options ?? const ['A', 'B', 'C', 'D'], correctIndex: correct);

    test('exactly 5 valid questions pass', () {
      expect(QuizDraftValidator.isValid(List.generate(5, (_) => q())), isTrue);
    });

    test('4 or 6 questions fail', () {
      expect(QuizDraftValidator.isValid(List.generate(4, (_) => q())), isFalse);
      expect(QuizDraftValidator.isValid(List.generate(6, (_) => q())), isFalse);
    });

    test('3 options, an empty option or no correct answer fail', () {
      final base = List.generate(4, (_) => q());
      expect(QuizDraftValidator.isValid([...base, q(options: const ['A', 'B', 'C'])]), isFalse);
      expect(QuizDraftValidator.isValid([...base, q(options: const ['A', '', 'C', 'D'])]), isFalse);
      expect(QuizDraftValidator.isValid([...base, q(correct: -1)]), isFalse);
      expect(QuizDraftValidator.isValid([...base, q(text: '  ')]), isFalse);
    });
  });
}
