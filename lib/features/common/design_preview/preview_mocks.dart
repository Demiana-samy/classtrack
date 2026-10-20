import '../../auth/data/app_user.dart';
import '../../../core/constants/app_constants.dart';

const mockTeacher = AppUser(
  id: 'preview-teacher',
  name: 'Sara Ahmed',
  email: 'sara@university.edu',
  role: Roles.teacher,
);

const mockStudent = AppUser(
  id: 'preview-student',
  name: 'Omar Ali',
  email: 'omar@university.edu',
  role: Roles.student,
  studentId: '20231234',
);

class MockClass {
  const MockClass({
    required this.id,
    required this.name,
    required this.semester,
    required this.joinCode,
    required this.studentCount,
  });

  final String id;
  final String name;
  final String semester;
  final String joinCode;
  final int studentCount;
}

const mockClasses = [
  MockClass(
    id: 'c1',
    name: 'Mobile Programming',
    semester: 'Fall 2026',
    joinCode: 'K7MP2Q',
    studentCount: 28,
  ),
  MockClass(
    id: 'c2',
    name: 'Data Structures',
    semester: 'Fall 2026',
    joinCode: 'DS9X4B',
    studentCount: 32,
  ),
];

class MockRecord {
  const MockRecord({
    required this.name,
    required this.studentId,
    required this.status,
    this.distance,
    this.score,
  });

  final String name;
  final String studentId;
  final String status;
  final double? distance;
  final int? score;
}

const mockRecords = [
  MockRecord(name: 'Omar Ali', studentId: '20231234', status: 'present', distance: 12.4, score: 5),
  MockRecord(name: 'Lina Hassan', studentId: '20230011', status: 'present', distance: 8.1, score: 4),
  MockRecord(name: 'Yousef Nabil', studentId: '20230888', status: 'rejected', distance: 210.0),
];
