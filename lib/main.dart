import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/providers/animations_provider.dart';
import 'presentation/providers/contrast_provider.dart';
import 'presentation/providers/font_scale_provider.dart';
import 'presentation/providers/spacing_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SeniorEaseApp()));
}

class SeniorEaseApp extends ConsumerWidget {
  const SeniorEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        theme: buildLightTheme(
          contrastLevel: contrastLevel.value,
          spacingScale: spacingScale,
        ),
        darkTheme: buildDarkTheme(
          contrastLevel: contrastLevel.value,
          spacingScale: spacingScale,
        ),
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
