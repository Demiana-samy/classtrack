import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';

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

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String> createClass({
    required String name,
    required String semester,
    required String teacherId,
  }) async {
    final ref = _db.collection(Col.classes).doc();
    await ref.set({
      'name': name.trim(),
      'semester': semester.trim(),
      'teacherID': teacherId,
      'joinCode': _generateCode(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudentEnrollments(String studentId) =>
      _db.collection(Col.enrollments).where('studentID', isEqualTo: studentId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchClassEnrollments(String classId) =>
      _db.collection(Col.enrollments).where('classID', isEqualTo: classId).snapshots();
}
