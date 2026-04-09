import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/core/entities/app_user.dart';
import 'package:senior_ease/core/repositories/auth_repository.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/settings_page.dart';
import 'package:senior_ease/presentation/providers/auth_provider.dart';
import 'package:senior_ease/presentation/providers/basic_mode_provider.dart';
import 'package:senior_ease/presentation/providers/contrast_provider.dart';
import 'package:senior_ease/presentation/providers/font_scale_provider.dart';
import 'package:senior_ease/presentation/providers/theme_provider.dart';
import 'package:senior_ease/presentation/providers/user_preferences_provider.dart';
import 'package:senior_ease/core/entities/user_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Notifier que retorna prefs defaults sem ir ao Firestore.
class _FakeUserPreferencesNotifier extends UserPreferencesNotifier {
  @override
  Future<UserPreferences> build() async => UserPreferences.defaults();

  @override
  Future<void> save(UserPreferences preferences) async {
    state = AsyncData(preferences);
  }
}

final _fakeUser = AppUser(
  uid: 'test-uid',
  email: 'joao@email.com',
  displayName: 'João',
  createdAt: DateTime(2025, 1, 1),
);

Widget _buildTestApp() {
  final testRouter = GoRouter(
    initialLocation: '/configuracoes',
    routes: [
      GoRoute(path: '/configuracoes', builder: (_, _) => const SettingsPage()),
    ],
  );

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(testRouter),
      authStateProvider.overrideWith((_) => Stream.value(_fakeUser)),
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      userPreferencesProvider.overrideWith(_FakeUserPreferencesNotifier.new),
    ],
    child: const SeniorEaseApp(),
  );
}

/// Helper: rola a lista até o widget existir na árvore (lazy ListView),
/// depois garante posicionamento correto para test.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Helper: rola até o widget, garante visibilidade e toca.
Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  // ─── Renderização ─────────────────────────────────────────────────────
  group('SettingsPage - renderização', () {
    testWidgets('exibe AppBar e seções visíveis no topo', (tester) async {
      await tester.pumpWidget(_buildTestApp()); // renderiza árvore em memória
      await tester.pumpAndSettle(); // aguarda animações e frames pendentes

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Tamanho do texto'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
    });

    testWidgets('exibe todas as seções ao rolar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      for (final title in [
        'Contraste',
        'Espaçamento',
        'Animações',
        'Modo de exibição',
        'Feedback visual',
        'Segurança',
      ]) {
        await _scrollTo(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('exibe botão de restaurar padrões', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Restaurar padrões'));
      expect(find.text('Restaurar padrões'), findsOneWidget);
    });
  });

  // ─── Tamanho do texto ─────────────────────────────────────────────────
  group('SettingsPage - tamanho do texto', () {
    testWidgets('exibe opções Normal, Grande e Muito grande', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Grande'), findsOneWidget);
      expect(find.text('Muito grande'), findsOneWidget);
    });

    testWidgets('selecionar "Muito grande" atualiza o provider de fonte', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Default fontScale=1.2 já mapeia para "Grande" (1.3), então
      // selecionamos "Muito grande" para garantir que houve mudança.
      final finder = find.widgetWithText(RadioListTile<double>, 'Muito grande');
      await _scrollAndTap(tester, finder);

      final container = ProviderScope.containerOf(
        tester.element(find.text('Configurações')),
      ); // Obtém o container para ler os providers

      expect(container.read(fontScaleProvider), 1.6);
    });
  });

  // ─── Tema ─────────────────────────────────────────────────────────────
  group('SettingsPage - tema', () {
    testWidgets('exibe Automático, Claro e Escuro', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('selecionar "Escuro" atualiza o provider de tema', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(RadioListTile<ThemeMode>, 'Escuro');
      await _scrollAndTap(tester, finder);

      final container = ProviderScope.containerOf(
        tester.element(find.text('Configurações')),
      );
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  // ─── Contraste ────────────────────────────────────────────────────────
  group('SettingsPage - contraste', () {
    testWidgets('exibe Normal, Reforçado e Muito alto', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Reforçado'));
      expect(find.text('Reforçado'), findsOneWidget);
      expect(find.text('Muito alto'), findsOneWidget);
    });

    testWidgets('selecionar "Reforçado" atualiza o provider de contraste', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(
        RadioListTile<ContrastLevel>,
        'Reforçado',
      );
      await _scrollAndTap(tester, finder);

      final container = ProviderScope.containerOf(
        tester.element(find.text('Configurações')),
      );
      expect(container.read(contrastLevelProvider), ContrastLevel.high);
    });
  });

  // ─── Espaçamento ──────────────────────────────────────────────────────
  group('SettingsPage - espaçamento', () {
    testWidgets('exibe Compacto, Normal e Espaçado', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Compacto'));
      expect(find.text('Compacto'), findsOneWidget);
      expect(find.text('Espaçado'), findsOneWidget);
    });

    testWidgets('exibe preview de espaçamento com tarefas exemplo', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Reunião às 14h'));
      expect(find.text('Reunião às 14h'), findsOneWidget);
      expect(find.text('Tomar remédio'), findsOneWidget);
      expect(find.text('Consulta médica'), findsWidgets);
    });
  });

  // ─── Animações ────────────────────────────────────────────────────────
  group('SettingsPage - animações', () {
    testWidgets('switch "Reduzir animações" inicia desligado e pode ligar', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(SwitchListTile, 'Reduzir animações');

      await _scrollTo(tester, finder);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();

      var switchWidget = tester.widget<SwitchListTile>(finder);

      expect(switchWidget.value, isFalse);

      await tester.tap(finder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget<SwitchListTile>(finder);

      expect(switchWidget.value, isTrue);
    });
  });

  // ─── Modo de exibição ─────────────────────────────────────────────────
  group('SettingsPage - modo de exibição', () {
    testWidgets('switch "Modo básico" alterna e muda preview', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(SwitchListTile, 'Modo básico');
      await _scrollTo(tester, finder);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();

      expect(find.text('Prévia — Modo avançado'), findsOneWidget);

      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.text('Prévia — Modo básico'), findsOneWidget);
    });
  });

  // ─── Feedback visual ──────────────────────────────────────────────────
  group('SettingsPage - feedback visual', () {
    testWidgets('switch "Feedback reforçado" inicia desligado', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(SwitchListTile, 'Feedback reforçado');
      await _scrollTo(tester, finder);

      final switchWidget = tester.widget<SwitchListTile>(finder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('preview normal mostra SnackBar ao tocar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(OutlinedButton, 'Tarefa concluída!');
      await _scrollAndTap(tester, btn);

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('preview reforçado mostra dialog ao tocar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Liga feedback reforçado
      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Feedback reforçado',
      );
      await _scrollAndTap(tester, switchFinder);

      // Toca no botão preview
      final btn = find.widgetWithText(OutlinedButton, 'Tarefa concluída!');
      await _scrollAndTap(tester, btn);

      expect(find.text('Parabéns! Continue assim.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Parabéns! Continue assim.'), findsNothing);
    });
  });

  // ─── Segurança ────────────────────────────────────────────────────────
  group('SettingsPage - segurança', () {
    testWidgets('switch "Confirmar antes de excluir" alterna', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final finder = find.widgetWithText(
        SwitchListTile,
        'Confirmar antes de excluir',
      );
      await _scrollTo(tester, finder);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();

      var switchWidget = tester.widget<SwitchListTile>(finder);
      expect(switchWidget.value, isFalse);

      await tester.tap(finder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget<SwitchListTile>(finder);
      expect(switchWidget.value, isTrue);
    });
  });

  // ─── Restaurar padrões ────────────────────────────────────────────────
  group('SettingsPage - restaurar padrões', () {
    testWidgets('abre dialog de confirmação', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _scrollAndTap(tester, find.text('Restaurar padrões'));

      expect(
        find.text(
          'Tem certeza? Todas as suas configurações de acessibilidade voltarão ao padrão.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Restaurar'), findsOneWidget);
    });

    testWidgets('cancelar fecha dialog sem alterar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.text('Configurações')),
      );

      // Liga "Modo básico"
      final modoBasico = find.widgetWithText(SwitchListTile, 'Modo básico');
      await _scrollAndTap(tester, modoBasico);
      expect(container.read(basicModeProvider), isTrue);

      // Abre dialog de restaurar → cancela
      await _scrollAndTap(tester, find.text('Restaurar padrões'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Modo básico continua ligado (verifica via provider)
      expect(container.read(basicModeProvider), isTrue);
    });

    testWidgets('confirmar restaura todos os valores padrão', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.text('Configurações')),
      );

      // Liga "Modo básico"
      final modoBasico = find.widgetWithText(SwitchListTile, 'Modo básico');
      await _scrollAndTap(tester, modoBasico);
      expect(container.read(basicModeProvider), isTrue);

      // Restaurar padrões → confirma
      await _scrollAndTap(tester, find.text('Restaurar padrões'));
      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();

      // Provider voltou ao padrão (false)
      expect(container.read(basicModeProvider), isFalse);
    });
  });

  // ─── Acessibilidade ──────────────────────────────────────────────────
  group('Acessibilidade - SettingsPage', () {
    testWidgets('atende tap target Android (48x48)', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('todos os elementos tocáveis possuem label semântico', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('contraste de texto atende WCAG', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
