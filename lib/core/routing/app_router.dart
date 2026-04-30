import 'package:go_router/go_router.dart';

import '../../features/ble_device/presentation/pages/scan_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/control/presentation/pages/control_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/mcp_server/presentation/pages/mcp_page.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanPage()),
      GoRoute(path: '/control', builder: (_, _) => const ControlPage()),
      GoRoute(path: '/chat', builder: (_, _) => const ChatPage()),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const PlaceholderPage(title: 'Settings'),
      ),
      GoRoute(path: '/mcp', builder: (_, _) => const McpPage()),
    ],
  );
}
