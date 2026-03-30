import '../../core/entities/app_user.dart';
import '../../core/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Stream<AppUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  Future<AppUser?> get currentUser async => _datasource.currentUser;

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _datasource.signInWithEmail(email, password);

  @override
  Future<AppUser> signUpWithEmail(String email, String password) =>
      _datasource.signUpWithEmail(email, password);

  @override
  Future<AppUser> signInWithGoogle() => _datasource.signInWithGoogle();

  @override
  Future<void> sendPasswordReset(String email) =>
      _datasource.sendPasswordReset(email);

  @override
  Future<void> signOut() => _datasource.signOut();
}
