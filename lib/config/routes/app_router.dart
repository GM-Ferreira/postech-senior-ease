import 'package:go_router/go_router.dart';

import '../../presentation/pages/demo_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/sign_up_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
      path: '/',
      name: 'demo',
      builder: (context, state) => const DemoPage(),
    ),
  ],
);
