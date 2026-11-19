import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import '../../quiz/data/models/quiz_question_model.dart';
import 'attendance_session.dart';

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

  /// Same as [watchSession] but mapped to a model. Emits null if the session does not exist.
  Stream<AttendanceSession?> watchSessionModel(String sessionId) =>
      watchSession(sessionId).map(
        (doc) => doc.exists ? AttendanceSession.fromMap(doc.id, doc.data()!) : null,
      );

  /// Quiz questions for students. They never contain the correct answer, so
  /// `correctIndex` is -1 here; the score is calculated by submitAttendance.
  Future<List<QuizQuestionDraft>> fetchQuizQuestions(String sessionId) async {
    final raw = await fetchQuestions(sessionId);
    return raw
        .map(
          (m) => QuizQuestionDraft(
            text: m['text'] as String? ?? '',
            options: List<String>.from(m['options'] as List? ?? const []),
            correctIndex: -1,
          ),
        )
        .toList();
  }

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
