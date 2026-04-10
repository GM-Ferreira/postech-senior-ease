import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/core/entities/user_preferences.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/onboarding_page.dart';
import 'package:senior_ease/presentation/providers/user_preferences_provider.dart';

/// Restaura o tamanho da tela ao final do teste.
void addTeardownSize(WidgetTester tester) {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Notifier que retorna prefs defaults sem ir ao Firestore.
class _FakeUserPreferencesNotifier extends UserPreferencesNotifier {
  @override
  Future<UserPreferences> build() async => UserPreferences.defaults();

  @override
  Future<void> save(UserPreferences preferences) async {
    state = AsyncData(preferences);
  }
}

Widget _buildTestApp() {
  final testRouter = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(testRouter),
      userPreferencesProvider.overrideWith(_FakeUserPreferencesNotifier.new),
    ],
    child: const SeniorEaseApp(),
  );
}

void main() {
  // ─── Renderização ───

  group('OnboardingPage - renderização', () {
    testWidgets('exibe etapa 1 com título e opções de texto', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pumpAndSettle(); // espera animações e frames pendentes

      expect(find.text('Tamanho do texto'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Grande'), findsOneWidget);
      expect(find.text('Muito grande'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
    });

    testWidgets('navega para etapa 2 ao clicar Próximo', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pumpAndSettle(); // espera animações e frames pendentes

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle(); // espera animação de transição completar

      expect(find.text('Aparência'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Contraste'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
    });

    testWidgets('navega para etapa 3 (confirmação)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTeardownSize(tester); // restaura tamanho da tela ao final do teste

      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pumpAndSettle(); // espera animações e frames pendentes

      // Etapa 1 → 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle(); // espera animação de transição completar

      // Etapa 2 → 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle(); // espera animação de transição completar

      expect(find.text('Tudo pronto!'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Texto'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Contraste'), findsOneWidget);
    });

    testWidgets('botão Voltar retorna à etapa anterior', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Vai para etapa 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Aparência'), findsOneWidget);

      // Volta para etapa 1
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Tamanho do texto'), findsOneWidget);
    });
  });

  // ─── Interações ───

  group('OnboardingPage - interações', () {
    testWidgets('selecionar tamanho de texto muda opção', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTeardownSize(tester); // restaura tamanho da tela ao final do teste

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Default é 1.3 (Grande). Trocar para Muito grande.
      await tester.tap(find.text('Muito grande'));
      await tester.pumpAndSettle();

      // Avançar até confirmação para verificar
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Muito grande'), findsOneWidget);
    });

    testWidgets('selecionar tema Escuro aparece na confirmação', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTeardownSize(tester); // restaura tamanho da tela ao final do teste

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Etapa 1 → 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Selecionar tema Escuro
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      // Etapa 2 → 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('selecionar contraste Reforçado aparece na confirmação', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTeardownSize(tester); // restaura tamanho da tela ao final do teste

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Etapa 1 → 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Selecionar contraste Reforçado
      await tester.tap(find.text('Reforçado'));
      await tester.pumpAndSettle();

      // Etapa 2 → 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Reforçado'), findsOneWidget);
    });

    testWidgets('Começar salva preferências', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTeardownSize(tester);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Navegar até etapa 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Clicar em Começar
      await tester.tap(find.text('Começar'));
      await tester.pump();

      // Verifica que o provider foi atualizado com onboardingCompleted = true
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingPage)),
      );

      final prefs = container.read(userPreferencesProvider).asData?.value;

      expect(prefs?.onboardingCompleted, true);
    });
  });

  // ─── Acessibilidade ───

  group('OnboardingPage - acessibilidade', () {
    testWidgets('atende tap target Android (48x48dp)', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis têm label', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG AA (4.5:1)', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
