import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/core/entities/app_user.dart';
import 'package:senior_ease/core/repositories/auth_repository.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/profile_page.dart';
import 'package:senior_ease/presentation/providers/auth_provider.dart';

// ─── Mock do AuthRepository ───
// mocktail gera automaticamente stubs para todos os métodos da interface.
class MockAuthRepository extends Mock implements AuthRepository {}

// Usuário fake para os testes — não precisa do Firebase
final _fakeUser = AppUser(
  uid: 'test-uid-123',
  email: 'joao@email.com',
  displayName: 'João Silva',
  photoUrl: null,
  createdAt: DateTime(2025, 1, 15),
);

Widget _buildTestApp({AppUser? user, MockAuthRepository? authRepo}) {
  final mockAuth = authRepo ?? MockAuthRepository();
  final testUser = user ?? _fakeUser;

  final testRouter = GoRouter(
    initialLocation: '/perfil',
    routes: [
      GoRoute(path: '/perfil', builder: (_, _) => const ProfilePage()),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(testRouter),
      // Sobrescreve o stream de auth → emite o usuário fake
      authStateProvider.overrideWith((_) => Stream.value(testUser)),
      // Sobrescreve o repositório → mock sem Firebase
      authRepositoryProvider.overrideWithValue(mockAuth),
    ],
    child: const SeniorEaseApp(),
  );
}

void main() {
  group('ProfilePage - renderização com usuário logado', () {
    testWidgets('exibe nome, email e data de criação', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('João Silva'), findsAtLeast(1));
      expect(find.text('joao@email.com'), findsAtLeast(1));
      expect(find.text('15/01/2025'), findsOneWidget);
    });

    testWidgets('exibe botões de editar nome e sair', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      expect(find.text('Editar nome'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
    });

    testWidgets('exibe "Não informado" quando nome é null', (tester) async {
      final userSemNome = AppUser(
        uid: 'test-uid',
        email: 'sem@nome.com',
        displayName: null,
        createdAt: DateTime(2025, 6, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(user: userSemNome),
      ); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      expect(find.text('Não informado'), findsOneWidget);
      expect(find.text('sem@nome.com'), findsAtLeast(1));
    });
  });

  group('ProfilePage - interação', () {
    testWidgets('botão "Editar nome" abre dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await tester.ensureVisible(find.text('Editar nome'));
      await tester.tap(find.text('Editar nome'));
      await tester.pumpAndSettle(); // espera animação do dialog completar

      // Dialog apareceu — botão do formulário e título do dialog
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('dialog valida nome vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await tester.ensureVisible(find.text('Editar nome'));
      await tester.tap(find.text('Editar nome'));
      await tester.pumpAndSettle(); // espera animação do dialog completar

      // Limpa o campo e tenta salvar
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Informe um nome'), findsOneWidget);
    });

    testWidgets('botão "Sair da conta" chama signOut', (tester) async {
      final mockAuth = MockAuthRepository();

      // Configura o mock para aceitar a chamada signOut()
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildTestApp(authRepo: mockAuth),
      ); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle(); // espera animação do dialog completar

      // Verifica que signOut() foi chamado exatamente 1 vez
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  // ─── Acessibilidade ───

  group('Acessibilidade - ProfilePage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester
          .pump(); // espera o primeiro frame renderizar com dados do user

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
