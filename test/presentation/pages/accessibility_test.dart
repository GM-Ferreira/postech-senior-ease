import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/login_page.dart';
import 'package:senior_ease/presentation/pages/sign_up_page.dart';
import 'package:senior_ease/presentation/pages/forgot_password_page.dart';
import 'package:senior_ease/presentation/pages/splash_page.dart';

// ─── Helpers para montar cada página isolada ───

Widget _buildPageApp(String path, Widget page) {
  final testRouter = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (_, _) => page),
      // Rotas auxiliares para evitar erro de navegação
      GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
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
  // ═══════════════════════════════════════════════════════════════════
  // O Flutter oferece 3 guidelines de acessibilidade como matchers:
  //
  // 1. androidTapTargetGuideline
  //    → Todo elemento tocável deve ter pelo menos 48x48 dp
  //      (Material Design / Android)
  //
  // 2. iOSTapTargetGuideline
  //    → Todo elemento tocável deve ter pelo menos 44x44 dp (Apple HIG)
  //
  // 3. labeledTapTargetGuideline
  //    → Todo elemento tocável deve ter um label de acessibilidade
  //      (para leitores de tela como TalkBack / VoiceOver)
  //
  // 4. textContrastGuideline
  //    → Todo texto deve ter contraste ≥ 4.5:1 com o fundo (WCAG AA)
  //
  // Uso: expect(tester, meetsGuideline(guideline));
  // ═══════════════════════════════════════════════════════════════════

  // ─── SplashPage (trivial, sem dependências) ───

  group('Acessibilidade - SplashPage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('atende tap target iOS (44x44dp)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA (4.5:1)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // ─── LoginPage ───

  group('Acessibilidade - LoginPage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/login', const LoginPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('atende tap target iOS (44x44dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/login', const LoginPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/login', const LoginPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA (4.5:1)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/login', const LoginPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // ─── SignUpPage ───

  group('Acessibilidade - SignUpPage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/cadastro', const SignUpPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('atende tap target iOS (44x44dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/cadastro', const SignUpPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/cadastro', const SignUpPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA (4.5:1)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/cadastro', const SignUpPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // ─── ForgotPasswordPage ───

  group('Acessibilidade - ForgotPasswordPage', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/recuperar-senha', const ForgotPasswordPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('atende tap target iOS (44x44dp)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/recuperar-senha', const ForgotPasswordPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/recuperar-senha', const ForgotPasswordPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA (4.5:1)', (tester) async {
      await tester.pumpWidget(
        _buildPageApp('/recuperar-senha', const ForgotPasswordPage()),
      ); // renderiza árvore em memória
      await tester.pump(); // espera o primeiro frame renderizar

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
