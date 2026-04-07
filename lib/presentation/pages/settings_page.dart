import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../core/entities/user_preferences.dart';
import '../providers/animations_provider.dart';
import '../providers/contrast_provider.dart';
import '../providers/font_scale_provider.dart';
import '../providers/spacing_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_preferences_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _saving = false;

  PreferencesContrastLevel _toPrefsContrast(ContrastLevel level) =>
      switch (level) {
        ContrastLevel.high => PreferencesContrastLevel.high,
        ContrastLevel.veryHigh => PreferencesContrastLevel.veryHigh,
        ContrastLevel.normal => PreferencesContrastLevel.normal,
      };

  ContrastLevel _toUiContrast(PreferencesContrastLevel level) =>
      switch (level) {
        PreferencesContrastLevel.high => ContrastLevel.high,
        PreferencesContrastLevel.veryHigh => ContrastLevel.veryHigh,
        PreferencesContrastLevel.normal => ContrastLevel.normal,
      };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final current =
          ref.read(userPreferencesProvider).asData?.value ??
          UserPreferences.defaults();

      await ref
          .read(userPreferencesProvider.notifier)
          .save(
            current.copyWith(
              fontScale: ref.read(fontScaleProvider),
              spacingScale: ref.read(spacingScaleProvider),
              themeMode: PreferencesThemeMode.fromThemeMode(
                ref.read(themeModeProvider),
              ),
              contrastLevel: _toPrefsContrast(ref.read(contrastLevelProvider)),
              reduceAnimations: ref.read(reduceAnimationsProvider),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferências salvas com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar padrões'),
        content: const Text(
          'Tem certeza? Todas as suas configurações de acessibilidade voltarão ao padrão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final defaults = UserPreferences.defaults();
    ref.read(fontScaleProvider.notifier).setScale(defaults.fontScale);
    ref.read(spacingScaleProvider.notifier).setScale(defaults.spacingScale);
    ref
        .read(themeModeProvider.notifier)
        .setThemeMode(defaults.themeMode.toThemeMode());
    ref
        .read(contrastLevelProvider.notifier)
        .setLevel(_toUiContrast(defaults.contrastLevel));
    ref
        .read(reduceAnimationsProvider.notifier)
        .set(reduce: defaults.reduceAnimations);

    setState(() => _saving = true);
    try {
      final current =
          ref.read(userPreferencesProvider).asData?.value ??
          UserPreferences.defaults();
      await ref
          .read(userPreferencesProvider.notifier)
          .save(
            defaults.copyWith(onboardingCompleted: current.onboardingCompleted),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferências restauradas!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    final spacingScale = ref.watch(spacingScaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final contrastLevel = ref.watch(contrastLevelProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Tamanho do texto ───────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.text_fields,
            title: 'Tamanho do texto',
            children: [
              RadioGroup<double>(
                groupValue: _roundedFontScale(fontScale),
                onChanged: (v) =>
                    ref.read(fontScaleProvider.notifier).setScale(v!),
                child: const Column(
                  children: [
                    RadioListTile<double>(title: Text('Normal'), value: 1.0),
                    RadioListTile<double>(title: Text('Grande'), value: 1.3),
                    RadioListTile<double>(
                      title: Text('Muito grande'),
                      value: 1.6,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Tema ───────────────────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.palette_outlined,
            title: 'Tema',
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (v) =>
                    ref.read(themeModeProvider.notifier).setThemeMode(v!),
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('Automático'),
                      subtitle: Text('Segue a configuração do dispositivo'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Claro'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Escuro'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Contraste ──────────────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.contrast,
            title: 'Contraste',
            children: [
              RadioGroup<ContrastLevel>(
                groupValue: contrastLevel,
                onChanged: (v) =>
                    ref.read(contrastLevelProvider.notifier).setLevel(v!),
                child: const Column(
                  children: [
                    RadioListTile<ContrastLevel>(
                      title: Text('Normal'),
                      subtitle: Text('Visual padrão do app'),
                      value: ContrastLevel.normal,
                    ),
                    RadioListTile<ContrastLevel>(
                      title: Text('Reforçado'),
                      subtitle: Text(
                        'Cores mais definidas para facilitar leitura',
                      ),
                      value: ContrastLevel.high,
                    ),
                    RadioListTile<ContrastLevel>(
                      title: Text('Muito alto'),
                      subtitle: Text('Máximo contraste disponível'),
                      value: ContrastLevel.veryHigh,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Espaçamento ────────────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.space_bar,
            title: 'Espaçamento',
            children: [
              RadioGroup<double>(
                groupValue: _roundedSpacingScale(spacingScale),
                onChanged: (v) =>
                    ref.read(spacingScaleProvider.notifier).setScale(v!),
                child: const Column(
                  children: [
                    RadioListTile<double>(title: Text('Compacto'), value: 0.8),
                    RadioListTile<double>(title: Text('Normal'), value: 1.0),
                    RadioListTile<double>(
                      title: Text('Espaçado'),
                      subtitle: Text('Mais espaço entre os elementos'),
                      value: 1.5,
                    ),
                  ],
                ),
              ),
              const _SpacingPreview(),
            ],
          ),

          const SizedBox(height: 16),

          // ── Animações ──────────────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.animation,
            title: 'Animações',
            children: [
              SwitchListTile(
                title: const Text('Reduzir animações'),
                subtitle: const Text(
                  'Remove transições e efeitos visuais em movimento',
                ),
                value: reduceAnimations,
                onChanged: (v) =>
                    ref.read(reduceAnimationsProvider.notifier).set(reduce: v),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Ações ──────────────────────────────────────────────────────────
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Salvar preferências'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _saving ? null : _restoreDefaults,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text('Restaurar padrões'),
          ),
        ],
      ),
    );
  }

  /// Arredonda fontScale para o valor mais próximo dos 3 níveis disponíveis.
  double _roundedFontScale(double scale) {
    if (scale <= 1.15) return 1.0;
    if (scale <= 1.45) return 1.3;
    return 1.6;
  }

  /// Arredonda spacingScale para o valor mais próximo dos 3 níveis disponíveis.
  double _roundedSpacingScale(double scale) {
    if (scale <= 0.9) return 0.8;
    if (scale <= 1.25) return 1.0;
    return 1.5;
  }
}

// ─── Card de seção ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Preview de espaçamento ───────────────────────────────────────────────────

class _SpacingPreview extends StatelessWidget {
  const _SpacingPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lê o AppSpacing do tema — muda automaticamente quando spacingScaleProvider muda,
    // porque o main.dart reconstrói o MaterialApp com o novo ThemeData.
    final spacing = theme.extension<AppSpacing>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
      child: Container(
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prévia',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Reunião às 14h',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Tomar remédio',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Consulta médica',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
