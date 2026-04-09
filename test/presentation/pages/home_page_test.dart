import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/core/entities/app_user.dart';
import 'package:senior_ease/core/entities/task.dart';
import 'package:senior_ease/core/repositories/auth_repository.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/home_page.dart';
import 'package:senior_ease/presentation/providers/auth_provider.dart';
import 'package:senior_ease/presentation/providers/tasks_provider.dart';
import 'package:senior_ease/presentation/providers/tutorial_seen_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Notifier que já inicia com tutorial "visto" para não disparar o coach mark
class _TutorialAlreadySeen extends TutorialSeenNotifier {
  @override
  bool build() => true;
}

final _fakeUser = AppUser(
  uid: 'test-uid',
  email: 'joao@email.com',
  displayName: 'João',
  createdAt: DateTime(2025, 1, 1),
);

final _pendingTasks = <Task>[
  Task.create(
    id: 'task-1',
    title: 'Reunião às 14h',
    priority: TaskPriority.high,
    userId: 'test-uid',
    dueDate: DateTime.now().add(const Duration(hours: 2)),
  ),
  Task.create(
    id: 'task-2',
    title: 'Tomar remédio',
    priority: TaskPriority.medium,
    userId: 'test-uid',
  ),
  Task.create(
    id: 'task-3',
    title: 'Passear no parque',
    priority: TaskPriority.low,
    userId: 'test-uid',
  ),
];

Widget _buildTestApp({List<Task> tasks = const []}) {
  final testRouter = GoRouter(
    initialLocation: '/home',
    routes: [GoRoute(path: '/home', builder: (_, _) => const HomePage())],
  );

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(testRouter),
      authStateProvider.overrideWith((_) => Stream.value(_fakeUser)),
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      tasksProvider.overrideWith((_) => Stream.value(tasks)),
      // Desabilita o tutorial para não interferir nos testes
      tutorialSeenProvider.overrideWith(_TutorialAlreadySeen.new),
    ],
    child: const SeniorEaseApp(),
  );
}

void main() {
  group('HomePage - lista vazia', () {
    testWidgets('exibe saudação e estado vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      expect(find.text('Olá, João'), findsOneWidget);
      expect(find.text('Nova tarefa'), findsOneWidget);
    });
  });

  group('HomePage - com tarefas', () {
    testWidgets('exibe todas as tarefas pendentes', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump();

      expect(find.text('Reunião às 14h'), findsOneWidget);
      expect(find.text('Tomar remédio'), findsOneWidget);
      expect(find.text('Passear no parque'), findsOneWidget);
    });

    testWidgets('não exibe tarefas concluídas', (tester) async {
      final mixed = <Task>[
        ..._pendingTasks,
        Task.create(
          id: 'task-done',
          title: 'Tarefa concluída',
          priority: TaskPriority.low,
          userId: 'test-uid',
        ).copyWith(completed: true),
      ];

      await tester.pumpWidget(_buildTestApp(tasks: mixed));
      await tester.pump();

      expect(find.text('Tarefa concluída'), findsNothing);
      expect(find.text('Reunião às 14h'), findsOneWidget);
    });

    testWidgets('FAB "Nova tarefa" está presente', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Nova tarefa'), findsOneWidget);
    });
  });

  group('HomePage - interação', () {
    testWidgets('FAB abre bottom sheet de criação', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump(); // espera o primeiro frame renderizar

      await tester.tap(find.text('Nova tarefa'));
      await tester.pumpAndSettle(); // espera animação do bottom sheet completar

      // O bottom sheet de criação deve ter o campo de título
      expect(find.text('O que precisa fazer?'), findsOneWidget);
    });
  });

  // ─── Acessibilidade ───

  group('Acessibilidade - HomePage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA', (tester) async {
      await tester.pumpWidget(_buildTestApp(tasks: _pendingTasks));
      await tester.pump();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
