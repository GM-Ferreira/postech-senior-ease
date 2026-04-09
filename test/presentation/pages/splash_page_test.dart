import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_ease/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage - renderização', () {
    testWidgets('exibe ícone, nome do app e indicador de carregamento', (
      tester,
    ) async {
      // SplashPage não precisa de router nem providers —
      // basta envolver com MaterialApp
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));

      expect(find.text('SeniorEase'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('tem semântica de carregamento', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));

      // Verifica que existe a label de acessibilidade
      expect(find.bySemanticsLabel('Carregando aplicativo'), findsOneWidget);
    });
  });
}
