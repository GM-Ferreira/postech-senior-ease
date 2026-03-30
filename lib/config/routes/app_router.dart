import 'package:go_router/go_router.dart';

import '../../presentation/pages/demo_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'demo',
      builder: (context, state) => const DemoPage(),
    ),
  ],
);
