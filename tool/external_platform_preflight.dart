import 'dart:convert';
import 'dart:io';

const Set<String> _safetyV0Tools = <String>{'get_status', 'stop_all'};

Future<void> main(List<String> args) async {
  final _Args parsed = _Args.parse(args);
  if (parsed.help) {
    stdout.writeln(_usage);
    return;
  }

  final _ConnectorInput connector = _loadConnector(parsed);
  final List<String> errors = connector.validationErrors;
  if (errors.isNotEmpty) {
    _writeEvidence(
      parsed.evidenceOut,
      _buildReport(
        parsed: parsed,
        connector: connector,
        result: 'FAIL',
        sections: <String>[
          '## Validation Errors',
          for (final String error in errors) '- $error',
        ],
      ),
    );
    stderr.writeln('Connector preflight failed:');
    for (final String error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 2;
    return;
  }

  final Uri toolCallUri = _toolCallUri(connector.connectorUrl);
  if (parsed.dryRun) {
    final String report = _buildReport(
      parsed: parsed,
      connector: connector,
      result: 'DRY_RUN_PASS',
      sections: <String>[
        '## Derived Request',
        '- Tool call URL: `$toolCallUri`',
        '- Auth header: `Authorization: Bearer ${connector.maskedToken}`',
        '- Allowed tools: `${connector.tools.join(',')}`',
        '',
        '## Not Executed',
        '- Network calls were skipped because `--dry-run` was set.',
      ],
    );
    _writeEvidence(parsed.evidenceOut, report);
    stdout.writeln(report);
    return;
  }

  final _HttpCheck getStatus = await _postToolCall(
    uri: toolCallUri,
    token: connector.authToken,
    requestId: '${parsed.platformSlug}-get-status',
    tool: 'get_status',
    input: const <String, Object?>{},
  );
  final _HttpCheck unsafeTool = await _postToolCall(
    uri: toolCallUri,
    token: connector.authToken,
    requestId: '${parsed.platformSlug}-set-suck-reject',
    tool: 'set_suck',
    input: const <String, Object?>{'intensity': 10, 'mode': 1},
  );

  final bool getStatusPass =
      getStatus.statusCode == HttpStatus.ok &&
      getStatus.body['ok'] == true &&
      (getStatus.body['result'] is Map<String, dynamic>) &&
      !(getStatus.body['result'] as Map<String, dynamic>).containsKey(
        'deviceId',
      );
  final bool unsafePass =
      unsafeTool.statusCode == HttpStatus.badRequest &&
      unsafeTool.body['ok'] == false;
  final bool pass = getStatusPass && unsafePass;

  final String report = _buildReport(
    parsed: parsed,
    connector: connector,
    result: pass ? 'PASS' : 'FAIL',
    sections: <String>[
      '## HTTP Evidence',
      _checkLine('get_status', getStatus, getStatusPass),
      _checkLine('set_suck rejected', unsafeTool, unsafePass),
      '',
      '## Boundary',
      '- This validates the connector endpoint used by an external platform.',
      '- It does not prove ChatGPT/Claude UI configuration unless run against the same connector details used in that platform.',
    ],
  );
  _writeEvidence(parsed.evidenceOut, report);
  stdout.writeln(report);
  if (!pass) {
    exitCode = 1;
  }
}

String _checkLine(String label, _HttpCheck check, bool pass) {
  return '- ${pass ? 'PASS' : 'FAIL'} `$label`: HTTP ${check.statusCode}, body `${jsonEncode(check.body)}`';
}

Future<_HttpCheck> _postToolCall({
  required Uri uri,
  required String token,
  required String requestId,
  required String tool,
  required Map<String, Object?> input,
}) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(
      jsonEncode(<String, Object?>{
        'requestId': requestId,
        'tool': tool,
        'input': input,
      }),
    );
    final HttpClientResponse response = await request.close();
    final String body = await utf8.decodeStream(response);
    final Object? decoded = body.trim().isEmpty ? null : jsonDecode(body);
    return _HttpCheck(
      statusCode: response.statusCode,
      body: decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{},
    );
  } finally {
    client.close(force: true);
  }
}

_ConnectorInput _loadConnector(_Args args) {
  if (args.cardPath != null) {
    final Object? decoded = jsonDecode(File(args.cardPath!).readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Connector card JSON must be an object.');
    }
    return _ConnectorInput.fromCard(decoded.cast<String, Object?>());
  }
  return _ConnectorInput(
    connectorUrl: args.connectorUrl ?? '',
    authToken: args.token ?? '',
    tools: args.tools,
  );
}

Uri _toolCallUri(String connectorUrl) {
  final Uri uri = Uri.parse(connectorUrl);
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/mobile-bridge/tool-call',
  );
}

String _buildReport({
  required _Args parsed,
  required _ConnectorInput connector,
  required String result,
  required List<String> sections,
}) {
  return <String>[
    '# External Platform Connector Preflight',
    '',
    '| Field | Value |',
    '|---|---|',
    '| Platform | `${parsed.platform}` |',
    '| Result | `$result` |',
    '| Connector URL | `${connector.connectorUrl}` |',
    '| Token | `${connector.maskedToken}` |',
    '| Tools | `${connector.tools.join(',')}` |',
    '| Dry run | `${parsed.dryRun}` |',
    '',
    ...sections,
    '',
  ].join('\n');
}

void _writeEvidence(String? path, String report) {
  if (path == null || path.isEmpty) {
    return;
  }
  File(path).writeAsStringSync(report);
}

class _HttpCheck {
  const _HttpCheck({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

class _ConnectorInput {
  const _ConnectorInput({
    required this.connectorUrl,
    required this.authToken,
    required this.tools,
  });

  factory _ConnectorInput.fromCard(Map<String, Object?> card) {
    final Object? auth = card['auth'];
    final Map<String, Object?> authJson = auth is Map
        ? auth.cast<String, Object?>()
        : const <String, Object?>{};
    final Object? tools = card['tools'];
    return _ConnectorInput(
      connectorUrl: card['connectorUrl']?.toString() ?? '',
      authToken: authJson['token']?.toString() ?? '',
      tools: tools is List
          ? tools.map((Object? value) => value.toString()).toList()
          : const <String>[],
    );
  }

  final String connectorUrl;
  final String authToken;
  final List<String> tools;

  String get maskedToken {
    if (authToken.length <= 8) {
      return authToken;
    }
    return '${authToken.substring(0, 4)}...'
        '${authToken.substring(authToken.length - 4)}';
  }

  List<String> get validationErrors {
    final List<String> errors = <String>[];
    final Uri? uri = Uri.tryParse(connectorUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      errors.add('Connector URL is invalid.');
    }
    if (authToken.trim().isEmpty) {
      errors.add('Bearer token is required.');
    }
    final Set<String> toolSet = tools.toSet();
    if (!toolSet.containsAll(_safetyV0Tools)) {
      errors.add('Safety V0 tools must include get_status and stop_all.');
    }
    if (!_safetyV0Tools.containsAll(toolSet)) {
      errors.add('Connector includes tools outside Safety V0.');
    }
    return errors;
  }
}

class _Args {
  const _Args({
    required this.platform,
    required this.dryRun,
    required this.help,
    required this.tools,
    this.cardPath,
    this.connectorUrl,
    this.token,
    this.evidenceOut,
  });

  factory _Args.parse(List<String> args) {
    String platform = 'manual-external-platform';
    String? cardPath;
    String? connectorUrl;
    String? token;
    String? evidenceOut;
    bool dryRun = false;
    bool help = false;
    List<String> tools = const <String>['get_status', 'stop_all'];

    for (int index = 0; index < args.length; index += 1) {
      final String arg = args[index];
      String nextValue() {
        if (index + 1 >= args.length) {
          throw FormatException('Missing value for $arg');
        }
        index += 1;
        return args[index];
      }

      switch (arg) {
        case '--help':
        case '-h':
          help = true;
        case '--dry-run':
          dryRun = true;
        case '--platform':
          platform = nextValue();
        case '--card':
          cardPath = nextValue();
        case '--connector-url':
          connectorUrl = nextValue();
        case '--token':
          token = nextValue();
        case '--tools':
          tools = nextValue()
              .split(',')
              .map((String value) => value.trim())
              .where((String value) => value.isNotEmpty)
              .toList(growable: false);
        case '--evidence-out':
          evidenceOut = nextValue();
        default:
          throw FormatException('Unknown argument: $arg');
      }
    }

    return _Args(
      platform: platform,
      dryRun: dryRun,
      help: help,
      cardPath: cardPath,
      connectorUrl: connectorUrl,
      token: token,
      tools: tools,
      evidenceOut: evidenceOut,
    );
  }

  final String platform;
  final String? cardPath;
  final String? connectorUrl;
  final String? token;
  final List<String> tools;
  final String? evidenceOut;
  final bool dryRun;
  final bool help;

  String get platformSlug {
    return platform
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('(^-|-\$)'), '');
  }
}

const String _usage = '''
Usage:
  dart run tool/external_platform_preflight.dart --card connector-card.json --platform "ChatGPT GPT Actions"
  dart run tool/external_platform_preflight.dart --connector-url https://example/mcp/claude --token TOKEN --dry-run

Options:
  --card PATH             Connector card JSON copied from ToyLink.
  --connector-url URL     Connector URL, used when --card is not provided.
  --token TOKEN           Bearer token, used when --card is not provided.
  --tools CSV             Allowed tools, default get_status,stop_all.
  --platform NAME         Label for the platform being checked.
  --dry-run               Validate inputs and derive request URL without network calls.
  --evidence-out PATH     Write markdown evidence report to this path.
''';
