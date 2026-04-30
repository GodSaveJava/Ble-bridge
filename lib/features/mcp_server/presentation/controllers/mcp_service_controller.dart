import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/services/mcp_service.dart';

class McpServiceState {
  const McpServiceState({
    this.isRunning = false,
    this.isBusy = false,
    this.endpointInfo,
    this.errorMessage,
  });

  final bool isRunning;
  final bool isBusy;
  final McpEndpointInfo? endpointInfo;
  final String? errorMessage;

  McpServiceState copyWith({
    bool? isRunning,
    bool? isBusy,
    McpEndpointInfo? endpointInfo,
    String? errorMessage,
    bool clearError = false,
  }) {
    return McpServiceState(
      isRunning: isRunning ?? this.isRunning,
      isBusy: isBusy ?? this.isBusy,
      endpointInfo: endpointInfo ?? this.endpointInfo,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class McpServiceController extends Notifier<McpServiceState> {
  @override
  McpServiceState build() {
    final useCase = ref.watch(manageMcpServiceUseCaseProvider);
    return McpServiceState(
      isRunning: useCase.isRunning,
      endpointInfo: useCase.endpointInfo,
    );
  }

  Future<void> start() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final useCase = ref.read(manageMcpServiceUseCaseProvider);
      await useCase.start();
      state = state.copyWith(
        isBusy: false,
        isRunning: useCase.isRunning,
        endpointInfo: useCase.endpointInfo,
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'MCP 服务启动失败。');
    }
  }

  Future<void> stop() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final useCase = ref.read(manageMcpServiceUseCaseProvider);
      await useCase.stop();
      state = state.copyWith(
        isBusy: false,
        isRunning: useCase.isRunning,
        endpointInfo: useCase.endpointInfo,
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: 'MCP 服务停止失败。');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final mcpServiceControllerProvider =
    NotifierProvider<McpServiceController, McpServiceState>(
      McpServiceController.new,
    );
