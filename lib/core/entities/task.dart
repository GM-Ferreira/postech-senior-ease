/// Prioridade da tarefa.
enum TaskPriority {
  high,
  medium,
  low;

  static TaskPriority fromString(String value) => switch (value) {
    'high' => high,
    'medium' => medium,
    _ => low,
  };

  String toSerializable() => name;

  String get label => switch (this) {
    high => 'Alta',
    medium => 'Média',
    low => 'Baixa',
  };
}

/// Entidade de domínio que representa uma tarefa do usuário.
/// Imutável — use [copyWith] para criar variações.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.completed,
    required this.createdAt,
    required this.userId,
    this.dueDate,
  });

  /// Cria uma nova tarefa com id e timestamps gerados automaticamente.
  factory Task.create({
    required String id,
    required String title,
    required TaskPriority priority,
    required String userId,
    DateTime? dueDate,
  }) => Task(
    id: id,
    title: title,
    priority: priority,
    completed: false,
    createdAt: DateTime.now(),
    userId: userId,
    dueDate: dueDate,
  );

  /// Reconstrói a entidade a partir de um Map (Firestore).
  factory Task.fromMap(String id, Map<String, dynamic> map) => Task(
    id: id,
    title: map['title'] as String? ?? '',
    priority: TaskPriority.fromString(map['priority'] as String? ?? ''),
    completed: map['completed'] as bool? ?? false,
    createdAt: map['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : DateTime.now(),
    userId: map['userId'] as String? ?? '',
    dueDate: map['dueDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
        : null,
  );

  final String id;
  final String title;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;
  final String userId;
  final DateTime? dueDate;

  /// Converte para Map para persistir no Firestore.
  Map<String, dynamic> toMap() => {
    'title': title,
    'priority': priority.toSerializable(),
    'completed': completed,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'userId': userId,
    if (dueDate != null) 'dueDate': dueDate!.millisecondsSinceEpoch,
  };

  Task copyWith({
    String? title,
    TaskPriority? priority,
    bool? completed,
    DateTime? dueDate,
  }) => Task(
    id: id,
    title: title ?? this.title,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed,
    createdAt: createdAt,
    userId: userId,
    dueDate: dueDate ?? this.dueDate,
  );
}
