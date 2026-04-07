import '../../core/entities/task.dart';
import '../../core/repositories/task_repository.dart';
import '../datasources/firestore_task_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._datasource);

  final FirestoreTaskDatasource _datasource;

  @override
  Stream<List<Task>> watchTasks(String uid) => _datasource.watchTasks(uid);

  @override
  Future<void> create(String uid, Task task) => _datasource.create(uid, task);

  @override
  Future<void> update(String uid, Task task) => _datasource.update(uid, task);

  @override
  Future<void> delete(String uid, String taskId) =>
      _datasource.delete(uid, taskId);
}
