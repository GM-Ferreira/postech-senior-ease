import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/sign_up_page.dart';

Widget _buildTestApp() {
  final testRouter = GoRouter(
    initialLocation: '/cadastro',
    routes: [
      GoRoute(path: '/cadastro', builder: (_, _) => const SignUpPage()),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [appRouterProvider.overrideWithValue(testRouter)],
    child: const SeniorEaseApp(),
  );
}

void main() {
  group('SignUpPage - renderização', () {
    testWidgets('exibe título, campos e botões', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      expect(find.text('Criar Conta'), findsOneWidget); // AppBar
      expect(find.text('Crie sua conta'), findsOneWidget);

      // 4 campos do formulário
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);

      // Botões
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Já tem conta?'), findsOneWidget);
      expect(find.text('Fazer login'), findsOneWidget);
    });
  });

  group('SignUpPage - validação', () {
    testWidgets('mostra erros ao submeter formulário vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe seu email'), findsOneWidget);
      expect(find.text('Informe uma senha'), findsOneWidget);
      expect(find.text('Confirme sua senha'), findsOneWidget);
    });

    testWidgets('mostra erro para email inválido', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'semArroba');
      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('mostra erro para senha curta', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), '123');
      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(
        find.text('A senha deve ter pelo menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('mostra erro quando senhas não coincidem', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'João');
      await tester.enterText(fields.at(1), 'joao@email.com');
      await tester.enterText(fields.at(2), '123456');
      await tester.enterText(fields.at(3), '654321');
      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('erro desaparece ao corrigir o campo', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Rola até o botão (o formulário longo empurra pra fora da tela)
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Informe seu nome'), findsOneWidget);

      // Corrige o nome e submete de novo — erro do nome some
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'João');
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump(); // re-renderiza para mostrar os erros

      expect(find.text('Informe seu nome'), findsNothing);
    });
  });

  group('SignUpPage - interação', () {
    testWidgets('toggle de visibilidade da senha funciona', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      // Dois ícones de visibilidade (senha + confirmar)
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

      // Toca no primeiro (campo senha)
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump(); // re-renderiza para mostrar a mudança

      // Agora: 1 olho aberto (confirmar) + 1 olho fechado (senha)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
