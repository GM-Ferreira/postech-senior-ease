import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/forgot_password_page.dart';

Widget _buildTestApp() {
  final testRouter = GoRouter(
    initialLocation: '/recuperar-senha',
    routes: [
      GoRoute(
        path: '/recuperar-senha',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [appRouterProvider.overrideWithValue(testRouter)],
    child: const SeniorEaseApp(),
  );
}

void main() {
  group('ForgotPasswordPage - renderização', () {
    testWidgets('exibe título, descrição, campo e botão', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      expect(find.text('Recuperar Senha'), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(
        find.text(
          'Informe seu email e enviaremos um link para você criar uma nova senha.',
        ),
        findsOneWidget,
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enviar link de recuperação'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - validação', () {
    testWidgets('mostra erro ao submeter sem email', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Informe seu email'), findsOneWidget);
    });

    testWidgets('mostra erro para email inválido', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await tester.enterText(find.byType(TextFormField), 'semArroba');
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('erro desaparece ao corrigir o email', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Submete vazio para forçar erro
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump(); // re-renderiza para mostrar os erros
      expect(find.text('Informe seu email'), findsOneWidget);

      // Digita email inválido — troca de mensagem
      await tester.enterText(find.byType(TextFormField), 'invalido');
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Informe seu email'), findsNothing);
      expect(find.text('Email inválido'), findsOneWidget);
    });
  });
}
