import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/user_preferences.dart';
import '../providers/contrast_provider.dart';
import '../providers/font_scale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_preferences_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  double _fontScale = 1.3;
  PreferencesThemeMode _themeMode = PreferencesThemeMode.system;
  PreferencesContrastLevel _contrastLevel = PreferencesContrastLevel.normal;
  bool _saving = false;

  // Aplica imediatamente no provider de UI para preview em tempo real.
  // O Firestore só é atualizado ao clicar em "Começar".
  void _applyFont(double v) {
    setState(() => _fontScale = v);
    ref.read(fontScaleProvider.notifier).setScale(v);
  }

  void _applyTheme(PreferencesThemeMode v) {
    setState(() => _themeMode = v);
    ref.read(themeModeProvider.notifier).setThemeMode(v.toThemeMode());
  }

  void _applyContrast(PreferencesContrastLevel v) {
    setState(() => _contrastLevel = v);
    final uiLevel = switch (v) {
      PreferencesContrastLevel.high => ContrastLevel.high,
      PreferencesContrastLevel.veryHigh => ContrastLevel.veryHigh,
      PreferencesContrastLevel.normal => ContrastLevel.normal,
    };
    ref.read(contrastLevelProvider.notifier).setLevel(uiLevel);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final current =
        ref.read(userPreferencesProvider).asData?.value ??
        UserPreferences.defaults();

    await ref
        .read(userPreferencesProvider.notifier)
        .save(
          current.copyWith(
            fontScale: _fontScale,
            themeMode: _themeMode,
            contrastLevel: _contrastLevel,
            onboardingCompleted: true,
          ),
        );
    // O router detecta onboardingCompleted = true e redireciona para '/'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _StepIndicator(current: _step, total: 3),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: switch (_step) {
                  0 => _FontStep(
                    key: const ValueKey(0),
                    selected: _fontScale,
                    onChanged: _applyFont,
                  ),
                  1 => _AppearanceStep(
                    key: const ValueKey(1),
                    themeMode: _themeMode,
                    contrastLevel: _contrastLevel,
                    onThemeChanged: _applyTheme,
                    onContrastChanged: _applyContrast,
                  ),
                  _ => _ConfirmStep(
                    key: const ValueKey(2),
                    fontScale: _fontScale,
                    themeMode: _themeMode,
                    contrastLevel: _contrastLevel,
                  ),
                },
              ),
            ),
            _BottomNav(
              step: _step,
              saving: _saving,
              onBack: _step > 0 ? () => setState(() => _step--) : null,
              onNext: () {
                if (_step < 2) {
                  setState(() => _step++);
                } else {
                  _finish();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Indicador de etapas ──────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Etapa 1: Tamanho do texto ────────────────────────────────────────────────

class _FontStep extends StatelessWidget {
  const _FontStep({super.key, required this.selected, required this.onChanged});

  final double selected;
  final ValueChanged<double> onChanged;

  static const _options = [
    (label: 'Normal', scale: 1.0),
    (label: 'Grande', scale: 1.3),
    (label: 'Muito grande', scale: 1.6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Tamanho do texto',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o tamanho que fica mais confortável para você.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final isSelected = selected == opt.scale;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OptionCard(
                selected: isSelected,
                onTap: () => onChanged(opt.scale),
                child: Row(
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 16 * opt.scale,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      opt.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Etapa 2: Aparência ───────────────────────────────────────────────────────

class _AppearanceStep extends StatelessWidget {
  const _AppearanceStep({
    super.key,
    required this.themeMode,
    required this.contrastLevel,
    required this.onThemeChanged,
    required this.onContrastChanged,
  });

  final PreferencesThemeMode themeMode;
  final PreferencesContrastLevel contrastLevel;
  final ValueChanged<PreferencesThemeMode> onThemeChanged;
  final ValueChanged<PreferencesContrastLevel> onContrastChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Aparência',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o visual que prefere.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tema',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Claro',
                  selected: themeMode == PreferencesThemeMode.light,
                  onTap: () => onThemeChanged(PreferencesThemeMode.light),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeCard(
                  icon: Icons.nightlight_outlined,
                  label: 'Escuro',
                  selected: themeMode == PreferencesThemeMode.dark,
                  onTap: () => onThemeChanged(PreferencesThemeMode.dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeCard(
                  icon: Icons.brightness_auto_outlined,
                  label: 'Auto',
                  selected: themeMode == PreferencesThemeMode.system,
                  onTap: () => onThemeChanged(PreferencesThemeMode.system),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Contraste',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            selected: contrastLevel == PreferencesContrastLevel.normal,
            onTap: () => onContrastChanged(PreferencesContrastLevel.normal),
            child: Row(
              children: [
                Icon(Icons.contrast, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Normal', style: theme.textTheme.titleMedium),
                      Text(
                        'Visual padrão do app',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (contrastLevel == PreferencesContrastLevel.normal)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            selected: contrastLevel == PreferencesContrastLevel.high,
            onTap: () => onContrastChanged(PreferencesContrastLevel.high),
            child: Row(
              children: [
                Icon(
                  Icons.contrast,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reforçado', style: theme.textTheme.titleMedium),
                      Text(
                        'Cores mais definidas para facilitar a leitura',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (contrastLevel == PreferencesContrastLevel.high)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Etapa 3: Confirmação ─────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    super.key,
    required this.fontScale,
    required this.themeMode,
    required this.contrastLevel,
  });

  final double fontScale;
  final PreferencesThemeMode themeMode;
  final PreferencesContrastLevel contrastLevel;

  String get _fontLabel => switch (fontScale) {
    1.3 => 'Grande',
    1.6 => 'Muito grande',
    _ => 'Normal',
  };

  String get _themeLabel => switch (themeMode) {
    PreferencesThemeMode.light => 'Claro',
    PreferencesThemeMode.dark => 'Escuro',
    PreferencesThemeMode.system => 'Automático',
  };

  String get _contrastLabel => switch (contrastLevel) {
    PreferencesContrastLevel.high => 'Reforçado',
    PreferencesContrastLevel.veryHigh => 'Muito alto',
    PreferencesContrastLevel.normal => 'Normal',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 52,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tudo pronto!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas preferências foram configuradas.\nVocê pode ajustá-las a qualquer momento.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 40),
          _SummaryItem(
            icon: Icons.text_fields,
            label: 'Texto',
            value: _fontLabel,
          ),
          const Divider(height: 1),
          _SummaryItem(
            icon: Icons.palette_outlined,
            label: 'Tema',
            value: _themeLabel,
          ),
          const Divider(height: 1),
          _SummaryItem(
            icon: Icons.contrast,
            label: 'Contraste',
            value: _contrastLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Navegação inferior ───────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.step,
    required this.saving,
    required this.onNext,
    this.onBack,
  });

  final int step;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: saving ? null : onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isLast ? 'Começar' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card de opção genérico ───────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}
