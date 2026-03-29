import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_ease/main.dart';

void main() {
  testWidgets('App renders SeniorEase text', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SeniorEaseApp()));

    expect(find.text('SeniorEase'), findsOneWidget);
  });
}
