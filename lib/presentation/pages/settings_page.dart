import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../core/entities/user_preferences.dart';
import '../providers/animations_provider.dart';
import '../providers/basic_mode_provider.dart';
import '../providers/confirm_actions_provider.dart';
import '../providers/contrast_provider.dart';
import '../providers/enhanced_feedback_provider.dart';
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

  void _autoSave() {
    final current =
        ref.read(userPreferencesProvider).asData?.value ??
        UserPreferences.defaults();

    ref
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
            basicMode: ref.read(basicModeProvider),
            enhancedFeedback: ref.read(enhancedFeedbackProvider),
            confirmCriticalActions: ref.read(confirmActionsProvider),
          ),
        );
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
    ref.read(basicModeProvider.notifier).set(enabled: defaults.basicMode);
    ref
        .read(enhancedFeedbackProvider.notifier)
        .set(enabled: defaults.enhancedFeedback);
    ref
        .read(confirmActionsProvider.notifier)
        .set(enabled: defaults.confirmCriticalActions);

    try {
      final current =
          ref.read(userPreferencesProvider).asData?.value ??
          UserPreferences.defaults();
      await ref
          .read(userPreferencesProvider.notifier)
          .save(
            defaults.copyWith(
              onboardingCompleted: current.onboardingCompleted,
              tutorialSeen: current.tutorialSeen,
            ),
          );
      if (mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Preferências restauradas para os padrões',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferências restauradas!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Silencia erro — preferências locais já foram restauradas
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    final spacingScale = ref.watch(spacingScaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final contrastLevel = ref.watch(contrastLevelProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);
    final basicMode = ref.watch(basicModeProvider);
    final enhancedFeedback = ref.watch(enhancedFeedbackProvider);
    final confirmActions = ref.watch(confirmActionsProvider);

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
                onChanged: (v) {
                  ref.read(fontScaleProvider.notifier).setScale(v!);
                  _autoSave();
                },
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
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).setThemeMode(v!);
                  _autoSave();
                },
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
                onChanged: (v) {
                  ref.read(contrastLevelProvider.notifier).setLevel(v!);
                  _autoSave();
                },
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
                onChanged: (v) {
                  ref.read(spacingScaleProvider.notifier).setScale(v!);
                  _autoSave();
                },
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
                onChanged: (v) {
                  ref.read(reduceAnimationsProvider.notifier).set(reduce: v);
                  _autoSave();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Modo de exibição ─────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.view_agenda_outlined,
            title: 'Modo de exibição',
            children: [
              SwitchListTile(
                title: const Text('Modo básico'),
                subtitle: const Text(
                  'Exibe as tarefas de forma simplificada, com menos detalhes',
                ),
                value: basicMode,
                onChanged: (v) {
                  ref.read(basicModeProvider.notifier).set(enabled: v);
                  _autoSave();
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _TaskPreview(basicMode: basicMode),
            ],
          ),

          const SizedBox(height: 16),

          // ── Feedback visual ─────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.notifications_active_outlined,
            title: 'Feedback visual',
            children: [
              SwitchListTile(
                title: const Text('Feedback reforçado'),
                subtitle: const Text(
                  'Exibe confirmações mais evidentes ao realizar ações',
                ),
                value: enhancedFeedback,
                onChanged: (v) {
                  ref.read(enhancedFeedbackProvider.notifier).set(enabled: v);
                  _autoSave();
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _FeedbackPreview(enhanced: enhancedFeedback),
            ],
          ),

          const SizedBox(height: 16),

          // ── Segurança ───────────────────────────────────────────────────
          _SettingsCard(
            icon: Icons.shield_outlined,
            title: 'Segurança',
            children: [
              SwitchListTile(
                title: const Text('Confirmar antes de excluir'),
                subtitle: const Text(
                  'Pede confirmação antes de apagar tarefas ou dados importantes',
                ),
                value: confirmActions,
                onChanged: (v) {
                  ref.read(confirmActionsProvider.notifier).set(enabled: v);
                  _autoSave();
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Ações ──────────────────────────────────────────────────────────
          OutlinedButton(
            onPressed: _restoreDefaults,
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
                ExcludeSemantics(
                  child: Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
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
    final spacing = theme.extension<AppSpacing>()!;

    return Semantics(
      label: 'Prévia de espaçamento entre elementos',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
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
              _SpacingTaskCard(title: 'Reunião às 14h', spacing: spacing),
              SizedBox(height: spacing.sm),
              _SpacingTaskCard(title: 'Tomar remédio', spacing: spacing),
              SizedBox(height: spacing.sm),
              _SpacingTaskCard(title: 'Consulta médica', spacing: spacing),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpacingTaskCard extends StatelessWidget {
  const _SpacingTaskCard({required this.title, required this.spacing});

  final String title;
  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xs,
          vertical: spacing.sm,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(value: false, onChanged: null),
            ),
            SizedBox(width: spacing.xs),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview de tarefa (modo básico vs avançado) ──────────────────────────────

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.basicMode});

  final bool basicMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Semantics(
      label: basicMode
          ? 'Prévia do modo básico de exibição'
          : 'Prévia do modo avançado de exibição',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.sm,
            spacing.md,
            spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                basicMode ? 'Prévia — Modo básico' : 'Prévia — Modo avançado',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: spacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: basicMode
                    ? const _BasicTaskCard()
                    : const _AdvancedTaskCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicTaskCard extends StatelessWidget {
  const _BasicTaskCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(value: false, onChanged: null),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Consulta médica',
                style: theme.textTheme.titleMedium,
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedTaskCard extends StatelessWidget {
  const _AdvancedTaskCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(value: false, onChanged: null),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consulta médica', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Alta',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vence hoje',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview de feedback reforçado ────────────────────────────────────────────

class _FeedbackPreview extends ConsumerWidget {
  const _FeedbackPreview({required this.enhanced});

  final bool enhanced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévia — toque para testar',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: spacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tarefa concluída!'),
              onPressed: () =>
                  enhanced ? _showEnhanced(context) : _showNormal(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showNormal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarefa concluída!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEnhanced(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 72,
              color: Theme.of(ctx).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tarefa concluída!',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Parabéns! Continue assim.',
              style: Theme.of(ctx).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
