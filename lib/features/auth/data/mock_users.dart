import '../../../core/constants/app_constants.dart';
import 'app_user.dart';

const mockTeacherSara = AppUser(
  id: 'preview-teacher-sara',
  name: 'Sara',
  email: 'sara@university.edu',
  role: Roles.teacher,
);

const mockTeacherAhmed = AppUser(
  id: 'preview-teacher-ahmed',
  name: 'Ahmed',
  email: 'ahmed@university.edu',
  role: Roles.teacher,
);

const mockStudentMohamed = AppUser(
  id: 'preview-student-mohamed',
  name: 'Mohamed',
  email: 'mohamed@university.edu',
  role: Roles.student,
  studentId: '20231234',
);

const mockStudentAhmed = AppUser(
  id: 'preview-student-ahmed',
  name: 'Ahmed',
  email: 'ahmed.s@university.edu',
  role: Roles.student,
  studentId: '20230011',
);
