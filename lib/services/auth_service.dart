import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────
//  AUTH SERVICE
//  A thin wrapper around Firebase Auth (email + password).
//
//  Exposes:
//    - authStateChanges  → a stream the gate listens to (logged in/out)
//    - currentUser       → the signed-in user, or null
//    - register()        → create account + set display name
//    - signIn()          → email/password login
//    - signOut()
//
//  Each method returns null on success, or a HEBREW error string on
//  failure (already user-friendly), so the screens can just show it.
//
//  No ChangeNotifier here — FirebaseAuth already gives us a stream
//  (authStateChanges), which is the idiomatic way to react to login
//  state. The gate in main.dart wraps the app in a StreamBuilder on it.
// ─────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of login state — emits the user (or null) on every change.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // The currently signed-in user, or null if logged out.
  User? get currentUser => _auth.currentUser;

  // Convenience: the display name, falling back gracefully.
  String get displayName {
    final n = _auth.currentUser?.displayName;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : 'מטייל';
  }

  // ── Register a new account ──────────────────────────────────────
  // Returns null on success, or a Hebrew error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Save the display name on the new user, then reload so
      // currentUser.displayName is populated immediately.
      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return _hebrewError(e.code);
    } catch (_) {
      return 'משהו השתבש. נסה שוב.';
    }
  }

  // ── Sign in ─────────────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _hebrewError(e.code);
    } catch (_) {
      return 'משהו השתבש. נסה שוב.';
    }
  }

  // ── Sign out ────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Map Firebase error codes to friendly Hebrew messages ────────
  String _hebrewError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'כתובת המייל אינה תקינה.';
      case 'user-disabled':
        return 'החשבון הזה הושבת.';
      case 'user-not-found':
        return 'לא נמצא משתמש עם המייל הזה.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'מייל או סיסמה שגויים.';
      case 'email-already-in-use':
        return 'כתובת המייל כבר רשומה במערכת.';
      case 'weak-password':
        return 'הסיסמה חלשה מדי (לפחות 6 תווים).';
      case 'network-request-failed':
        return 'אין חיבור לאינטרנט. בדוק את החיבור ונסה שוב.';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסה שוב מאוחר יותר.';
      default:
        return 'ההתחברות נכשלה. נסה שוב.';
    }
  }
}
