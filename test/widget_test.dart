import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toylink_ai/app.dart';

void main() {
  testWidgets('renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ToyLinkApp()));

    expect(find.text('ToyLink AI'), findsOneWidget);
    expect(find.text('Device Status'), findsOneWidget);
    expect(find.text('MCP Service'), findsOneWidget);
  });
}
