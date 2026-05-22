import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/remote_bridge_session.dart';
import 'claude_connector_onboarding_controller.dart';
import 'remote_bridge_session_controller.dart';

enum ClaudeConnectorHealthStatus { blocked, pending, ready }

class ClaudeConnectorHealthCheck {
  const ClaudeConnectorHealthCheck({
    required this.status,
    required this.title,
    required this.summary,
    required this.deviceReady,
    required this.bridgeReady,
    required this.connectorReady,
    required this.onboardingCompleted,
    this.actionLabel,
    this.actionRoute,
  });

  final ClaudeConnectorHealthStatus status;
  final String title;
  final String summary;
  final bool deviceReady;
  final bool bridgeReady;
  final bool connectorReady;
  final bool onboardingCompleted;
  final String? actionLabel;
  final String? actionRoute;

  bool get isHealthy => status == ClaudeConnectorHealthStatus.ready;
}

final claudeConnectorHealthCheckProvider =
    Provider<AsyncValue<ClaudeConnectorHealthCheck>>((ref) {
      final AsyncValue<ActiveDeviceAdapterReadiness> readinessAsync = ref.watch(
        activeDeviceAdapterReadinessProvider,
      );
      final RemoteBridgeSessionState bridgeState = ref.watch(
        remoteBridgeSessionControllerProvider,
      );
      final ClaudeConnectorOnboardingState onboardingState = ref.watch(
        claudeConnectorOnboardingControllerProvider,
      );

      if (readinessAsync.hasError) {
        return AsyncError<ClaudeConnectorHealthCheck>(
          readinessAsync.error!,
          readinessAsync.stackTrace!,
        );
      }

      if (readinessAsync is! AsyncData<ActiveDeviceAdapterReadiness>) {
        return const AsyncLoading<ClaudeConnectorHealthCheck>();
      }

      final ActiveDeviceAdapterReadiness readiness = readinessAsync.value;
      final bool deviceReady =
          readiness.state == ActiveDeviceAdapterReadinessState.verified;
      final bool bridgeReady =
          bridgeState.status == RemoteBridgeSessionStatus.ready;
      final bool connectorReady = bridgeState.canOnboardClaude;
      final bool onboardingCompleted =
          onboardingState.matchesReadiness(readiness);

      if (!deviceReady) {
        return AsyncData<ClaudeConnectorHealthCheck>(
          ClaudeConnectorHealthCheck(
            status: ClaudeConnectorHealthStatus.blocked,
            title: '设备侧未准备好',
            summary: _deviceBlockedSummary(readiness),
            deviceReady: false,
            bridgeReady: bridgeReady,
            connectorReady: connectorReady,
            onboardingCompleted: onboardingCompleted,
            actionLabel: _deviceBlockedActionLabel(readiness),
            actionRoute: _deviceBlockedActionRoute(readiness),
          ),
        );
      }

      if (!bridgeReady) {
        return AsyncData<ClaudeConnectorHealthCheck>(
          ClaudeConnectorHealthCheck(
            status: ClaudeConnectorHealthStatus.pending,
            title: '桥接侧仍需处理',
            summary: _bridgePendingSummary(bridgeState.status),
            deviceReady: true,
            bridgeReady: false,
            connectorReady: connectorReady,
            onboardingCompleted: onboardingCompleted,
          ),
        );
      }

      if (!connectorReady) {
        return const AsyncData<ClaudeConnectorHealthCheck>(
          ClaudeConnectorHealthCheck(
            status: ClaudeConnectorHealthStatus.pending,
            title: '接入信息还没准备好',
            summary: '桥接会话已经连上，但接入地址或令牌还没生成。先在当前页面刷新或重新生成接入信息。',
            deviceReady: true,
            bridgeReady: true,
            connectorReady: false,
            onboardingCompleted: false,
          ),
        );
      }

      if (!onboardingCompleted) {
        return const AsyncData<ClaudeConnectorHealthCheck>(
          ClaudeConnectorHealthCheck(
            status: ClaudeConnectorHealthStatus.pending,
            title: '还差 Claude 侧配置',
            summary: '设备、桥接和接入信息都已就绪，下一步去 Claude 添加 connector，完成后就能回到原对话继续使用。',
            deviceReady: true,
            bridgeReady: true,
            connectorReady: true,
            onboardingCompleted: false,
            actionLabel: '继续 Claude 接入',
            actionRoute: '/claude-onboarding',
          ),
        );
      }

      return const AsyncData<ClaudeConnectorHealthCheck>(
        ClaudeConnectorHealthCheck(
          status: ClaudeConnectorHealthStatus.ready,
          title: 'Claude 接入健康',
          summary: '现在可以回到 Claude 原对话继续使用。',
          deviceReady: true,
          bridgeReady: true,
          connectorReady: true,
          onboardingCompleted: true,
          actionLabel: '查看 Claude 接入详情',
          actionRoute: '/claude-onboarding',
        ),
      );
    });

String _deviceBlockedSummary(ActiveDeviceAdapterReadiness readiness) {
  final String adapterName =
      readiness.adapterDisplayName ?? readiness.adapterId ?? '当前适配器';
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '还没有连接可供 Claude 控制的设备。先完成设备连接。';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '当前设备还没有绑定适配器。先去设备管理页绑定模板。';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前设备之前绑定的适配器已经失效或被删除。请重新选择模板。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '$adapterName 还没完成低强度验证。验证通过前，Claude 不能控制设备。';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '$adapterName 的验证已被撤销。请重新验证后再开放给 Claude。';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '$adapterName 需要重新验证。完成后再回来继续 Claude 接入。';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '$adapterName 上次验证失败。请重新做低强度测试。';
    case ActiveDeviceAdapterReadinessState.verified:
      return '设备侧已经准备完成。';
  }
}

String? _deviceBlockedActionLabel(ActiveDeviceAdapterReadiness readiness) {
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '去连接设备';
    case ActiveDeviceAdapterReadinessState.noBinding:
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '去设备管理';
    case ActiveDeviceAdapterReadinessState.unverified:
    case ActiveDeviceAdapterReadinessState.revoked:
    case ActiveDeviceAdapterReadinessState.needsReverify:
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return readiness.adapterId == null ? '去设备管理' : '去重新验证';
    case ActiveDeviceAdapterReadinessState.verified:
      return null;
  }
}

String? _deviceBlockedActionRoute(ActiveDeviceAdapterReadiness readiness) {
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '/scan';
    case ActiveDeviceAdapterReadinessState.noBinding:
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '/device-manager';
    case ActiveDeviceAdapterReadinessState.unverified:
    case ActiveDeviceAdapterReadinessState.revoked:
    case ActiveDeviceAdapterReadinessState.needsReverify:
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return readiness.adapterId == null
          ? '/device-manager'
          : '/verification/${readiness.adapterId}';
    case ActiveDeviceAdapterReadinessState.verified:
      return null;
  }
}

String _bridgePendingSummary(RemoteBridgeSessionStatus status) {
  return switch (status) {
    RemoteBridgeSessionStatus.offline =>
      '桥接会话还没启动。先在当前页面启动桥接会话。',
    RemoteBridgeSessionStatus.connecting =>
      '桥接正在建立连接，请稍等片刻，不要重复点击。',
    RemoteBridgeSessionStatus.busy =>
      '桥接正在处理请求或刷新接入信息，请等待当前操作完成。',
    RemoteBridgeSessionStatus.error =>
      '桥接会话当前异常。请重新启动桥接会话，并检查网络和后台保活状态。',
    RemoteBridgeSessionStatus.ready => '桥接已经准备完成。',
  };
}
