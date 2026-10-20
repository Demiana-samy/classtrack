import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
  });

  final String id;
  final String name;
  final String email;
  final String role; // 'teacher' | 'student'
  final String? studentId;

  bool get isTeacher => role == Roles.teacher;

  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
        id: id,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        role: m['role'] as String? ?? Roles.student,
        studentId: m['studentID'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        if (studentId != null) 'studentID': studentId,
      };

  @override
  List<Object?> get props => [id, name, email, role, studentId];
}
