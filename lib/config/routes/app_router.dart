import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entities/app_user.dart';
import '../../presentation/pages/demo_page.dart';
import '../../presentation/pages/forgot_password_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/sign_up_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/providers/auth_provider.dart';

/// Rotas públicas — acessíveis sem autenticação.
const _publicRoutes = {'/login', '/cadastro', '/recuperar-senha', '/splash'};

/// Usa ref.listen para observar o authStateProvider de forma gerenciada pelo
/// Riverpod. Isso garante que o StreamProvider fica ativo e que o redirect
/// sempre lê um valor cacheado — sem depender de assinaturas raw ao Firebase.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;

  bool get isLoading => _ref.read(authStateProvider).isLoading;
  AppUser? get user => _ref.read(authStateProvider).asData?.value;
}

final _routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // keepAlive evita que o GoRouter seja descartado e recriado em rebuilds,
  // o que reiniciaria o notifier com isLoading=true causando loop na splash.
  ref.keepAlive();

  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (notifier.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = notifier.user != null;
      final isPublic = _publicRoutes.contains(location);

      // Após o loading, sempre sai da splash independente do estado de auth.
      if (location == '/splash') {
        return isAuthenticated ? '/' : '/login';
      }

      if (isAuthenticated && isPublic) return '/';
      if (!isAuthenticated && !isPublic) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/cadastro',
        name: 'cadastro',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/recuperar-senha',
        name: 'recuperar-senha',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DemoPage(),
      ),
    ],
  );
});
