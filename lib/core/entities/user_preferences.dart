import 'package:flutter/material.dart';

/// Níveis de contraste disponíveis no app.
/// Duplicado aqui para manter o domínio independente dos providers de UI.
enum PreferencesContrastLevel {
  normal,
  high,
  veryHigh;

  static PreferencesContrastLevel fromString(String value) => switch (value) {
    'high' => high,
    'veryHigh' => veryHigh,
    _ => normal,
  };

  String toSerializable() => name;
}

/// Modos de tema disponíveis.
enum PreferencesThemeMode {
  system,
  light,
  dark;

  static PreferencesThemeMode fromString(String value) => switch (value) {
    'light' => light,
    'dark' => dark,
    _ => system,
  };

  String toSerializable() => name;

  ThemeMode toThemeMode() => switch (this) {
    light => ThemeMode.light,
    dark => ThemeMode.dark,
    system => ThemeMode.system,
  };

  static PreferencesThemeMode fromThemeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => light,
    ThemeMode.dark => dark,
    _ => system,
  };
}

/// Entidade de domínio que representa todas as preferências persistíveis
/// do usuário. Imutável — use [copyWith] para criar variações.
class UserPreferences {
  const UserPreferences({
    required this.fontScale,
    required this.contrastLevel,
    required this.spacingScale,
    required this.reduceAnimations,
    required this.themeMode,
    required this.onboardingCompleted,
    required this.basicMode,
    required this.enhancedFeedback,
    required this.confirmCriticalActions,
    required this.tutorialSeen,
  });

  /// Preferências padrão com foco em acessibilidade para idosos:
  /// fonte ligeiramente maior, contraste normal, sem redução de animações.
  factory UserPreferences.defaults() => const UserPreferences(
    fontScale: 1.2,
    contrastLevel: PreferencesContrastLevel.normal,
    spacingScale: 1.0,
    reduceAnimations: false,
    themeMode: PreferencesThemeMode.system,
    onboardingCompleted: false,
    basicMode: false,
    enhancedFeedback: false,
    confirmCriticalActions: false,
    tutorialSeen: false,
  );

  /// Reconstrói a entidade a partir de um Map (Firestore).
  /// Valores ausentes ou inválidos caem nos defaults.
  factory UserPreferences.fromMap(Map<String, dynamic> map) => UserPreferences(
    fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1.2,
    contrastLevel: PreferencesContrastLevel.fromString(
      map['contrastLevel'] as String? ?? '',
    ),
    spacingScale: (map['spacingScale'] as num?)?.toDouble() ?? 1.0,
    reduceAnimations: map['reduceAnimations'] as bool? ?? false,
    themeMode: PreferencesThemeMode.fromString(
      map['themeMode'] as String? ?? '',
    ),
    onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
    basicMode: map['basicMode'] as bool? ?? false,
    enhancedFeedback: map['enhancedFeedback'] as bool? ?? false,
    confirmCriticalActions: map['confirmCriticalActions'] as bool? ?? false,
    tutorialSeen: map['tutorialSeen'] as bool? ?? false,
  );

  final double fontScale;
  final PreferencesContrastLevel contrastLevel;
  final double spacingScale;
  final bool reduceAnimations;
  final PreferencesThemeMode themeMode;
  final bool onboardingCompleted;
  final bool basicMode;
  final bool enhancedFeedback;
  final bool confirmCriticalActions;
  final bool tutorialSeen;

  /// Converte para Map para persistir no Firestore.
  Map<String, dynamic> toMap() => {
    'fontScale': fontScale,
    'contrastLevel': contrastLevel.toSerializable(),
    'spacingScale': spacingScale,
    'reduceAnimations': reduceAnimations,
    'themeMode': themeMode.toSerializable(),
    'onboardingCompleted': onboardingCompleted,
    'basicMode': basicMode,
    'enhancedFeedback': enhancedFeedback,
    'confirmCriticalActions': confirmCriticalActions,
    'tutorialSeen': tutorialSeen,
  };

  UserPreferences copyWith({
    double? fontScale,
    PreferencesContrastLevel? contrastLevel,
    double? spacingScale,
    bool? reduceAnimations,
    PreferencesThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? basicMode,
    bool? enhancedFeedback,
    bool? confirmCriticalActions,
    bool? tutorialSeen,
  }) => UserPreferences(
    fontScale: fontScale ?? this.fontScale,
    contrastLevel: contrastLevel ?? this.contrastLevel,
    spacingScale: spacingScale ?? this.spacingScale,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    themeMode: themeMode ?? this.themeMode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    basicMode: basicMode ?? this.basicMode,
    enhancedFeedback: enhancedFeedback ?? this.enhancedFeedback,
    confirmCriticalActions:
        confirmCriticalActions ?? this.confirmCriticalActions,
    tutorialSeen: tutorialSeen ?? this.tutorialSeen,
  );
}
