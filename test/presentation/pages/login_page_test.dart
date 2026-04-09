import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/login_page.dart';

// Helper: cria o app com o router apontando para a LoginPage.
// Evita depender do Firebase nos testes.
Widget _buildTestApp() {
  final testRouter = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/cadastro', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/recuperar-senha', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [appRouterProvider.overrideWithValue(testRouter)],
    child: const SeniorEaseApp(),
  );
}

void main() {
  // ─── Renderização ───

  group('LoginPage - renderização', () {
    // Verifica que os elementos visuais principais aparecem na tela
    testWidgets('exibe título, subtítulo e campos do formulário', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Textos principais
      expect(find.text('SeniorEase'), findsOneWidget);
      expect(find.text('Acesse sua conta'), findsOneWidget);

      // Campos do formulário
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);

      // Botões
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });
  });

  // ─── Validação do formulário ───

  group('LoginPage - validação', () {
    // Ao clicar "Entrar" sem preencher, deve mostrar mensagens de erro
    testWidgets('mostra erros ao submeter formulário vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Toca no botão "Entrar" sem preencher nada
      await tester.tap(find.text('Entrar'));
      await tester.pump(); // re-renderiza para mostrar os erros

      // Mensagens de validação devem aparecer
      expect(find.text('Informe seu email'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('mostra erro para email inválido', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Digita um email sem @
      await tester.enterText(find.byType(TextFormField).first, 'emailinvalido');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('mostra erro para senha curta', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Digita email válido
      await tester.enterText(
        find.byType(TextFormField).first,
        'teste@email.com',
      );
      // Digita senha com menos de 6 caracteres
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(
        find.text('A senha deve ter pelo menos 6 caracteres'),
        findsOneWidget,
      );
    });
  });

  // ─── Interação ───

  group('LoginPage - interação', () {
    // O botão de olho deve alternar a visibilidade da senha
    testWidgets('toggle de visibilidade da senha funciona', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Inicialmente a senha está oculta — ícone de "mostrar" está visível
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Toca no ícone de visibilidade
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump(); // re-renderiza para mostrar a mudança

      // Agora o ícone mudou para "ocultar"
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });
  });
}
