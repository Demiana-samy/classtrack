class MockClassInfo {
  const MockClassInfo({
    required this.id,
    required this.name,
    required this.semester,
    required this.joinCode,
    required this.teacherName,
    required this.studentCount,
  });

  final String id;
  final String name;
  final String semester;
  final String joinCode;
  final String teacherName;
  final int studentCount;
}

const mockClasses = <MockClassInfo>[
  MockClassInfo(
    id: 'c-mp',
    name: 'Mobile Programming',
    semester: 'Fall 2026',
    joinCode: 'MP-4K9X',
    teacherName: 'Sara',
    studentCount: 28,
  ),
  MockClassInfo(
    id: 'c-db',
    name: 'Databases',
    semester: 'Fall 2026',
    joinCode: 'DB-7N2P',
    teacherName: 'Sara',
    studentCount: 24,
  ),
  MockClassInfo(
    id: 'c-net',
    name: 'Networks',
    semester: 'Fall 2026',
    joinCode: 'NT-3H8Q',
    teacherName: 'Ahmed',
    studentCount: 31,
  ),
];
