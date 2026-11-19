import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maps platform / Firebase errors to short, readable sentences for the UI.
class ErrorMessages {
  static const generic = 'Something went wrong. Please try again.';

  static String bootstrap(Object error) {
    final text = error.toString();
    if (error is UnimplementedError ||
        text.contains('flutterfire configure') ||
        text.contains('DefaultFirebaseOptions')) {
      return 'Firebase is not configured yet.\n\n'
          'Ask the team leader to run `flutterfire configure` '
          '(Android + iOS), then enable Email/Password in Authentication '
          'and create a Firestore database.';
    }
    if (text.contains('network') || text.contains('SocketException')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Could not start ClassTrack.\n\nCheck Firebase setup and your connection, then retry.';
  }

  static String authStart(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'unavailable' || error.code == 'network-request-failed') {
        return 'Could not reach the server. Check your internet connection and try again.';
      }
      return 'Could not load your account. Check your connection and try again.';
    }
    return 'Could not start sign-in. Please try again.';
  }

  /// Errors thrown by `startSession` / `submitAttendance` (functions/index.js).
  static String fromFunctions(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'already-exists':
        return 'A session is already running for this class.';
      case 'permission-denied':
        return e.message ?? 'You are not allowed to do that.';
      case 'unauthenticated':
        return 'Your login expired. Please log in again.';
      case 'invalid-argument':
        return e.message ?? 'Some session details are not valid.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Could not reach the server. Check your internet connection and try again.';
      case 'not-found':
        return 'The server function was not found. Ask the leader to deploy Cloud Functions.';
      default:
        return generic;
    }
  }

  static String fromAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address does not look valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a password with at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled on this Firebase project.';
      default:
        return 'Could not sign in. Please try again.';
    }
  }
}
