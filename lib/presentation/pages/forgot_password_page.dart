import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapAuthError(e.code));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) => switch (code) {
    'user-not-found' => 'Nenhuma conta encontrada com este email.',
    'invalid-email' => 'Email inválido.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde um momento e tente novamente.',
    _ => 'Erro ao enviar o email. Tente novamente.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _emailSent
                ? _SuccessView(
                    spacing: spacing,
                    theme: theme,
                    colors: colors,
                    email: _emailController.text.trim(),
                    onBackToLogin: () => context.go('/login'),
                  )
                : _FormView(
                    formKey: _formKey,
                    emailController: _emailController,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    spacing: spacing,
                    theme: theme,
                    colors: colors,
                    onSend: _sendReset,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.spacing,
    required this.theme,
    required this.colors,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final AppSpacing spacing;
  final ThemeData theme;
  final ColorScheme colors;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 64, color: colors.primary),
          SizedBox(height: spacing.md),
          Text(
            'Esqueceu a senha?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.sm),
          Text(
            'Informe seu email e enviaremos um link para você criar uma nova senha.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.xl),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSend(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'seu@email.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          SizedBox(height: spacing.md),

          if (errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(spacing.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.onErrorContainer),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.md),
          ],

          FilledButton(
            onPressed: isLoading ? null : onSend,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: spacing.md),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar link de recuperação'),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.spacing,
    required this.theme,
    required this.colors,
    required this.email,
    required this.onBackToLogin,
  });

  final AppSpacing spacing;
  final ThemeData theme;
  final ColorScheme colors;
  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 64, color: colors.primary),
        SizedBox(height: spacing.md),
        Text(
          'Email enviado!',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.sm),
        Text(
          'Enviamos um link para:\n$email\n\nVerifique sua caixa de entrada e siga as instruções para criar uma nova senha.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.xl),
        FilledButton(
          onPressed: onBackToLogin,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: spacing.md),
          ),
          child: const Text('Voltar para o login'),
        ),
      ],
    );
  }
}
