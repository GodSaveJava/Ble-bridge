import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/bridge/remote_bridge_task_assignment_handler.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';

void main() {
  group('RemoteBridgeTaskAssignmentHandler', () {
    test('passes valid payload to consume use case', () async {
      late Map<String, Object?> capturedInput;
      final RemoteBridgeTaskAssignmentHandler handler =
          RemoteBridgeTaskAssignmentHandler(
            consumeTask: ({
              String? requestId,
              required String tool,
              Map<String, Object?> input = const <String, Object?>{},
            }) async {
              capturedInput = <String, Object?>{
                'requestId': requestId ?? '',
                'tool': tool,
                'input': input,
              };
              return const RemoteBridgeTaskResult(
                ok: true,
                requestId: 'bridge-task-1',
                tool: 'get_status',
                result: <String, dynamic>{'deviceId': 'mock-sosexy-001'},
              );
            },
          );

      final RemoteBridgeTaskResult result = await handler.handle(<String, Object?>{
        'requestId': 'bridge-task-1',
        'tool': 'get_status',
        'input': <String, Object?>{'mode': 1},
      });

      expect(result.ok, isTrue);
      expect(
        capturedInput,
        <String, Object?>{
          'requestId': 'bridge-task-1',
          'tool': 'get_status',
          'input': <String, Object?>{'mode': 1},
        },
      );
    });

    test('returns validation error when tool field is missing', () async {
      final RemoteBridgeTaskAssignmentHandler handler =
          RemoteBridgeTaskAssignmentHandler(
            consumeTask: ({
              String? requestId,
              required String tool,
              Map<String, Object?> input = const <String, Object?>{},
            }) async {
              fail('consumeTask should not be called for invalid payload.');
            },
          );

      final RemoteBridgeTaskResult result = await handler.handle(<String, Object?>{
        'requestId': 'bridge-task-2',
        'input': <String, Object?>{},
      });

      expect(result.ok, isFalse);
      expect(result.errorCode, 'validation_error');
    });

    test('returns validation error when input is not a JSON object', () async {
      final RemoteBridgeTaskAssignmentHandler handler =
          RemoteBridgeTaskAssignmentHandler(
            consumeTask: ({
              String? requestId,
              required String tool,
              Map<String, Object?> input = const <String, Object?>{},
            }) async {
              fail('consumeTask should not be called for invalid payload.');
            },
          );

      final RemoteBridgeTaskResult result = await handler.handle(<String, Object?>{
        'requestId': 'bridge-task-3',
        'tool': 'stop_all',
        'input': 'invalid',
      });

      expect(result.ok, isFalse);
      expect(result.errorCode, 'validation_error');
      expect(result.tool, 'stop_all');
    });
  });
}
