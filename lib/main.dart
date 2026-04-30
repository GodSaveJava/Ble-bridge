import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/application_providers.dart';
import 'app.dart';
import 'infrastructure/providers/infrastructure_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        hardwareRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultHardwareRepositoryProvider);
        }),
        mcpServiceProvider.overrideWith((ref) {
          return ref.watch(defaultMcpServiceProvider);
        }),
      ],
      child: const ToyLinkApp(),
    ),
  );
}
