import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import 'app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<AppUser?> fetchCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _db.collection(Col.users).doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<AppUser> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final user = await fetchCurrentUser();
    if (user == null) throw Exception('User profile not found');
    return user;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      id: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      studentId: role == Roles.student ? studentId?.trim() : null,
    );
    await _db.collection(Col.users).doc(user.id).set(user.toMap());
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
