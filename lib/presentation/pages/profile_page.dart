import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../core/repositories/auth_repository.dart';
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

                    // Editar nome
                    FilledButton.icon(
                      onPressed: () => _showEditNameDialog(
                        context,
                        ref,
                        currentName: user.displayName ?? '',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar nome'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                      ),
                    ),
                    SizedBox(height: spacing.sm),

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

  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref, {
    required String currentName,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _EditNameDialog(currentName: currentName, authRepo: authRepo),
    );

    // Feedback de sucesso após fechar o dialog de edição.
    if ((saved ?? false) && context.mounted) {
      final colors = Theme.of(context).colorScheme;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: colors.primary, size: 72),
              const SizedBox(height: 20),
              Text(
                'Nome atualizado\ncom sucesso!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
              child: const Text('OK', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    }
  }
}

/// Dialog de edição de nome como StatefulWidget para que o
/// TextEditingController seja descartado pelo ciclo de vida do Flutter
/// (após a animação de fechamento completar), evitando use-after-dispose.
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.currentName, required this.authRepo});

  final String currentName;
  final AuthRepository authRepo;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar nome'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe um nome';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepo.updateDisplayName(_controller.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao salvar. Tente novamente.';
        });
      }
    }
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
