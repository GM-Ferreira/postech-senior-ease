import '../../core/entities/user_preferences.dart';
import '../../core/repositories/user_preferences_repository.dart';
import '../datasources/firestore_user_preferences_datasource.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  UserPreferencesRepositoryImpl(this._datasource);

  final FirestoreUserPreferencesDatasource _datasource;

  @override
  Future<UserPreferences> load(String uid) => _datasource.load(uid);

  @override
  Future<void> save(String uid, UserPreferences preferences) =>
      _datasource.save(uid, preferences);
}
