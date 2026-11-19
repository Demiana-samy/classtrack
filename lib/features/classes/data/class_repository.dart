import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import 'class_info.dart';
import 'student_info.dart';

/// Answer from the `joinClass` Cloud Function.
class JoinResult {
  const JoinResult({
    required this.classId,
    required this.className,
    required this.alreadyJoined,
  });

  final String classId;
  final String className;
  final bool alreadyJoined;
}

class ClassRepository {
  ClassRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  /// 6-character join code. Shown on Create Class before saving.
  static String generateJoinCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)]).join();
  }

  Future<String> createClass({
    required String name,
    required String semester,
    required String teacherId,
    String? joinCode,
  }) async {
    final ref = _db.collection(Col.classes).doc();
    await ref.set({
      'name': name.trim(),
      'semester': semester.trim(),
      'teacherID': teacherId,
      'joinCode': joinCode ?? generateJoinCode(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// My classes as a teacher, live, sorted by name.
  Stream<List<ClassInfo>> watchTeacherClassInfos(String teacherId) =>
      watchTeacherClasses(teacherId).map(
        (q) => q.docs.map((d) => ClassInfo.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      );

  /// Number of enrolled students (aggregate count, no documents downloaded).
  Future<int> fetchStudentCount(String classId) async {
    final agg = await _db
        .collection(Col.enrollments)
        .where('classID', isEqualTo: classId)
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Roster of a class, live: enrollments joined with `users` (name, studentID).
  Stream<List<StudentInfo>> watchClassStudents(String classId) =>
      watchClassEnrollments(classId).asyncMap(_studentsFromEnrollments);

  Future<List<StudentInfo>> fetchClassStudents(String classId) async {
    final q = await _db.collection(Col.enrollments).where('classID', isEqualTo: classId).get();
    return _studentsFromEnrollments(q);
  }

  Future<List<StudentInfo>> _studentsFromEnrollments(QuerySnapshot<Map<String, dynamic>> q) async {
    final joined = <String, DateTime?>{
      for (final d in q.docs)
        if ((d.data()['studentID'] as String? ?? '').isNotEmpty)
          d.data()['studentID'] as String: (d.data()['joinedAt'] as Timestamp?)?.toDate(),
    };
    final users = await fetchUsers(joined.keys.toList());
    final list = joined.entries
        .map((e) => (users[e.key] ?? StudentInfo(id: e.key, name: 'Student')).withJoinedAt(e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// `users` docs by uid, 30 per query (Firestore `whereIn` limit).
  Future<Map<String, StudentInfo>> fetchUsers(List<String> uids) async {
    final result = <String, StudentInfo>{};
    for (var i = 0; i < uids.length; i += 30) {
      final chunk = uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
      final q = await _db
          .collection(Col.users)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in q.docs) {
        result[d.id] = StudentInfo(
          id: d.id,
          name: d.data()['name'] as String? ?? 'Student',
          studentNumber: d.data()['studentID'] as String? ?? '',
        );
      }
    }
    return result;
  }

  /// Class name for headers (e.g. Active Session). Null if the class is missing.
  Future<String?> fetchClassName(String classId) async {
    if (classId.isEmpty) return null;
    final doc = await _db.collection(Col.classes).doc(classId).get();
    return doc.data()?['name'] as String?;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeacherClasses(String teacherId) =>
      _db.collection(Col.classes).where('teacherID', isEqualTo: teacherId).snapshots();

  /// Joins the signed-in student to a class. The code is checked by the
  /// `joinClass` Cloud Function; the app cannot write enrollments itself.
  /// Throws [FirebaseFunctionsException] with code `not-found` for a wrong code.
  Future<JoinResult> joinByCode(String code) async {
    final res = await _functions.httpsCallable('joinClass').call({'code': code.trim()});
    final m = res.data as Map;
    return JoinResult(
      classId: m['classId'] as String,
      className: m['className'] as String? ?? '',
      alreadyJoined: m['alreadyJoined'] == true,
    );
  }

  /// Name, semester and teacher of one class. Null if missing or not readable
  /// (firestore.rules: only the teacher and enrolled students can read a class).
  Future<ClassInfo?> fetchClassInfo(String classId) async {
    if (classId.isEmpty) return null;
    final doc = await _db.collection(Col.classes).doc(classId).get();
    final data = doc.data();
    return data == null ? null : ClassInfo.fromMap(doc.id, data);
  }

  /// IDs of the classes the student is enrolled in, live.
  Stream<List<String>> watchStudentClassIds(String studentId) =>
      watchStudentEnrollments(studentId).map(
        (q) => q.docs.map((d) => d.data()['classID'] as String? ?? '').where((id) => id.isNotEmpty).toList(),
      );

  /// classId -> when the student joined (null for old enrollments without joinedAt).
  Future<Map<String, DateTime?>> fetchStudentJoinDates(String studentId) async {
    final q = await _db.collection(Col.enrollments).where('studentID', isEqualTo: studentId).get();
    return {
      for (final d in q.docs)
        if ((d.data()['classID'] as String? ?? '').isNotEmpty)
          d.data()['classID'] as String: (d.data()['joinedAt'] as Timestamp?)?.toDate(),
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudentEnrollments(String studentId) =>
      _db.collection(Col.enrollments).where('studentID', isEqualTo: studentId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchClassEnrollments(String classId) =>
      _db.collection(Col.enrollments).where('classID', isEqualTo: classId).snapshots();
}
