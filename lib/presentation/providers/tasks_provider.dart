import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/task.dart';
import '../../core/repositories/task_repository.dart';
import '../../data/datasources/firestore_task_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import 'auth_provider.dart';

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _taskDatasourceProvider = Provider<FirestoreTaskDatasource>(
  (ref) => FirestoreTaskDatasource(ref.watch(_firestoreProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(_taskDatasourceProvider)),
);

/// Stream reativo de tarefas do usuário autenticado.
/// Emite lista vazia se não houver usuário.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;

  if (user == null) return Stream.value([]);

  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks(user.uid);
});

/// Notifier para operações de escrita (criar, atualizar, excluir).
/// Separado do stream para manter a leitura reativa via Firestore.
class TaskActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  Future<String?> _getUid() async {
    final user = await ref.read(authStateProvider.future);
    return user?.uid;
  }

  Future<void> create(Task task) async {
    final uid = await _getUid();
    if (uid == null) return;
    await _repo.create(uid, task.copyWith(userId: uid));
  }

  Future<void> update(Task task) async {
    final uid = await _getUid();
    if (uid == null) return;
    await _repo.update(uid, task);
  }

  Future<void> toggleComplete(Task task) async {
    final uid = await _getUid();
    if (uid == null) return;
    await _repo.update(uid, task.copyWith(completed: !task.completed));
  }

  Future<void> delete(String taskId) async {
    final uid = await _getUid();
    if (uid == null) return;
    await _repo.delete(uid, taskId);
  }
}

final taskActionsProvider = NotifierProvider<TaskActionsNotifier, void>(
  TaskActionsNotifier.new,
);
