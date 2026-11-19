import 'package:equatable/equatable.dart';

/// A class as the student sees it (no join code needed on the student side).
class ClassInfo extends Equatable {
  const ClassInfo({
    required this.id,
    required this.name,
    this.semester = '',
    this.teacherId = '',
  });

  final String id;
  final String name;
  final String semester;
  final String teacherId;

  factory ClassInfo.fromMap(String id, Map<String, dynamic> m) => ClassInfo(
        id: id,
        name: m['name'] as String? ?? '',
        semester: m['semester'] as String? ?? '',
        teacherId: m['teacherID'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, name, semester, teacherId];
}
