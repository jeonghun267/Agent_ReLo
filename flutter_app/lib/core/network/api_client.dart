import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// ReLo 백엔드(`src/server/app.mjs`)의 보안 정책을 100% 준수하는 네이티브 HTTP 클라이언트
/// - 세션 쿠키(`relo_session`) 자동 저장 및 전송
/// - 쓰기 요청 시 `Origin` 및 `X-CSRF-Token` 자동 주입
/// - 낙관적 락(`If-Match: <version>`) 및 멱등성 키(`Idempotency-Key`) 주입
/// - 파일 업로드 시 원시 바이너리(`application/octet-stream` / 이미지 MIME) 및 `X-File-Name` 전송
class ApiError implements Exception {
  final String message;
  final String code;
  final int status;
  final String? field;

  const ApiError(
    this.message, {
    this.code = 'error',
    this.status = 0,
    this.field,
  });

  @override
  String toString() => message;
}

class ReloApiClient {
  String baseUrl;
  String _csrfToken = '';
  String _sessionCookie = '';
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6);

  ReloApiClient({String? initialBaseUrl})
    : baseUrl = initialBaseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:4180';
      }
    } catch (_) {
      // Web or unsupported platform check fallback
    }
    return 'http://127.0.0.1:4180';
  }

  String get csrfToken => _csrfToken;
  bool get hasSession => _sessionCookie.isNotEmpty;

  void clearSession() {
    _csrfToken = '';
    _sessionCookie = '';
  }

  static String newIdempotencyKey() {
    final rng = math.Random();
    String hex(int digits) => List.generate(
      digits,
      (_) => rng.nextInt(16).toRadixString(16),
    ).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  Future<Map<String, dynamic>> requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    List<int>? rawBytes,
    Map<String, String>? headers,
    int? version,
    String? idempotencyKey,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final origin =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    HttpClientRequest req;
    try {
      req = await _httpClient.openUrl(method, uri);
    } catch (e) {
      throw const ApiError(
        '백엔드 서버(4180 포트)에 연결하지 못했어요. 로컬 체험 모드로 계속 이용할 수 있어요.',
        code: 'network',
        status: 0,
      );
    }

    req.headers.set('Accept', 'application/json');
    if (method != 'GET' && method != 'HEAD') {
      req.headers.set('Origin', origin);
      if (_csrfToken.isNotEmpty) {
        req.headers.set('X-CSRF-Token', _csrfToken);
      }
    }
    if (_sessionCookie.isNotEmpty) {
      req.headers.set('Cookie', 'relo_session=$_sessionCookie');
    }
    if (version != null) {
      req.headers.set('If-Match', version.toString());
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      req.headers.set('Idempotency-Key', idempotencyKey);
    }
    if (headers != null) {
      headers.forEach((k, v) => req.headers.set(k, v));
    }

    if (rawBytes != null) {
      req.contentLength = rawBytes.length;
      req.add(rawBytes);
    } else if (data != null) {
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      final encoded = utf8.encode(jsonEncode(data));
      req.contentLength = encoded.length;
      req.add(encoded);
    }

    final HttpClientResponse res = await req.close();

    // Extract session cookie if issued
    for (final cookie in res.cookies) {
      if (cookie.name == 'relo_session') {
        _sessionCookie = cookie.value;
      }
    }

    final responseBody = await utf8.decoder.bind(res).join();
    Map<String, dynamic> decoded = {};
    if (responseBody.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(responseBody);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {}
    }

    if (decoded['csrf'] is String) {
      _csrfToken = decoded['csrf'] as String;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiError(
        (decoded['message'] ?? '요청을 처리하지 못했어요.').toString(),
        code: (decoded['error'] ?? 'error').toString(),
        status: res.statusCode,
        field: decoded['field']?.toString(),
      );
    }

    return decoded;
  }
}
