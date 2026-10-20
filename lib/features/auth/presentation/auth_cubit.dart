import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/error_messages.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, failed }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isBusy;
  final String? error;

  @override
  List<Object?> get props => [status, user, isBusy, error];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(AuthRepository repo)
      : _repo = repo,
        super(const AuthState());

  /// In-memory cubit for Design Preview. Never talks to Firebase.
  AuthCubit.preview({AppUser? user})
      : _repo = null,
        super(
          AuthState(
            status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
            user: user,
          ),
        );

  final AuthRepository? _repo;
  bool get _isPreview => _repo == null;

  Future<void> start() async {
    if (_isPreview) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      final user = await _repo!.fetchCurrentUser();
      emit(
        user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
      );
    } catch (e) {
      emit(AuthState(status: AuthStatus.failed, error: ErrorMessages.authStart(e)));
    }
  }

  Future<void> login(String email, String password) =>
      _run(() => _repo!.signIn(email, password));

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
  }) =>
      _run(
        () => _repo!.register(
          name: name,
          email: email,
          password: password,
          role: role,
          studentId: studentId,
        ),
      );

  Future<void> logout() async {
    if (!_isPreview) {
      await _repo!.signOut();
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _run(Future<AppUser> Function() action) async {
    if (_isPreview) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Preview mode: Firebase is not called.',
        ),
      );
      return;
    }
    emit(AuthState(status: state.status, user: state.user, isBusy: true));
    try {
      final user = await action();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, error: ErrorMessages.fromAuth(e)));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated, error: ErrorMessages.generic));
    }
  }
}
