import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            displayName: _nameController.text.trim(),
          );
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapAuthError(e.code));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) => switch (code) {
    'email-already-in-use' => 'Este email já está cadastrado.',
    'invalid-email' => 'Email inválido.',
    'weak-password' => 'A senha é muito fraca. Use pelo menos 6 caracteres.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde um momento e tente novamente.',
    _ => 'Erro ao criar conta. Tente novamente.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(spacing.md),
                        child: Image.asset(
                          'assets/icon/app_icon.jpg',
                          height: 80,
                          width: 80,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'Crie sua conta',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing.xl),

                  // Nome
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Como gostaria de ser chamado',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu nome';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
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

                  // Senha
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                          SemanticsService.sendAnnouncement(
                            View.of(context),
                            _obscurePassword ? 'Senha oculta' : 'Senha visível',
                            TextDirection.ltr,
                          );
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  // Confirmar senha
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirm
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                          SemanticsService.sendAnnouncement(
                            View.of(context),
                            _obscureConfirm ? 'Senha oculta' : 'Senha visível',
                            TextDirection.ltr,
                          );
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  // Erro inline
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(spacing.sm),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(spacing.sm),
                      ),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.error_outline,
                              color: colors.onErrorContainer,
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.md),
                  ],

                  // Botão de cadastro
                  FilledButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: spacing.md),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar conta'),
                  ),
                  SizedBox(height: spacing.lg),

                  // Link para login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Já tem conta?', style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Fazer login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
