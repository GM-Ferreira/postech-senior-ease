import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_ease/presentation/providers/font_scale_provider.dart';
import 'package:senior_ease/presentation/providers/spacing_provider.dart';
import 'package:senior_ease/presentation/providers/animations_provider.dart';
import 'package:senior_ease/presentation/providers/basic_mode_provider.dart';
import 'package:senior_ease/presentation/providers/enhanced_feedback_provider.dart';
import 'package:senior_ease/presentation/providers/confirm_actions_provider.dart';
import 'package:senior_ease/presentation/providers/tutorial_seen_provider.dart';
import 'package:senior_ease/presentation/providers/contrast_provider.dart';
import 'package:senior_ease/presentation/providers/theme_provider.dart';

void main() {
  // Para testar um Notifier do Riverpod, cria-se um ProviderContainer.
  // Ele funciona como um "mini-app" só para os providers, sem precisar de UI.

  // ─── FontScaleNotifier ───

  group('FontScaleNotifier', () {
    test('valor inicial é 1.0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(fontScaleProvider), 1.0);
    });

    test('setScale atualiza o valor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fontScaleProvider.notifier).setScale(1.8);
      expect(container.read(fontScaleProvider), 1.8);
    });

    test('setScale faz clamp entre 0.8 e 2.5', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Valor abaixo do mínimo → clamp em 0.8
      container.read(fontScaleProvider.notifier).setScale(0.1);
      expect(container.read(fontScaleProvider), 0.8);

      // Valor acima do máximo → clamp em 2.5
      container.read(fontScaleProvider.notifier).setScale(5.0);
      expect(container.read(fontScaleProvider), 2.5);
    });
  });

  // ─── SpacingScaleNotifier ───

  group('SpacingScaleNotifier', () {
    test('valor inicial é 1.0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(spacingScaleProvider), 1.0);
    });

    test('setScale atualiza o valor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(spacingScaleProvider.notifier).setScale(1.5);
      expect(container.read(spacingScaleProvider), 1.5);
    });

    test('setScale faz clamp entre 0.8 e 2.0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(spacingScaleProvider.notifier).setScale(0.1);
      expect(container.read(spacingScaleProvider), 0.8);

      container.read(spacingScaleProvider.notifier).setScale(10.0);
      expect(container.read(spacingScaleProvider), 2.0);
    });
  });

  // ─── ReduceAnimationsNotifier ───

  group('ReduceAnimationsNotifier', () {
    test('valor inicial é false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(reduceAnimationsProvider), false);
    });

    test('toggle inverte o estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reduceAnimationsProvider.notifier).toggle();
      expect(container.read(reduceAnimationsProvider), true);

      container.read(reduceAnimationsProvider.notifier).toggle();
      expect(container.read(reduceAnimationsProvider), false);
    });

    test('set define o valor diretamente', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reduceAnimationsProvider.notifier).set(reduce: true);
      expect(container.read(reduceAnimationsProvider), true);

      container.read(reduceAnimationsProvider.notifier).set(reduce: false);
      expect(container.read(reduceAnimationsProvider), false);
    });
  });

  // ─── BasicModeNotifier ───

  group('BasicModeNotifier', () {
    test('valor inicial é false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(basicModeProvider), false);
    });

    test('set altera o estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(basicModeProvider.notifier).set(enabled: true);
      expect(container.read(basicModeProvider), true);

      container.read(basicModeProvider.notifier).set(enabled: false);
      expect(container.read(basicModeProvider), false);
    });
  });

  // ─── EnhancedFeedbackNotifier ───

  group('EnhancedFeedbackNotifier', () {
    test('valor inicial é false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(enhancedFeedbackProvider), false);
    });

    test('set altera o estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(enhancedFeedbackProvider.notifier).set(enabled: true);
      expect(container.read(enhancedFeedbackProvider), true);
    });
  });

  // ─── ConfirmActionsNotifier ───

  group('ConfirmActionsNotifier', () {
    test('valor inicial é false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(confirmActionsProvider), false);
    });

    test('set altera o estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(confirmActionsProvider.notifier).set(enabled: true);
      expect(container.read(confirmActionsProvider), true);
    });
  });

  // ─── TutorialSeenNotifier ───

  group('TutorialSeenNotifier', () {
    test('valor inicial é false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tutorialSeenProvider), false);
    });

    test('set altera o estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(tutorialSeenProvider.notifier).set(seen: true);
      expect(container.read(tutorialSeenProvider), true);
    });
  });

  // ─── ContrastLevelNotifier ───

  group('ContrastLevelNotifier', () {
    test('valor inicial é normal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(contrastLevelProvider), ContrastLevel.normal);
    });

    test('setLevel altera o nível de contraste', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(contrastLevelProvider.notifier)
          .setLevel(ContrastLevel.high);
      expect(container.read(contrastLevelProvider), ContrastLevel.high);

      container
          .read(contrastLevelProvider.notifier)
          .setLevel(ContrastLevel.veryHigh);
      expect(container.read(contrastLevelProvider), ContrastLevel.veryHigh);
    });
  });

  // ─── ContrastLevel enum ───

  group('ContrastLevel enum', () {
    // Cada nível tem um valor numérico para calcular contraste
    test('valores numéricos corretos', () {
      expect(ContrastLevel.normal.value, 0.0);
      expect(ContrastLevel.high.value, 0.5);
      expect(ContrastLevel.veryHigh.value, 1.0);
    });
  });

  // ─── ThemeModeNotifier ───

  group('ThemeModeNotifier', () {
    test('valor inicial é ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode altera o modo de tema', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
