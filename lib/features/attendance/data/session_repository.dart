import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';

/// A quiz question as sent by the teacher when starting a quiz session.
class QuizQuestionInput {
  const QuizQuestionInput({
    required this.text,
    required this.options,
    required this.correctIndex,
  });
  final String text;
  final List<String> options; // exactly 4
  final int correctIndex; // 0..3

  Map<String, dynamic> toMap() =>
      {'text': text, 'options': options, 'correctIndex': correctIndex};
}

class SessionRepository {
  SessionRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Session creation goes through a Cloud Function so start/expiry times come from the server.
  /// Returns the new session id.
  Future<String> startSession({
    required String classId,
    required String mode, // Modes.punchIn | Modes.quiz
    required double latitude,
    required double longitude,
    required int radius,
    List<QuizQuestionInput>? questions,
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

  /// Active sessions for the classes a student is enrolled in.
  /// Firestore `whereIn` accepts at most 30 ids.
  /// Students see sessions even when far away (assignment rule). Filter expired ones on the client.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveSessions(List<String> classIds) =>
      _db
          .collection(Col.sessions)
          .where('classID', whereIn: classIds.take(30).toList())
          .where('status', isEqualTo: 'active')
          .snapshots();

  /// Quiz questions WITHOUT the correct answers (those live in a teacher-only doc).
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
