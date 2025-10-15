import 'package:firebase_auth/firebase_auth.dart';

/// A service class to handle all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of the current authenticated user.
  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates a new user with email and password.
  /// Throws a FirebaseAuthException on failure (e.g., email already in use).
  Future<User?> signUp(
      {required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  /// Signs in an existing user with email and password.
  /// Throws a FirebaseAuthException on failure (e.g., wrong password).
  Future<User?> signIn(
      {required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
