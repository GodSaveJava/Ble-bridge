import 'dart:io';

import '../lib/bridge_server.dart';

Future<void> main(List<String> args) async {
  final BridgeServerConfig config = BridgeServerConfig.fromEnvironment();
  final BridgeServer server = BridgeServer(config: config);
  final HttpServer httpServer = await server.bind();

  stdout.writeln(
    'ToyLink Bridge server listening on '
    '${httpServer.address.address}:${httpServer.port}',
  );
  stdout.writeln('Public bridge URL: ${config.publicBaseUrl}');
  stdout.writeln('Connector path: ${config.connectorPath}');
}
