import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/entities/task.dart';

class FirestoreTaskDatasource {
  FirestoreTaskDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  /// Stream reativa ordenada por data de criação (mais recentes primeiro).
  Stream<List<Task>> watchTasks(String uid) => _collection(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList(),
      );

  Future<void> create(String uid, Task task) =>
      _collection(uid).doc(task.id).set(task.toMap());

  Future<void> update(String uid, Task task) =>
      _collection(uid).doc(task.id).update(task.toMap());

  Future<void> delete(String uid, String taskId) =>
      _collection(uid).doc(taskId).delete();
}
