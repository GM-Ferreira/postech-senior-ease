import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_ease/core/entities/user_preferences.dart';

void main() {
  // ─── PreferencesContrastLevel ───

  group('PreferencesContrastLevel.fromString', () {
    test('retorna o enum correto para valores válidos', () {
      expect(
        PreferencesContrastLevel.fromString('high'),
        PreferencesContrastLevel.high,
      );
      expect(
        PreferencesContrastLevel.fromString('veryHigh'),
        PreferencesContrastLevel.veryHigh,
      );
      expect(
        PreferencesContrastLevel.fromString('normal'),
        PreferencesContrastLevel.normal,
      );
    });

    test('retorna normal como fallback para valor inválido', () {
      expect(
        PreferencesContrastLevel.fromString('invalido'),
        PreferencesContrastLevel.normal,
      );
      expect(
        PreferencesContrastLevel.fromString(''),
        PreferencesContrastLevel.normal,
      );
    });
  });

  group('PreferencesContrastLevel.toSerializable', () {
    test('serializa para o nome do enum', () {
      expect(PreferencesContrastLevel.normal.toSerializable(), 'normal');
      expect(PreferencesContrastLevel.high.toSerializable(), 'high');
      expect(PreferencesContrastLevel.veryHigh.toSerializable(), 'veryHigh');
    });
  });

  // ─── PreferencesThemeMode ───

  group('PreferencesThemeMode.fromString', () {
    test('retorna o enum correto para valores válidos', () {
      expect(
        PreferencesThemeMode.fromString('light'),
        PreferencesThemeMode.light,
      );
      expect(
        PreferencesThemeMode.fromString('dark'),
        PreferencesThemeMode.dark,
      );
      expect(
        PreferencesThemeMode.fromString('system'),
        PreferencesThemeMode.system,
      );
    });

    test('retorna system como fallback para valor inválido', () {
      expect(
        PreferencesThemeMode.fromString('invalido'),
        PreferencesThemeMode.system,
      );
      expect(PreferencesThemeMode.fromString(''), PreferencesThemeMode.system);
    });
  });

  group('PreferencesThemeMode.toSerializable', () {
    test('serializa para o nome do enum', () {
      expect(PreferencesThemeMode.light.toSerializable(), 'light');
      expect(PreferencesThemeMode.dark.toSerializable(), 'dark');
      expect(PreferencesThemeMode.system.toSerializable(), 'system');
    });
  });

  group('PreferencesThemeMode.toThemeMode', () {
    // Converte o enum do domínio para o ThemeMode do Flutter
    test('mapeia corretamente para ThemeMode do Flutter', () {
      expect(PreferencesThemeMode.light.toThemeMode(), ThemeMode.light);
      expect(PreferencesThemeMode.dark.toThemeMode(), ThemeMode.dark);
      expect(PreferencesThemeMode.system.toThemeMode(), ThemeMode.system);
    });
  });

  group('PreferencesThemeMode.fromThemeMode', () {
    // Converte o ThemeMode do Flutter de volta para o enum do domínio
    test('mapeia corretamente de ThemeMode do Flutter', () {
      expect(
        PreferencesThemeMode.fromThemeMode(ThemeMode.light),
        PreferencesThemeMode.light,
      );
      expect(
        PreferencesThemeMode.fromThemeMode(ThemeMode.dark),
        PreferencesThemeMode.dark,
      );
      expect(
        PreferencesThemeMode.fromThemeMode(ThemeMode.system),
        PreferencesThemeMode.system,
      );
    });
  });

  // ─── UserPreferences ───

  group('UserPreferences.defaults', () {
    // Verifica que os defaults são pensados para acessibilidade de idosos:
    // fonte maior (1.2), contraste normal, sem nada ativado no início
    test('retorna valores padrão acessíveis', () {
      final prefs = UserPreferences.defaults();

      expect(prefs.fontScale, 1.2);
      expect(prefs.contrastLevel, PreferencesContrastLevel.normal);
      expect(prefs.spacingScale, 1.0);
      expect(prefs.reduceAnimations, false);
      expect(prefs.themeMode, PreferencesThemeMode.system);
      expect(prefs.onboardingCompleted, false);
      expect(prefs.basicMode, false);
      expect(prefs.enhancedFeedback, false);
      expect(prefs.confirmCriticalActions, false);
      expect(prefs.tutorialSeen, false);
    });
  });

  group('UserPreferences.toMap / fromMap', () {
    test('round-trip: toMap → fromMap preserva todos os 10 campos', () {
      const original = UserPreferences(
        fontScale: 1.5,
        contrastLevel: PreferencesContrastLevel.veryHigh,
        spacingScale: 1.2,
        reduceAnimations: true,
        themeMode: PreferencesThemeMode.dark,
        onboardingCompleted: true,
        basicMode: true,
        enhancedFeedback: true,
        confirmCriticalActions: true,
        tutorialSeen: true,
      );

      final map = original.toMap();
      final reconstruida = UserPreferences.fromMap(map);

      expect(reconstruida.fontScale, original.fontScale);
      expect(reconstruida.contrastLevel, original.contrastLevel);
      expect(reconstruida.spacingScale, original.spacingScale);
      expect(reconstruida.reduceAnimations, original.reduceAnimations);
      expect(reconstruida.themeMode, original.themeMode);
      expect(reconstruida.onboardingCompleted, original.onboardingCompleted);
      expect(reconstruida.basicMode, original.basicMode);
      expect(reconstruida.enhancedFeedback, original.enhancedFeedback);
      expect(
        reconstruida.confirmCriticalActions,
        original.confirmCriticalActions,
      );
      expect(reconstruida.tutorialSeen, original.tutorialSeen);
    });

    test('fromMap usa fallbacks quando map está vazio', () {
      final prefs = UserPreferences.fromMap({});

      // Deve ser idêntico ao defaults()
      expect(prefs.fontScale, 1.2);
      expect(prefs.contrastLevel, PreferencesContrastLevel.normal);
      expect(prefs.spacingScale, 1.0);
      expect(prefs.reduceAnimations, false);
      expect(prefs.themeMode, PreferencesThemeMode.system);
      expect(prefs.onboardingCompleted, false);
      expect(prefs.basicMode, false);
      expect(prefs.enhancedFeedback, false);
      expect(prefs.confirmCriticalActions, false);
      expect(prefs.tutorialSeen, false);
    });

    test('fromMap lida com enums inválidos usando fallback', () {
      final prefs = UserPreferences.fromMap({
        'contrastLevel': 'ultra_mega',
        'themeMode': 'neon',
      });

      expect(prefs.contrastLevel, PreferencesContrastLevel.normal);
      expect(prefs.themeMode, PreferencesThemeMode.system);
    });
  });

  group('UserPreferences.copyWith', () {
    final original = UserPreferences.defaults();

    test('altera apenas o campo especificado', () {
      final alterada = original.copyWith(fontScale: 2.0);

      expect(alterada.fontScale, 2.0); // mudou
      expect(alterada.contrastLevel, original.contrastLevel); // preservou
      expect(alterada.spacingScale, original.spacingScale); // preservou
      expect(alterada.basicMode, original.basicMode); // preservou
    });

    test('altera múltiplos campos de uma vez', () {
      final alterada = original.copyWith(
        contrastLevel: PreferencesContrastLevel.high,
        reduceAnimations: true,
        themeMode: PreferencesThemeMode.light,
        basicMode: true,
        enhancedFeedback: true,
        confirmCriticalActions: true,
        onboardingCompleted: true,
        tutorialSeen: true,
      );

      expect(alterada.contrastLevel, PreferencesContrastLevel.high);
      expect(alterada.reduceAnimations, true);
      expect(alterada.themeMode, PreferencesThemeMode.light);
      expect(alterada.basicMode, true);
      expect(alterada.enhancedFeedback, true);
      expect(alterada.confirmCriticalActions, true);
      expect(alterada.onboardingCompleted, true);
      expect(alterada.tutorialSeen, true);
      // Campos não alterados preservados
      expect(alterada.fontScale, original.fontScale);
      expect(alterada.spacingScale, original.spacingScale);
    });
  });
}
