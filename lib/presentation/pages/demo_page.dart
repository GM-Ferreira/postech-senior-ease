import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../providers/animations_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/contrast_provider.dart';
import '../providers/font_scale_provider.dart';
import '../providers/spacing_provider.dart';
import '../providers/theme_provider.dart';

class DemoPage extends ConsumerWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>()!;

    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final contrastLevel = ref.watch(contrastLevelProvider);
    final spacingScale = ref.watch(spacingScaleProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demonstração de Acessibilidade'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          // --- Tema ---
          _SectionTitle(title: 'Tema', spacing: spacing),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.settings_brightness),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Escuro'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),

          SizedBox(height: spacing.lg),

          // --- Fonte ---
          _SectionTitle(title: 'Tamanho da Fonte', spacing: spacing),
          Slider(
            value: fontScale,
            min: 0.8,
            max: 2.5,
            divisions: 17,
            label: '${(fontScale * 100).round()}%',
            onChanged: (value) {
              ref.read(fontScaleProvider.notifier).setScale(value);
            },
          ),
          Text(
            'Escala atual: ${(fontScale * 100).round()}%',
            style: theme.textTheme.bodyMedium,
          ),

          SizedBox(height: spacing.lg),

          // --- Contraste ---
          _SectionTitle(title: 'Nível de Contraste', spacing: spacing),
          SegmentedButton<ContrastLevel>(
            segments: const [
              ButtonSegment(value: ContrastLevel.normal, label: Text('Normal')),
              ButtonSegment(value: ContrastLevel.high, label: Text('Alto')),
              ButtonSegment(
                value: ContrastLevel.veryHigh,
                label: Text('Muito Alto'),
              ),
            ],
            selected: {contrastLevel},
            onSelectionChanged: (selection) {
              ref
                  .read(contrastLevelProvider.notifier)
                  .setLevel(selection.first);
            },
          ),

          SizedBox(height: spacing.lg),

          // --- Espaçamento ---
          _SectionTitle(title: 'Espaçamento', spacing: spacing),
          Slider(
            value: spacingScale,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            label: '${(spacingScale * 100).round()}%',
            onChanged: (value) {
              ref.read(spacingScaleProvider.notifier).setScale(value);
            },
          ),
          Text(
            'Escala atual: ${(spacingScale * 100).round()}%',
            style: theme.textTheme.bodyMedium,
          ),

          SizedBox(height: spacing.lg),

          // --- Animações ---
          _SectionTitle(title: 'Animações', spacing: spacing),
          SwitchListTile(
            title: const Text('Reduzir animações'),
            subtitle: const Text('Desativa transições e efeitos visuais'),
            value: reduceAnimations,
            onChanged: (_) {
              ref.read(reduceAnimationsProvider.notifier).toggle();
            },
          ),

          SizedBox(height: spacing.xl),

          // --- Preview ---
          _SectionTitle(title: 'Preview', spacing: spacing),
          SizedBox(height: spacing.sm),
          _PreviewCard(spacing: spacing),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.spacing});

  final String title;
  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.spacing});

  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exemplo de Tarefa', style: theme.textTheme.headlineSmall),
            SizedBox(height: spacing.sm),
            Text(
              'Esta é uma tarefa de exemplo para visualizar como o texto, cores, espaçamento e contraste ficam com as configurações atuais.',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('Concluir'),
                ),
                SizedBox(width: spacing.sm),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary,
            ),
            SizedBox(height: spacing.xs),
            Text(
              '70% concluído',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
