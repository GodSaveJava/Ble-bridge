import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/bridge/remote_bridge_task_assignment_handler.dart';
import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/use_cases/process_next_remote_bridge_task_use_case.dart';
import 'package:toylink_ai/app.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/claude_connector_onboarding_repository.dart';
import 'package:toylink_ai/domain/services/mcp_service.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/adapter_verification_controller.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/device_manager_controller.dart';
import 'package:toylink_ai/features/device_manager/presentation/pages/adapter_verification_page.dart';
import 'package:toylink_ai/features/device_manager/presentation/pages/device_manager_page.dart';
import 'package:toylink_ai/features/home/presentation/pages/home_page.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/claude_onboarding_page.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/mcp_page.dart';
import 'package:toylink_ai/infrastructure/mock/mock_remote_bridge_service.dart';
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
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
        ],
        child: const ToyLinkApp(),
      ),
    );

    expect(find.text('ToyLink AI'), findsOneWidget);
    expect(find.text(_kDeviceStatus), findsOneWidget);
    expect(find.text(_kMcpService), findsOneWidget);
    expect(find.text(_kViewAdapterStatus), findsOneWidget);
  });

  testWidgets('home page shows binding action when adapter is not bound', (
    WidgetTester tester,
  ) async {
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
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.noBinding,
                deviceId: 'device-a',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    expect(find.text(_kGoBindAdapter), findsOneWidget);
  });

  testWidgets('mcp page shows reverify action when adapter needs reverify', (
    WidgetTester tester,
  ) async {
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
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.needsReverify,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: 'Generic Triple Channel',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    expect(find.text(_kGoReverify), findsOneWidget);
  });

  testWidgets(
    'mcp page explains that MCP is the last step after verification',
    (WidgetTester tester) async {
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
            claudeConnectorOnboardingRepositoryProvider.overrideWith(
              (_) => _InMemoryClaudeConnectorOnboardingRepository(),
            ),
            remoteBridgeServiceProvider.overrideWith(
              (_) => MockRemoteBridgeService(),
            ),
            activeDeviceAdapterReadinessProvider.overrideWith(
              (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
                ActiveDeviceAdapterReadiness(
                  state: ActiveDeviceAdapterReadinessState.verified,
                  deviceId: 'device-a',
                  adapterId: 'generic.triple_channel.v1',
                  adapterDisplayName: '通用三通道模板',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: McpPage()),
        ),
      );

      expect(find.text(_kDeviceVerifiedTitle), findsOneWidget);
      expect(
        find.textContaining(_kOnlyStartMcpKeyLine),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining(_kAiControlWaitsForMcpKeyLine),
        findsOneWidget,
      );
    },
  );

  testWidgets('mcp page shows AI control ready after MCP starts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    expect(find.text(_kAiControlReadyTitle), findsOneWidget);
    expect(find.text(_kAiControlReadyChip), findsOneWidget);
    expect(find.text(_kAiControlReadyHint), findsOneWidget);
  });

  testWidgets('mcp page shows bridge onboarding prompt before remote session starts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeRemoteAccess),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kClaudeRemoteAccess), findsOneWidget);
    expect(find.text(_kBridgeOfflineChip), findsOneWidget);
    expect(find.text(_kStartBridgeSession), findsOneWidget);
    expect(find.text(_kConnectorUrlPending), findsOneWidget);
  });

  testWidgets('mcp page shows connector info after remote bridge is ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeRemoteAccess),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeHealthCheckTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kBridgeReadyChip), findsOneWidget);
    expect(find.text(_kConnectorUrlReady), findsOneWidget);
    expect(find.text(_kConnectorTokenReady), findsOneWidget);
    expect(find.text(_kRefreshConnectorInfo), findsOneWidget);
    expect(find.text(_kGoConfigureClaude), findsOneWidget);
    expect(find.text(_kClaudeHealthCheckTitle), findsOneWidget);
    expect(find.text(_kClaudeHealthPendingTitle), findsOneWidget);
  });

  testWidgets('mcp page can manually consume one remote task', (
    WidgetTester tester,
  ) async {
    final _TaskPollingBridgeService pollingBridge = _TaskPollingBridgeService(
      pendingTask: const RemoteBridgeTaskAssignment(
        requestId: 'bridge-task-9',
        tool: 'get_status',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          processNextRemoteBridgeTaskUseCaseProvider.overrideWith(
            (_) => ProcessNextRemoteBridgeTaskUseCase(
              remoteBridgeService: pollingBridge,
              assignmentHandler: RemoteBridgeTaskAssignmentHandler(
                consumeTask: ({
                  String? requestId,
                  required String tool,
                  Map<String, Object?> input = const <String, Object?>{},
                }) async {
                  return RemoteBridgeTaskResult(
                    ok: true,
                    requestId: requestId,
                    tool: tool,
                    result: const <String, Object?>{
                      'deviceId': 'mock-sosexy-001',
                    },
                  );
                },
              ),
            ),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('拉取一条远程任务'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('拉取一条远程任务'));
    await tester.tap(find.text('拉取一条远程任务'));
    await tester.pumpAndSettle();

    expect(find.text('最近任务处理成功'), findsOneWidget);
    expect(find.textContaining('get_status'), findsOneWidget);
    expect(find.textContaining('bridge-task-9'), findsOneWidget);
  });

  testWidgets('mcp page can enable automatic remote task consume', (
    WidgetTester tester,
  ) async {
    final _TaskPollingBridgeService pollingBridge = _TaskPollingBridgeService(
      pendingTask: const RemoteBridgeTaskAssignment(
        requestId: 'bridge-task-auto-9',
        tool: 'stop_all',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          processNextRemoteBridgeTaskUseCaseProvider.overrideWith(
            (_) => ProcessNextRemoteBridgeTaskUseCase(
              remoteBridgeService: pollingBridge,
              assignmentHandler: RemoteBridgeTaskAssignmentHandler(
                consumeTask: ({
                  String? requestId,
                  required String tool,
                  Map<String, Object?> input = const <String, Object?>{},
                }) async {
                  return RemoteBridgeTaskResult(
                    ok: true,
                    requestId: requestId,
                    tool: tool,
                    result: const <String, Object?>{'stopped': true},
                  );
                },
              ),
            ),
          ),
          remoteBridgeAutoConsumeIntervalProvider.overrideWith(
            (_) => const Duration(milliseconds: 20),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('自动拉取远程任务'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.textContaining('已自动处理远程任务'), findsOneWidget);
    expect(find.textContaining('stop_all'), findsOneWidget);
    expect(find.textContaining('bridge-task-auto-9'), findsOneWidget);
  });

  testWidgets('claude onboarding page blocks entry when local setup is incomplete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.noDevice,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ClaudeOnboardingPage()),
      ),
    );

    expect(find.text(_kClaudeOnboardingTitle), findsOneWidget);
    expect(find.text(_kClaudeBlockedTitle), findsOneWidget);
    expect(find.text(_kGoConnectDevice), findsOneWidget);
  });

  testWidgets('claude onboarding page shows connector steps when bridge is ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ClaudeOnboardingPage()),
      ),
    );

    expect(find.text(_kClaudeReadyTitle), findsOneWidget);
    expect(find.text(_kOnboardingStepPrepare), findsOneWidget);
    expect(find.text(_kOnboardingStepAddConnector), findsOneWidget);
    expect(find.text(_kConnectorUrlReady), findsOneWidget);
    expect(find.text(_kConnectorTokenReady), findsOneWidget);
    expect(find.text(_kCopyConnectorUrl), findsOneWidget);
    expect(find.text(_kCopyConnectorToken), findsOneWidget);
    expect(find.text(_kTroubleshootingTitle), findsOneWidget);
  });

  testWidgets('claude onboarding page shows copy actions and completion state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ClaudeOnboardingPage()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(_kCopyConnectorUrl),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(_kCopyConnectorUrl), findsOneWidget);
    expect(find.text(_kCopyConnectorToken), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(_kFinishedClaudeSetup),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_kFinishedClaudeSetup));
    await tester.pumpAndSettle();
    expect(find.text(_kClaudeSetupCompleteTitle), findsOneWidget);
  });

  testWidgets('mcp page shows completed Claude setup label for current device', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(
              record: ClaudeConnectorOnboardingRecord(
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                completedAt: DateTime(2026),
              ),
            ),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeRemoteAccess),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeHealthReadyTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kClaudeSetupCompletedChip), findsOneWidget);
    expect(find.text(_kViewClaudeConnectorInfo), findsOneWidget);
    expect(find.text(_kResetClaudeSetup), findsOneWidget);
    expect(find.text(_kClaudeHealthReadyTitle), findsOneWidget);
    expect(find.text(_kClaudeHealthReadySummary), findsOneWidget);
  });

  testWidgets('mcp page reset Claude onboarding returns to configure state', (
    WidgetTester tester,
  ) async {
    final _InMemoryClaudeConnectorOnboardingRepository repository =
        _InMemoryClaudeConnectorOnboardingRepository(
          record: ClaudeConnectorOnboardingRecord(
            deviceId: 'device-a',
            adapterId: 'generic.triple_channel.v1',
            completedAt: DateTime(2026),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => repository,
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kClaudeRemoteAccess),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kResetClaudeSetup),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_kResetClaudeSetup));
    await tester.pumpAndSettle();

    expect(find.text(_kClaudeSetupCompletedChip), findsNothing);
    expect(find.text(_kGoConfigureClaude), findsOneWidget);
    expect(repository.record, isNull);
  });

  testWidgets('mcp page shows bridge diagnostics banner when keepalive failed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _RecoverableKeepaliveFailedRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('桥接保活失败'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('桥接保活失败'), findsOneWidget);
    expect(find.textContaining('最近同步：2026-05-24 16:10'), findsOneWidget);
    final Finder restartBridgeButton = find.widgetWithText(
      OutlinedButton,
      '重新启动桥接会话',
    );
    expect(restartBridgeButton, findsOneWidget);

    await tester.tap(restartBridgeButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('桥接连接正常'), findsOneWidget);
    expect(find.textContaining('最近同步：2026-05-24 16:12'), findsOneWidget);
  });

  testWidgets('mcp page distinguishes disconnected toy from bridge failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _RunningMockMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.noDevice,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('玩具连接已断开'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('玩具连接已断开'), findsOneWidget);
    expect(find.textContaining('重新连接设备'), findsWidgets);
    expect(
      find.widgetWithText(OutlinedButton, '去重新连接设备'),
      findsOneWidget,
    );
  });

  testWidgets('verification page shows beginner guidance and locked submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'device-a', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdapterVerificationPage(adapterId: 'generic.triple_channel.v1'),
        ),
      ),
    );

    expect(find.text(_kVerificationGuide), findsOneWidget);
    expect(find.text(_kStopAllFirstStep), findsOneWidget);
    expect(find.text(_kStartLowIntensityTest), findsAtLeastNWidgets(1));
    expect(find.text(_kVerificationLockedHint), findsOneWidget);
  });

  testWidgets(
    'verification page shows next actions after verification passes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeDeviceStatusStreamProvider.overrideWith(
              (_) => Stream<DeviceStatus>.value(
                _deviceStatus(deviceId: 'device-a', isConnected: true),
              ),
            ),
            adapterVerificationControllerProvider.overrideWith(
              _VerifiedAdapterVerificationController.new,
            ),
          ],
          child: const MaterialApp(
            home: AdapterVerificationPage(
              adapterId: 'generic.triple_channel.v1',
            ),
          ),
        ),
      );

      expect(find.text(_kGoStartMcp), findsOneWidget);
      expect(find.text(_kConfirmInManualControl), findsOneWidget);
    },
  );

  testWidgets('device manager page shows recommended template guidance', (
    WidgetTester tester,
  ) async {
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
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              const <VerifiedAdapterRecord>[],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) => Stream<List<ActiveAdapterBinding>>.value(
              const <ActiveAdapterBinding>[],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'mock-sosexy-001', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_kAdapterWizardTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kAdapterWizardTitle), findsOneWidget);
    expect(find.text(_kWizardVerifyStep), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(_kSystemRecommendedTemplate),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kSystemRecommendedTemplate), findsOneWidget);
    expect(find.text(_kOfficialTemplate), findsAtLeastNWidgets(1));
    expect(find.text(_kPreferThisTemplate), findsOneWidget);
    expect(find.text(_kBindRecommendedTemplate), findsOneWidget);
    expect(find.text(_kPendingVerificationExplanation), findsOneWidget);
  });

  testWidgets('device manager page guides users to connect a device first', (
    WidgetTester tester,
  ) async {
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
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              const <VerifiedAdapterRecord>[],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) => Stream<List<ActiveAdapterBinding>>.value(
              const <ActiveAdapterBinding>[],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: '', isConnected: false),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(_kNextStepSuggestion), findsOneWidget);
    expect(find.text(_kGoConnectDevice), findsOneWidget);
    expect(find.text(_kConnectThenBindHint), findsOneWidget);
  });

  testWidgets('device manager page guides reverify and template switch', (
    WidgetTester tester,
  ) async {
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
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) =>
                Stream<List<ActiveAdapterBinding>>.value(<ActiveAdapterBinding>[
                  ActiveAdapterBinding(
                    deviceFingerprint: 'mock-sosexy-001',
                    adapterId: 'generic.triple_channel.v1',
                    boundAt: DateTime(2026),
                  ),
                ]),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              <VerifiedAdapterRecord>[
                VerifiedAdapterRecord(
                  manifestHash: 'manifest-hash-1',
                  adapterId: 'generic.triple_channel.v1',
                  adapterVersion: '1.0.0',
                  status: AdapterVerificationStatus.needsReverify,
                  updatedAt: DateTime(2026),
                  verifiedByAppVersion: '1.0.0',
                  target: const VerifiedTarget(
                    deviceFingerprint: 'mock-sosexy-001',
                    gattFingerprint: 'fff0/fff3/fff4',
                  ),
                  stepResults: const <VerificationStepResult>[
                    VerificationStepResult(stepKey: 'suck', passed: true),
                  ],
                  revokedReason: 'manifest changed',
                ),
              ],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'mock-sosexy-001', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(_kReverifyCurrentTemplate), findsOneWidget);
    expect(find.text(_kSwitchToRecommendedTemplate), findsOneWidget);
    expect(find.text(_kNeedsReverifyExplanation), findsOneWidget);
    expect(find.text(_kNeedsReverifyHint), findsOneWidget);
  });
}

DeviceStatus _deviceStatus({
  required String deviceId,
  required bool isConnected,
}) {
  return DeviceStatus(
    deviceId: deviceId,
    isConnected: isConnected,
    suckIntensity: 0,
    vibeIntensity: 0,
    emsIntensity: 0,
    suckMode: 1,
    vibeMode: 1,
    emsMode: 1,
    lastUpdatedAt: DateTime(2026),
  );
}

AdapterRecommendation _demoRecommendation() {
  return AdapterRecommendation(
    manifest: const AdapterManifest(
      schemaVersion: 1,
      adapterId: 'generic.triple_channel.v1',
      displayName: '\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f',
      protocolKey: 'generic_triple_channel',
      version: '1.0.0',
      minAppVersion: '1.0.0',
      adapterKind: AdapterKind.codecBacked,
      source: AdapterSource.official,
      codecKey: 'generic_triple_channel_v1',
      bleNamePrefixes: <String>['SOSEXY'],
      matching: AdapterMatching(
        serviceUuids: <String>['0000fff0-0000-1000-8000-00805f9b34fb'],
        priority: 100,
      ),
      gatt: AdapterGattProfile(
        serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
        writeCharacteristicUuid: '0000fff3-0000-1000-8000-00805f9b34fb',
        notifyCharacteristicUuid: '0000fff4-0000-1000-8000-00805f9b34fb',
        writeWithoutResponse: true,
      ),
      connection: AdapterConnectionHints(
        requiresBonding: false,
        requestMtu: 185,
        notifyRequired: false,
      ),
      capabilities: AdapterCapabilities(
        supportsSuck: true,
        supportsVibe: true,
        supportsEms: true,
        supportsSetAll: true,
        supportsStopAll: true,
      ),
      ranges: AdapterRanges(
        suckIntensity: IntRange(min: 0, max: 100),
        vibeIntensity: IntRange(min: 0, max: 100),
        emsIntensity: IntRange(min: 0, max: 20),
        mode: IntRange(min: 1, max: 4),
      ),
    ),
    reasons: const <String>[
      '\u8bbe\u5907\u524d\u7f00\u4e0e\u6a21\u677f\u5339\u914d\uff1aSOSEXY',
      '\u5bfc\u5165\u540e\u4ecd\u9700\u5728\u672c\u673a\u5b8c\u6210\u4f4e\u5f3a\u5ea6\u9a8c\u8bc1',
    ],
    score: 999,
    isCurrentBinding: false,
    verificationStatus: AdapterVerificationStatus.unverified,
  );
}

class _VerifiedAdapterVerificationController
    extends AdapterVerificationController {
  @override
  AdapterVerificationState build() {
    const AdapterVerificationState base = AdapterVerificationState(
      successMessage: '验证已通过，可以启用 AI 控制。',
    );
    return base.copyWith(
      steps: base.steps
          .map((VerificationStepDraft step) => step.copyWith(passed: true))
          .toList(),
    );
  }
}

const String _kDeviceStatus = '\u8bbe\u5907\u72b6\u6001';
const String _kMcpService = 'MCP \u670d\u52a1';
const String _kViewAdapterStatus = '\u67e5\u770b\u9002\u914d\u5668\u72b6\u6001';
const String _kGoBindAdapter = '\u53bb\u7ed1\u5b9a\u9002\u914d\u5668';
const String _kGoReverify = '\u53bb\u91cd\u65b0\u9a8c\u8bc1';
const String _kVerificationGuide = '\u9a8c\u8bc1\u8bf4\u660e';
const String _kStopAllFirstStep =
    '\u5148\u786e\u8ba4\u4e00\u952e\u505c\u6b62\u6b63\u5e38';
const String _kStartLowIntensityTest =
    '\u5f00\u59cb\u4f4e\u5f3a\u5ea6\u6d4b\u8bd5';
const String _kGoStartMcp = '\u53bb\u542f\u52a8 MCP';
const String _kConfirmInManualControl =
    '\u5148\u8fdb\u5165\u624b\u52a8\u63a7\u5236\u786e\u8ba4';
const String _kVerificationLockedHint =
    '\u5168\u90e8\u6b65\u9aa4\u90fd\u786e\u8ba4\u901a\u8fc7\u540e\uff0c\u624d\u80fd\u542f\u7528 AI \u63a7\u5236\u3002';
const String _kSystemRecommendedTemplate =
    '\u7cfb\u7edf\u63a8\u8350\u6a21\u677f';
const String _kAdapterWizardTitle = '\u9002\u914d\u5411\u5bfc';
const String _kWizardVerifyStep =
    '\u7b2c 3 \u6b65\uff1a\u4f4e\u5f3a\u5ea6\u9a8c\u8bc1';
const String _kOfficialTemplate = '\u5b98\u65b9\u6a21\u677f';
const String _kPreferThisTemplate =
    '\u4f18\u5148\u4f7f\u7528\u8fd9\u4efd\u6a21\u677f';
const String _kBindRecommendedTemplate =
    '\u7ed1\u5b9a\u63a8\u8350\u6a21\u677f\uff1a\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f';
const String _kNextStepSuggestion = '\u4e0b\u4e00\u6b65\u5efa\u8bae';
const String _kGoConnectDevice = '\u53bb\u8fde\u63a5\u8bbe\u5907';
const String _kReverifyCurrentTemplate =
    '\u91cd\u65b0\u9a8c\u8bc1\u5f53\u524d\u6a21\u677f';
const String _kSwitchToRecommendedTemplate =
    '\u6539\u7528\u63a8\u8350\u6a21\u677f\uff1a\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f';
const String _kPendingVerificationExplanation =
    '\u8fd9\u4efd\u9002\u914d\u5668\u8fd8\u6ca1\u5728\u5f53\u524d\u8bbe\u5907\u4e0a\u505a\u8fc7\u672c\u673a\u9a8c\u8bc1\u3002';
const String _kConnectThenBindHint =
    '\u5148\u8fde\u63a5\u8bbe\u5907\uff0c\u518d\u7ed1\u5b9a\u6216\u9a8c\u8bc1\u9002\u914d\u5668\u3002';
const String _kNeedsReverifyExplanation =
    '\u8fd9\u4efd\u9002\u914d\u5668\u4e4b\u524d\u53ef\u7528\uff0c\u4f46\u56e0\u4e3a\u6a21\u677f\u5185\u5bb9\u6216\u9a8c\u8bc1\u6761\u4ef6\u53d8\u5316\uff0c\u73b0\u5728\u9700\u8981\u91cd\u65b0\u786e\u8ba4\u4e00\u6b21\u3002\u539f\u56e0\uff1a\u9002\u914d\u5668\u5185\u5bb9\u53d1\u751f\u53d8\u5316\u3002';
const String _kNeedsReverifyHint =
    '\u5148\u91cd\u65b0\u9a8c\u8bc1\uff1b\u5982\u679c\u53cd\u5e94\u548c\u4e4b\u524d\u4e0d\u4e00\u81f4\uff0c\u518d\u6539\u7528\u63a8\u8350\u6a21\u677f\u3002';

class _RunningMockMcpService implements McpService {
  @override
  bool get isRunning => true;

  @override
  McpEndpointInfo? get endpointInfo =>
      const McpEndpointInfo(host: '127.0.0.1', port: 8765, path: '/mcp');

  @override
  Future<void> registerToolsForActiveDevice() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

const String _kDeviceVerifiedTitle =
    '\u5f53\u524d\u8bbe\u5907\u5df2\u7ecf\u5b8c\u6210\u9a8c\u8bc1';
const String _kOnlyStartMcpKeyLine =
    '\u73b0\u5728\u53ea\u5dee\u542f\u52a8 MCP \u670d\u52a1';
const String _kAiControlWaitsForMcpKeyLine =
    '\u542f\u52a8\u540e\uff0cAI \u624d\u80fd\u901a\u8fc7\u672c\u673a\u5de5\u5177\u63a7\u5236\u8bbe\u5907';
const String _kAiControlReadyTitle =
    '\u73b0\u5728\u53ef\u4ee5\u8ba9 AI \u63a7\u5236\u5f53\u524d\u8bbe\u5907';
const String _kAiControlReadyChip = 'AI \u63a7\u5236\u5df2\u53ef\u7528';
const String _kAiControlReadyHint =
    '\u73b0\u5728\u5df2\u7ecf\u53ef\u4ee5\u8ba9 AI \u63a7\u5236\u8bbe\u5907\u4e86\u3002\u5982\u679c\u4f60\u8fd8\u4e0d\u653e\u5fc3\uff0c\u4e5f\u53ef\u4ee5\u5148\u8fdb\u5165\u624b\u52a8\u63a7\u5236\u518d\u786e\u8ba4\u4e00\u6b21\u3002';
const String _kClaudeRemoteAccess = 'Claude 远程接入';
const String _kBridgeOfflineChip = '桥接未启动';
const String _kBridgeReadyChip = '桥接已就绪';
const String _kStartBridgeSession = '启动桥接会话';
const String _kRefreshConnectorInfo = '刷新接入信息';
const String _kConnectorUrlPending = '接入地址：尚未生成';
const String _kConnectorUrlReady =
    '接入地址：https://bridge.toylink.local/mcp/claude';
const String _kConnectorTokenReady = '接入令牌：已生成';
const String _kGoConfigureClaude = '去配置 Claude';
const String _kClaudeOnboardingTitle = 'Claude 接入向导';
const String _kClaudeBlockedTitle = '还不能开始 Claude 接入';
const String _kClaudeReadyTitle = '现在可以开始接入 Claude';
const String _kOnboardingStepPrepare = '第 1 步：确认本地准备';
const String _kOnboardingStepAddConnector = '第 3 步：去 Claude 添加 connector';
const String _kCopyConnectorUrl = '复制接入地址';
const String _kCopyConnectorToken = '复制接入令牌';
const String _kTroubleshootingTitle = '常见问题排查';
const String _kFinishedClaudeSetup = '我已完成 Claude 配置';
const String _kClaudeSetupCompleteTitle = 'Claude 接入已准备完成';
const String _kClaudeSetupCompletedChip = 'Claude 已完成接入';
const String _kViewClaudeConnectorInfo = '查看接入信息';
const String _kResetClaudeSetup = '重置 Claude 接入状态';
const String _kClaudeHealthCheckTitle = 'Claude 接入自检';
const String _kClaudeHealthPendingTitle = '还差 Claude 侧配置';
const String _kClaudeHealthReadyTitle = 'Claude 接入健康';
const String _kClaudeHealthReadySummary = '现在可以回到 Claude 原对话继续使用。';

class _ReadyRemoteBridgeService implements RemoteBridgeService {
  @override
  RemoteBridgeSession get currentSession => RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.ready,
    bridgeSessionId: 'bridge-session-ready',
    connectorInfo: const RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy_bridge_token_ready',
      toolNames: <String>[
        'set_suck',
        'set_vibe',
        'set_ems',
        'set_all',
        'stop_all',
        'get_status',
      ],
    ),
  );

  @override
  void dispose() {}

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield currentSession;
  }
}

class _RecoverableKeepaliveFailedRemoteBridgeService
    implements RemoteBridgeService {
  _RecoverableKeepaliveFailedRemoteBridgeService();

  final StreamController<RemoteBridgeSession> _controller =
      StreamController<RemoteBridgeSession>.broadcast();

  RemoteBridgeSession _session = RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.error,
    bridgeSessionId: 'bridge-session-keepalive-failed',
    connectorInfo: const RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy_bridge_token_ready',
      toolNames: <String>[
        'set_suck',
        'set_vibe',
        'set_ems',
        'set_all',
        'stop_all',
        'get_status',
      ],
    ),
    lastErrorCode: 'bridge_keepalive_failed',
    lastErrorMessage: 'keepalive failed',
    lastUpdatedAt: DateTime(2026, 5, 24, 16, 10),
  );

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {
    _session = RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.ready,
      bridgeSessionId: 'bridge-session-recovered',
      connectorInfo: const RemoteBridgeConnectorInfo(
        connectorUrl: 'https://bridge.toylink.local/mcp/claude',
        connectorToken: 'toy_bridge_token_recovered',
        toolNames: <String>[
          'set_suck',
          'set_vibe',
          'set_ems',
          'set_all',
          'stop_all',
          'get_status',
        ],
      ),
      lastUpdatedAt: DateTime(2026, 5, 24, 16, 12),
    );
    _controller.add(_session);
  }

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
    yield* _controller.stream;
  }
}

class _TaskPollingBridgeService implements RemoteBridgeService {
  _TaskPollingBridgeService({this.pendingTask});

  RemoteBridgeTaskAssignment? pendingTask;

  @override
  RemoteBridgeSession get currentSession => const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.ready,
    bridgeSessionId: 'bridge-session-polling',
    connectorInfo: RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy_bridge_token_polling',
      toolNames: <String>['get_status', 'stop_all'],
    ),
  );

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async {
    final next = pendingTask;
    pendingTask = null;
    return next;
  }

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield currentSession;
  }
}

class _InMemoryClaudeConnectorOnboardingRepository
    implements ClaudeConnectorOnboardingRepository {
  _InMemoryClaudeConnectorOnboardingRepository({
    ClaudeConnectorOnboardingRecord? record,
  }) : _record = record;

  ClaudeConnectorOnboardingRecord? _record;

  ClaudeConnectorOnboardingRecord? get record => _record;

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async => _record;

  @override
  Future<void> reset() async {
    _record = null;
  }

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord record) async {
    _record = record;
  }
}
