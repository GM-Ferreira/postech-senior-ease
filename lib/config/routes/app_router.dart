import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entities/app_user.dart';
import '../../core/entities/user_preferences.dart';
import '../../presentation/pages/demo_page.dart';
import '../../presentation/pages/forgot_password_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/profile_page.dart';
import '../../presentation/pages/sign_up_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/user_preferences_provider.dart';

/// Rotas públicas — acessíveis sem autenticação.
const _publicRoutes = {'/login', '/cadastro', '/recuperar-senha', '/splash'};

/// Usa ref.listen para observar o authStateProvider de forma gerenciada pelo
/// Riverpod. Isso garante que o StreamProvider fica ativo e que o redirect
/// sempre lê um valor cacheado — sem depender de assinaturas raw ao Firebase.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AppUser?>>(authStateProvider, (prev, next) {
      // Notifica o GoRouter apenas quando o status de autenticação muda
      // (null ↔ usuário) ou quando o loading muda.
      // Mudanças de perfil (displayName, photo) não devem acionar redirect.
      final prevIsLoading = prev?.isLoading ?? true;
      final prevAuthed = prev?.asData?.value != null;
      final nextAuthed = next.asData?.value != null;

      if (prevIsLoading != next.isLoading || prevAuthed != nextAuthed) {
        notifyListeners();
      }
    });

    _ref.listen<AsyncValue<UserPreferences>>(userPreferencesProvider, (
      prev,
      next,
    ) {
      // Notifica quando as preferências terminam de carregar ou quando
      // onboardingCompleted muda (ex: ao salvar no onboarding).
      final prevLoading = prev?.isLoading ?? true;
      final prevOnboarding = prev?.asData?.value.onboardingCompleted;
      final nextOnboarding = next.asData?.value.onboardingCompleted;

      if (prevLoading != next.isLoading || prevOnboarding != nextOnboarding) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;

  /// Loading enquanto auth OU (autenticado E preferências) ainda carregam.
  bool get isLoading {
    if (_ref.read(authStateProvider).isLoading) return true;
    if (_ref.read(authStateProvider).asData?.value != null) {
      return _ref.read(userPreferencesProvider).isLoading;
    }
    return false;
  }

  AppUser? get user => _ref.read(authStateProvider).asData?.value;

  bool get onboardingCompleted =>
      _ref.read(userPreferencesProvider).asData?.value.onboardingCompleted ??
      false;
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
        if (!isAuthenticated) return '/login';
        return notifier.onboardingCompleted ? '/' : '/onboarding';
      }

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && isPublic) {
        return notifier.onboardingCompleted ? '/' : '/onboarding';
      }

      if (isAuthenticated) {
        // Usuário ainda não fez onboarding → força para /onboarding
        if (!notifier.onboardingCompleted && location != '/onboarding') {
          return '/onboarding';
        }
        // Usuário já fez onboarding mas voltou para /onboarding → home
        if (notifier.onboardingCompleted && location == '/onboarding') {
          return '/';
        }
      }

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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DemoPage(),
      ),
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
