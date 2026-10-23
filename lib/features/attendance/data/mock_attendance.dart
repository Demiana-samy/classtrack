class MockAttendanceRecord {
  const MockAttendanceRecord({
    required this.name,
    required this.studentId,
    required this.status,
    this.className = 'Mobile Programming',
    this.distance,
    this.score,
  });

  final String name;
  final String studentId;
  final String status;
  final String className;
  final double? distance;
  final int? score;
}

const mockAttendanceRecords = <MockAttendanceRecord>[
  MockAttendanceRecord(
    name: 'Mohamed',
    studentId: '20231234',
    status: 'present',
    distance: 12.4,
    score: 5,
  ),
  MockAttendanceRecord(
    name: 'Ahmed',
    studentId: '20230011',
    status: 'present',
    distance: 8.1,
    score: 4,
  ),
  MockAttendanceRecord(
    name: 'Sara',
    studentId: '20230888',
    status: 'rejected',
    distance: 183,
  ),
];

const mockRejectedDistance = 183.0;
const mockAllowedRadius = 50;
