import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/shared/widgets/premium_bouncing_wrapper.dart';

void main() {
  testWidgets('does not double-fire when wrapping an interactive child', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PremiumBouncingWrapper(
              onTap: () => tapCount += 1,
              child: OutlinedButton(
                onPressed: () => tapCount += 1,
                child: const Text('Open page'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();

    expect(tapCount, 1);
  });
}
