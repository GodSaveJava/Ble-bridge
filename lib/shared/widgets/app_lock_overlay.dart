import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/app_lock_controller.dart';

class AppLockOverlayHost extends ConsumerStatefulWidget {
  const AppLockOverlayHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockOverlayHost> createState() => _AppLockOverlayHostState();
}

class _AppLockOverlayHostState extends ConsumerState<AppLockOverlayHost> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    return Stack(
      children: <Widget>[
        widget.child,
        if (lockState.enabled && lockState.locked)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            '应用已锁定',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('请输入 PIN（当前测试密码：1234）'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              errorText: _error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                final ok = ref
                                    .read(appLockControllerProvider.notifier)
                                    .unlockWithPin(_pinController.text.trim());
                                if (ok) {
                                  setState(() {
                                    _error = null;
                                    _pinController.clear();
                                  });
                                } else {
                                  setState(() {
                                    _error = '密码错误，请重试';
                                  });
                                }
                              },
                              child: const Text('解锁'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
