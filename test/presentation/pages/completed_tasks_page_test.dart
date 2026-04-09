import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/core/entities/task.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/completed_tasks_page.dart';
import 'package:senior_ease/presentation/providers/tasks_provider.dart';

// ─── Dados fake ───

final _completedTasks = <Task>[
  Task.create(
    id: 'task-1',
    title: 'Comprar remédio',
    priority: TaskPriority.high,
    userId: 'test-uid',
  ).copyWith(completed: true),
  Task.create(
    id: 'task-2',
    title: 'Ligar pro médico',
    priority: TaskPriority.medium,
    userId: 'test-uid',
  ).copyWith(completed: true),
  Task.create(
    id: 'task-3',
    title: 'Passear no parque',
    priority: TaskPriority.low,
    userId: 'test-uid',
  ).copyWith(completed: true),
];

Widget _buildTestApp({List<Task> tasks = const []}) {
  final testRouter = GoRouter(
    initialLocation: '/concluidas',
    routes: [
      GoRoute(
        path: '/concluidas',
        builder: (_, _) => const CompletedTasksPage(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(testRouter),
      // Sobrescreve o stream de tarefas com dados fake
      tasksProvider.overrideWith((_) => Stream.value(tasks)),
    ],
    child: const SeniorEaseApp(),
  );
}

void main() {
  group('CompletedTasksPage - lista vazia', () {
    testWidgets('exibe mensagem quando não há tarefas concluídas', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      expect(find.text('Tarefas concluídas'), findsOneWidget);
      expect(find.text('Nenhuma tarefa concluída ainda'), findsOneWidget);
    });
  });

  group('CompletedTasksPage - com tarefas', () {
    testWidgets('exibe todas as tarefas concluídas', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(tasks: _completedTasks),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      expect(find.text('Comprar remédio'), findsOneWidget);
      expect(find.text('Ligar pro médico'), findsOneWidget);
      expect(find.text('Passear no parque'), findsOneWidget);
    });

    testWidgets('cada tarefa tem checkbox marcado', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _completedTasks));
      await tester.pump();

      // 3 tarefas = 3 checkboxes marcados
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('cada tarefa tem botão de excluir', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _completedTasks));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('ignora tarefas pendentes (não concluídas)', (tester) async {
      final mixed = <Task>[
        Task.create(
          id: 'task-p',
          title: 'Pendente',
          priority: TaskPriority.low,
          userId: 'test-uid',
        ),
        ..._completedTasks,
      ];

      await tester.pumpWidget(_buildTestApp(tasks: mixed));
      await tester.pump();

      // A pendente NÃO deve aparecer
      expect(find.text('Pendente'), findsNothing);
      // As concluídas sim
      expect(find.text('Comprar remédio'), findsOneWidget);
    });
  });

  // ─── Acessibilidade ───

  group('Acessibilidade - CompletedTasksPage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _completedTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _completedTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _completedTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
