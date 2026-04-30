import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_lock_overlay.dart';

class ToyLinkApp extends ConsumerWidget {
  const ToyLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ToyLink AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return AppLockOverlayHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
