import '../entities/user_preferences.dart';

abstract class UserPreferencesRepository {
  /// Carrega as preferências do usuário pelo [uid].
  /// Retorna [UserPreferences.defaults()] se não existir documento.
  Future<UserPreferences> load(String uid);

  /// Salva as preferências do usuário no Firestore.
  Future<void> save(String uid, UserPreferences preferences);
}
