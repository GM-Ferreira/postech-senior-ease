import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/entities/user_preferences.dart';

class FirestoreUserPreferencesDatasource {
  FirestoreUserPreferencesDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('preferences')
      .doc('settings');

  Future<UserPreferences> load(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return UserPreferences.defaults();
    }
    return UserPreferences.fromMap(snapshot.data()!);
  }

  Future<void> save(String uid, UserPreferences preferences) =>
      _doc(uid).set(preferences.toMap());
}
