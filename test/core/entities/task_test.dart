import 'package:flutter_test/flutter_test.dart';
import 'package:senior_ease/core/entities/task.dart';

void main() {
  // ─── TaskPriority ───

  group('TaskPriority.fromString', () {
    // Testa se valores válidos retornam o enum correto
    test('retorna high para "high"', () {
      expect(TaskPriority.fromString('high'), TaskPriority.high);
    });

    test('retorna medium para "medium"', () {
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
    });

    test('retorna low para "low"', () {
      expect(TaskPriority.fromString('low'), TaskPriority.low);
    });

    // Testa o fallback: qualquer valor desconhecido deve cair em "low"
    test('retorna low como fallback para valor inválido', () {
      expect(TaskPriority.fromString('invalido'), TaskPriority.low);
      expect(TaskPriority.fromString(''), TaskPriority.low);
    });
  });

  group('TaskPriority.toSerializable', () {
    // Garante que serializa para o nome do enum (usado no Firestore)
    test('serializa para o nome do enum', () {
      expect(TaskPriority.high.toSerializable(), 'high');
      expect(TaskPriority.medium.toSerializable(), 'medium');
      expect(TaskPriority.low.toSerializable(), 'low');
    });
  });

  group('TaskPriority.label', () {
    // Testa os rótulos em português mostrados na UI
    test('retorna rótulo em português', () {
      expect(TaskPriority.high.label, 'Alta');
      expect(TaskPriority.medium.label, 'Média');
      expect(TaskPriority.low.label, 'Baixa');
    });
  });

  // ─── Task ───

  group('Task.create', () {
    // Task.create é a factory usada quando o usuário cria uma tarefa nova.
    // Ela deve definir completed=false e gerar createdAt automaticamente.
    test('cria tarefa com completed=false e createdAt preenchido', () {
      final antes = DateTime.now();
      final task = Task.create(
        id: '1',
        title: 'Estudar Flutter',
        priority: TaskPriority.high,
        userId: 'user123',
      );
      final depois = DateTime.now();

      expect(task.id, '1');
      expect(task.title, 'Estudar Flutter');
      expect(task.priority, TaskPriority.high);
      expect(task.userId, 'user123');
      expect(task.completed, false); // sempre começa não concluída
      expect(task.dueDate, isNull); // não passou dueDate
      // createdAt deve estar entre "antes" e "depois" da chamada
      expect(task.createdAt.isAfter(antes) || task.createdAt == antes, true);
      expect(task.createdAt.isBefore(depois) || task.createdAt == depois, true);
    });

    test('aceita dueDate opcional', () {
      final due = DateTime(2026, 12, 25);
      final task = Task.create(
        id: '2',
        title: 'Natal',
        priority: TaskPriority.low,
        userId: 'user123',
        dueDate: due,
      );

      expect(task.dueDate, due);
    });
  });

  group('Task.toMap / Task.fromMap', () {
    // toMap converte para o formato do Firestore.
    // fromMap reconstrói a entidade a partir do Firestore.
    // O "round-trip" garante que nada se perde na conversão.

    test('round-trip: toMap → fromMap preserva todos os campos', () {
      final original = Task(
        id: 'abc',
        title: 'Tarefa de teste',
        priority: TaskPriority.medium,
        completed: true,
        createdAt: DateTime(2026, 4, 8, 10, 30),
        userId: 'user456',
        dueDate: DateTime(2026, 5, 1),
      );

      // Converte para Map (como salva no Firestore)
      final map = original.toMap();

      // Reconstrói a partir do Map (como lê do Firestore)
      // Note: o id é passado separado (vem do document ID no Firestore)
      final reconstruida = Task.fromMap('abc', map);

      expect(reconstruida.id, original.id);
      expect(reconstruida.title, original.title);
      expect(reconstruida.priority, original.priority);
      expect(reconstruida.completed, original.completed);
      expect(reconstruida.createdAt, original.createdAt);
      expect(reconstruida.userId, original.userId);
      expect(reconstruida.dueDate, original.dueDate);
    });

    test('toMap omite dueDate quando é null', () {
      final task = Task(
        id: '1',
        title: 'Sem data',
        priority: TaskPriority.low,
        completed: false,
        createdAt: DateTime(2026, 1, 1),
        userId: 'user1',
      );

      final map = task.toMap();

      // O map NÃO deve conter a chave 'dueDate'
      expect(map.containsKey('dueDate'), false);
    });

    test('fromMap usa fallbacks quando campos estão ausentes', () {
      // Simula um documento do Firestore com dados incompletos
      final map = <String, dynamic>{};
      final task = Task.fromMap('id1', map);

      expect(task.id, 'id1');
      expect(task.title, ''); // fallback string vazia
      expect(task.priority, TaskPriority.low); // fallback do fromString
      expect(task.completed, false); // fallback false
      expect(task.userId, ''); // fallback string vazia
      expect(task.dueDate, isNull); // sem dueDate
    });
  });

  group('Task.copyWith', () {
    // copyWith cria uma cópia alterando só os campos desejados.
    // Importante: id e createdAt NUNCA mudam (são imutáveis da tarefa).

    final original = Task(
      id: 'x',
      title: 'Original',
      priority: TaskPriority.low,
      completed: false,
      createdAt: DateTime(2026, 1, 1),
      userId: 'user1',
      dueDate: DateTime(2026, 6, 1),
    );

    test('altera apenas o campo especificado', () {
      final alterada = original.copyWith(title: 'Alterada');

      expect(alterada.title, 'Alterada'); // mudou
      expect(alterada.id, original.id); // preservou
      expect(alterada.priority, original.priority); // preservou
      expect(alterada.completed, original.completed); // preservou
      expect(alterada.createdAt, original.createdAt); // preservou
    });

    test('altera prioridade mantendo demais campos', () {
      final alterada = original.copyWith(priority: TaskPriority.high);

      expect(alterada.priority, TaskPriority.high); // mudou
      expect(alterada.title, original.title); // preservou
      expect(alterada.dueDate, original.dueDate); // preservou
    });

    test('preserva id e createdAt sempre', () {
      final alterada = original.copyWith(
        title: 'Nova',
        priority: TaskPriority.high,
        completed: true,
        userId: 'outro',
      );

      expect(alterada.id, 'x'); // nunca muda
      expect(alterada.createdAt, DateTime(2026, 1, 1)); // nunca muda
    });
  });
}
