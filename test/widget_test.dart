import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/app.dart';
import 'package:toylink_ai/infrastructure/providers/infrastructure_providers.dart';

void main() {
  testWidgets('renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
        ],
        child: const ToyLinkApp(),
      ),
    );

    expect(find.text('ToyLink AI'), findsOneWidget);
    expect(find.text('设备状态'), findsOneWidget);
    expect(find.text('MCP 服务'), findsOneWidget);
    expect(find.text('查看适配器状态'), findsOneWidget);
  });
}
