import '../../core/error/failure.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/entities/device_status.dart';
import '../services/mcp_control_authorization_service.dart';
import '../use_cases/control_device_use_case.dart';

class McpToolResult {
  const McpToolResult({
    required this.ok,
    this.data,
    this.errorCode,
    this.errorMessage,
  });

  final bool ok;
  final Map<String, Object?>? data;
  final String? errorCode;
  final String? errorMessage;
}

class McpToolRouter {
  const McpToolRouter({
    required ControlDeviceUseCase controlDeviceUseCase,
    required McpControlAuthorizationService mcpControlAuthorizationService,
  }) : _controlDeviceUseCase = controlDeviceUseCase,
       _mcpControlAuthorizationService = mcpControlAuthorizationService;

  final ControlDeviceUseCase _controlDeviceUseCase;
  final McpControlAuthorizationService _mcpControlAuthorizationService;

  Future<McpToolResult> callTool(
    String name, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) async {
    try {
      switch (name) {
        case 'set_suck':
          await _mcpControlAuthorizationService.ensureToolAllowed(name);
          return _ok(
            await _controlDeviceUseCase.setSuck(
              intensity: _requiredInt(arguments, 'intensity'),
              mode: _optionalInt(arguments, 'mode', defaultValue: 1),
              source: CommandSource.mcp,
            ),
          );
        case 'set_vibe':
          await _mcpControlAuthorizationService.ensureToolAllowed(name);
          return _ok(
            await _controlDeviceUseCase.setVibe(
              intensity: _requiredInt(arguments, 'intensity'),
              mode: _optionalInt(arguments, 'mode', defaultValue: 1),
              source: CommandSource.mcp,
            ),
          );
        case 'set_ems':
          await _mcpControlAuthorizationService.ensureToolAllowed(name);
          return _ok(
            await _controlDeviceUseCase.setEms(
              intensity: _requiredInt(arguments, 'intensity'),
              mode: _optionalInt(arguments, 'mode', defaultValue: 1),
              source: CommandSource.mcp,
            ),
          );
        case 'set_all':
          await _mcpControlAuthorizationService.ensureToolAllowed(name);
          return _ok(
            await _controlDeviceUseCase.setAll(
              suck: _optionalInt(arguments, 'suck', defaultValue: 0),
              vibe: _optionalInt(arguments, 'vibe', defaultValue: 0),
              ems: _optionalInt(arguments, 'ems', defaultValue: 0),
              suckMode: _optionalInt(arguments, 'suckMode', defaultValue: 1),
              vibeMode: _optionalInt(arguments, 'vibeMode', defaultValue: 1),
              emsMode: _optionalInt(arguments, 'emsMode', defaultValue: 1),
              source: CommandSource.mcp,
            ),
          );
        case 'stop_all':
          return _ok(await _controlDeviceUseCase.stopAll());
        case 'get_status':
          await _mcpControlAuthorizationService.ensureToolAllowed(name);
          return _ok(await _controlDeviceUseCase.getStatus());
        default:
          return const McpToolResult(
            ok: false,
            errorCode: 'tool_not_found',
            errorMessage: 'Unsupported MCP tool.',
          );
      }
    } on Failure catch (failure) {
      return McpToolResult(
        ok: false,
        errorCode: _failureToMcpCode(failure),
        errorMessage: failure.message,
        data: failure.details,
      );
    } catch (_) {
      return const McpToolResult(
        ok: false,
        errorCode: 'mcp_internal_error',
        errorMessage: 'MCP tool execution failed.',
      );
    }
  }

  McpToolResult _ok(DeviceStatus status) {
    return McpToolResult(ok: true, data: _statusToJson(status));
  }

  Map<String, Object?> _statusToJson(DeviceStatus status) {
    return <String, Object?>{
      'deviceId': status.deviceId,
      'isConnected': status.isConnected,
      'suckIntensity': status.suckIntensity,
      'vibeIntensity': status.vibeIntensity,
      'emsIntensity': status.emsIntensity,
      'suckMode': status.suckMode,
      'vibeMode': status.vibeMode,
      'emsMode': status.emsMode,
      'batteryLevel': status.batteryLevel,
      'lastUpdatedAt': status.lastUpdatedAt.toIso8601String(),
    };
  }

  int _requiredInt(Map<String, Object?> args, String key) {
    final Object? value = args[key];
    if (value is int) {
      return value;
    }
    throw Failure.validation(
      message: 'Missing or invalid argument: $key must be an integer.',
      details: <String, Object?>{'argument': key},
    );
  }

  int _optionalInt(
    Map<String, Object?> args,
    String key, {
    required int defaultValue,
  }) {
    final Object? value = args[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is int) {
      return value;
    }
    throw Failure.validation(
      message: 'Invalid argument: $key must be an integer.',
      details: <String, Object?>{'argument': key},
    );
  }

  String _failureToMcpCode(Failure failure) {
    return switch (failure.code) {
      FailureCode.validation => 'validation_error',
      FailureCode.noActiveDevice => 'no_active_device',
      FailureCode.deviceDisconnected => 'device_disconnected',
      FailureCode.deviceWrite => 'device_write_failed',
      FailureCode.securityLock => 'security_lock_required',
      FailureCode.adapterNotVerified => 'adapter_not_verified',
      FailureCode.adapterVerificationFailed => 'adapter_verification_failed',
      FailureCode.adapterRevoked => 'adapter_revoked',
      _ => 'mcp_internal_error',
    };
  }
}
