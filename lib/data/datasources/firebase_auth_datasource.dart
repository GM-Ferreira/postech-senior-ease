import 'package:firebase_auth/firebase_auth.dart';

import '../../core/entities/app_user.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource(this._auth);

  final FirebaseAuth _auth;

  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Future<AppUser> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(credential);
  }

  Future<AppUser> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(credential);
  }

  Future<AppUser> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final credential = await _auth.signInWithPopup(provider);
    return _requireUser(credential);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  AppUser _requireUser(UserCredential credential) {
    final user = credential.user;
    if (user == null) throw Exception('Falha na autenticação');
    return _mapUser(user)!;
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
