import '../entities/task.dart';

abstract class TaskRepository {
  /// Stream reativa de todas as tarefas do usuário, ordenadas por data de criação.
  Stream<List<Task>> watchTasks(String uid);

  /// Cria uma nova tarefa no Firestore.
  Future<void> create(String uid, Task task);

  /// Atualiza uma tarefa existente.
  Future<void> update(String uid, Task task);

  /// Exclui uma tarefa pelo [taskId].
  Future<void> delete(String uid, String taskId);
}
