import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/user_preferences.dart';
import '../../core/repositories/user_preferences_repository.dart';
import '../../data/datasources/firestore_user_preferences_datasource.dart';
import '../../data/repositories/user_preferences_repository_impl.dart';
import 'auth_provider.dart';

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _preferencesDatasourceProvider =
    Provider<FirestoreUserPreferencesDatasource>(
      (ref) =>
          FirestoreUserPreferencesDatasource(ref.watch(_firestoreProvider)),
    );

final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>(
  (ref) =>
      UserPreferencesRepositoryImpl(ref.watch(_preferencesDatasourceProvider)),
);

/// Carrega as preferências do usuário autenticado do Firestore.
/// Retorna [UserPreferences.defaults()] enquanto não há usuário autenticado.
class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    // Usa selectAsync para reagir APENAS ao UID, não ao user object inteiro.
    // Assim, mudanças de perfil (displayName, photoUrl) não invalidam as
    // preferências nem disparam recarregamento desnecessário do Firestore.
    final uid = await ref.watch(
      authStateProvider.selectAsync((user) => user?.uid),
    );

    if (uid == null) return UserPreferences.defaults();

    final repo = ref.read(userPreferencesRepositoryProvider);
    return repo.load(uid);
  }

  /// Persiste [preferences] no Firestore e atualiza o estado local.
  /// Aplica otimisticamente antes da resposta do servidor para a UI
  /// permanecer responsiva.
  Future<void> save(UserPreferences preferences) async {
    final user = await ref.read(authStateProvider.future);
    if (user == null) return;

    // Atualização otimista: a UI reflete a mudança imediatamente.
    state = AsyncData(preferences);

    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.save(user.uid, preferences);
  }
}

final userPreferencesProvider =
    AsyncNotifierProvider<UserPreferencesNotifier, UserPreferences>(
      UserPreferencesNotifier.new,
    );
