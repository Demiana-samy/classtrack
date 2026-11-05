import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import '../../quiz/data/models/quiz_question_model.dart';

class SessionRepository {
  SessionRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<String> startSession({
    required String classId,
    required String mode, 
    required double latitude,
    required double longitude,
    required int radius,
    List<QuizQuestionDraft>? questions,
  }) async {
    final res = await _functions.httpsCallable('startSession').call({
      'classId': classId,
      'mode': mode,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      if (questions != null) 'questions': questions.map((q) => q.toMap()).toList(),
    });
    return (res.data as Map)['sessionId'] as String;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSession(String sessionId) =>
      _db.collection(Col.sessions).doc(sessionId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveSessions(List<String> classIds) =>
      _db
          .collection(Col.sessions)
          .where('classID', whereIn: classIds.take(30).toList())
          .where('status', isEqualTo: 'active')
          .snapshots();

  Future<List<Map<String, dynamic>>> fetchQuestions(String sessionId) async {
    final q = await _db
        .collection(Col.sessions)
        .doc(sessionId)
        .collection('questions')
        .orderBy('order')
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessionHistory(String classId) => _db
      .collection(Col.sessions)
      .where('classID', isEqualTo: classId)
      .orderBy('startTime', descending: true)
      .snapshots();
}
