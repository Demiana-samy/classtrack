import 'package:equatable/equatable.dart';

/// A class as the student sees it (no join code needed on the student side).
class ClassInfo extends Equatable {
  const ClassInfo({
    required this.id,
    required this.name,
    this.semester = '',
    this.teacherId = '',
    this.joinCode = '',
  });

  final String id;
  final String name;
  final String semester;
  final String teacherId;

  /// Only readable by the teacher and enrolled students (firestore.rules).
  final String joinCode;

  factory ClassInfo.fromMap(String id, Map<String, dynamic> m) => ClassInfo(
        id: id,
        name: m['name'] as String? ?? '',
        semester: m['semester'] as String? ?? '',
        teacherId: m['teacherID'] as String? ?? '',
        joinCode: m['joinCode'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, name, semester, teacherId, joinCode];
}
