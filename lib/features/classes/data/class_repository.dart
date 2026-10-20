import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class ClassRepository {
  ClassRepository(this._db);
  final FirebaseFirestore _db;

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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeacherClasses(String teacherId) =>
      _db.collection(Col.classes).where('teacherID', isEqualTo: teacherId).snapshots();

  /// Enrollment doc id is `classId_studentId`, so a student can join a class only once.
  Future<void> joinByCode({required String code, required String studentId}) async {
    final q = await _db
        .collection(Col.classes)
        .where('joinCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (q.docs.isEmpty) throw Exception('Invalid class code');
    final classId = q.docs.first.id;
    await _db.collection(Col.enrollments).doc('${classId}_$studentId').set({
      'classID': classId,
      'studentID': studentId,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudentEnrollments(String studentId) =>
      _db.collection(Col.enrollments).where('studentID', isEqualTo: studentId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchClassEnrollments(String classId) =>
      _db.collection(Col.enrollments).where('classID', isEqualTo: classId).snapshots();
}
