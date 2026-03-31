import 'package:go_router/go_router.dart';

import '../../presentation/pages/demo_page.dart';
import '../../presentation/pages/login_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      name: 'demo',
      builder: (context, state) => const DemoPage(),
    ),
  ],
);
