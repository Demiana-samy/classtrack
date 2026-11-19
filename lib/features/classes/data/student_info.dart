import 'package:equatable/equatable.dart';

/// A student in a class roster (from `users` + `enrollments`).
class StudentInfo extends Equatable {
  const StudentInfo({
    required this.id,
    required this.name,
    this.studentNumber = '',
    this.joinedAt,
  });

  /// Firebase Auth uid.
  final String id;
  final String name;

  /// University ID typed at register (`users.studentID`).
  final String studentNumber;

  /// When the student joined this class (null for old enrollments).
  final DateTime? joinedAt;

  StudentInfo withJoinedAt(DateTime? at) =>
      StudentInfo(id: id, name: name, studentNumber: studentNumber, joinedAt: at);

  @override
  List<Object?> get props => [id, name, studentNumber, joinedAt];
}
