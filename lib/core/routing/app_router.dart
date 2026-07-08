import 'package:go_router/go_router.dart';
import 'app_shell.dart';

import '../../features/ble_device/presentation/pages/scan_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/control/presentation/pages/control_page.dart';
import '../../features/device_manager/presentation/pages/device_manager_page.dart';
import '../../features/device_manager/presentation/pages/adapter_verification_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/mcp_server/presentation/pages/ai_connector_setup_page.dart';
import '../../features/mcp_server/presentation/pages/claude_onboarding_page.dart';
import '../../features/mcp_server/presentation/pages/connector_card_import_page.dart';
import '../../features/mcp_server/presentation/pages/mcp_page.dart';
import '../../features/settings/presentation/pages/background_stability_checklist_page.dart';
import '../../features/settings/presentation/pages/remote_bridge_config_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', redirect: (_, _) => '/home'),
          GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          GoRoute(path: '/scan', builder: (_, _) => const ScanPage()),
          GoRoute(
            path: '/control',
            builder: (_, state) => ControlPage(
              returnPath: state.uri.queryParameters['returnTo'],
              returnLabel: state.uri.queryParameters['returnLabel'],
            ),
          ),
          GoRoute(path: '/chat', builder: (_, _) => const ChatPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(
            path: '/settings/bridge',
            builder: (_, _) => const RemoteBridgeConfigPage(),
          ),
          GoRoute(
            path: '/background-checklist',
            builder: (_, _) => const BackgroundStabilityChecklistPage(),
          ),
          GoRoute(path: '/mcp', builder: (_, _) => const McpPage()),
          GoRoute(
            path: '/ai-connector-setup',
            builder: (_, _) => const AiConnectorSetupPage(),
          ),
          GoRoute(
            path: '/connector-card/v1',
            builder: (_, state) => ConnectorCardImportPage(uri: state.uri),
          ),
          GoRoute(
            path: '/v1',
            builder: (_, state) => ConnectorCardImportPage(uri: state.uri),
          ),
          GoRoute(
            path: '/claude-onboarding',
            builder: (_, _) => const ClaudeOnboardingPage(),
          ),
          GoRoute(
            path: '/device-manager',
            builder: (_, _) => const DeviceManagerPage(),
          ),
          GoRoute(
            path: '/verification/:adapterId',
            builder: (context, state) {
              final String adapterId = state.pathParameters['adapterId'] ?? '';
              return AdapterVerificationPage(adapterId: adapterId);
            },
          ),
        ],
      ),
    ],
  );
}
