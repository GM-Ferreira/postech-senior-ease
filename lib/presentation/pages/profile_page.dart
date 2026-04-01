import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>()!;

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Erro ao carregar perfil.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: spacing.lg),

                    // Avatar
                    Center(
                      child: _Avatar(photoUrl: user.photoUrl, colors: colors),
                    ),
                    SizedBox(height: spacing.lg),

                    // Nome
                    if (user.displayName != null) ...[
                      Text(
                        user.displayName!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.xs),
                    ],

                    // Email
                    Text(
                      user.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.xxl),

                    // Dados do perfil
                    _InfoTile(
                      icon: Icons.person_outlined,
                      label: 'Nome',
                      value: user.displayName ?? 'Não informado',
                      colors: colors,
                      theme: theme,
                    ),
                    SizedBox(height: spacing.sm),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      colors: colors,
                      theme: theme,
                    ),
                    SizedBox(height: spacing.sm),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Membro desde',
                      value: _formatDate(user.createdAt),
                      colors: colors,
                      theme: theme,
                    ),
                    SizedBox(height: spacing.xxl),

                    // Logout
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(color: colors.error),
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.colors});

  final String? photoUrl;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: colors.primaryContainer,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return CircleAvatar(
      radius: 52,
      backgroundColor: colors.primaryContainer,
      child: Icon(Icons.person, size: 52, color: colors.onPrimaryContainer),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
