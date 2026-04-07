import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/entities/user_preferences.dart';
import 'firebase_options.dart';
import 'presentation/providers/animations_provider.dart';
import 'presentation/providers/basic_mode_provider.dart';
import 'presentation/providers/confirm_actions_provider.dart';
import 'presentation/providers/contrast_provider.dart';
import 'presentation/providers/enhanced_feedback_provider.dart';
import 'presentation/providers/font_scale_provider.dart';
import 'presentation/providers/spacing_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SeniorEaseApp()));
}

/// Converte [PreferencesContrastLevel] (domínio) para [ContrastLevel] (UI).
ContrastLevel _toContrastLevel(PreferencesContrastLevel level) =>
    switch (level) {
      PreferencesContrastLevel.high => ContrastLevel.high,
      PreferencesContrastLevel.veryHigh => ContrastLevel.veryHigh,
      PreferencesContrastLevel.normal => ContrastLevel.normal,
    };

class SeniorEaseApp extends ConsumerWidget {
  const SeniorEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Quando as preferências do Firestore carregam (ou o usuário troca),
    // alimentamos os providers de UI com os valores persistidos.
    ref.listen<AsyncValue<UserPreferences>>(userPreferencesProvider, (_, next) {
      next.whenData((prefs) {
        ref.read(fontScaleProvider.notifier).setScale(prefs.fontScale);
        ref.read(spacingScaleProvider.notifier).setScale(prefs.spacingScale);
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(prefs.themeMode.toThemeMode());
        ref
            .read(reduceAnimationsProvider.notifier)
            .set(reduce: prefs.reduceAnimations);
        ref
            .read(contrastLevelProvider.notifier)
            .setLevel(_toContrastLevel(prefs.contrastLevel));
        ref.read(basicModeProvider.notifier).set(enabled: prefs.basicMode);
        ref
            .read(enhancedFeedbackProvider.notifier)
            .set(enabled: prefs.enhancedFeedback);
        ref
            .read(confirmActionsProvider.notifier)
            .set(enabled: prefs.confirmCriticalActions);
      });
    });

    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final contrastLevel = ref.watch(contrastLevelProvider);
    final spacingScale = ref.watch(spacingScaleProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);

    // Ler configurações de acessibilidade do SO
    final platformData = MediaQuery.of(context);
    final platformTextScale = platformData.textScaler.scale(1.0);
    final platformDisableAnimations = platformData.disableAnimations;

    final effectiveFontScale = fontScale == 1.0 ? platformTextScale : fontScale;

    final effectiveDisableAnimations =
        reduceAnimations || platformDisableAnimations;

    return MediaQuery(
      data: platformData.copyWith(
        textScaler: TextScaler.linear(effectiveFontScale),
        disableAnimations: effectiveDisableAnimations,
      ),
      child: MaterialApp.router(
        title: 'SeniorEase',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(
          contrastLevel: contrastLevel.value,
          spacingScale: spacingScale,
        ),
        darkTheme: buildDarkTheme(
          contrastLevel: contrastLevel.value,
          spacingScale: spacingScale,
        ),
        themeMode: themeMode,
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
