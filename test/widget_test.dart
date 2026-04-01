import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:senior_ease/config/routes/app_router.dart';
import 'package:senior_ease/main.dart';
import 'package:senior_ease/presentation/pages/login_page.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    // Override do router para evitar dependência do Firebase em testes.
    final testRouter = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(testRouter)],
        child: const SeniorEaseApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Acesse sua conta'), findsOneWidget);
  });
}
