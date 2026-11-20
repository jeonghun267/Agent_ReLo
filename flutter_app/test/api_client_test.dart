import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/network/api_client.dart';

/// 앱이 서버에 실제로 무엇을 실어 보내는지 본다 (이 컴퓨터 안의 시험용 서버로).
/// 화면 시험용 바인딩을 세우지 않으므로 진짜 HTTP로 주고받는다.
void main() {
  test('저장하는 요청에는 화면의 언어를 실어 보내고, 읽는 요청에는 싣지 않는다', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final seen = <String, String?>{};
    server.listen((request) async {
      seen[request.method] = request.headers.value('x-relo-locale');
      await request.drain<void>();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true}));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final api = ReloApiClient(
      initialBaseUrl: 'http://127.0.0.1:${server.port}',
    )..locale = 'ja';
    await api.requestJson('/api/claims');
    await api.requestJson('/api/claims', method: 'POST', data: {'title': 'x'});

    expect(seen['POST'], 'ja');
    expect(seen['GET'], isNull);
  });

  test('한글 · 일본어 · 중국어가 서버까지 깨지지 않고 가고, 서버의 한글 답도 그대로 돌아온다', () async {
    const line = '허브 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요. 電源が入りません。电源打不开。';
    const answer = '허브 2개 가운데 1개가 켜지지 않아 환불을 원하는 것으로 읽었어요.';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? received;
    String? fileName;
    server.listen((request) async {
      // 서버(Node)는 본문을 UTF-8로 읽는다
      final body = utf8.decode(await request.fold<List<int>>([], (all, part) => all..addAll(part)));
      if (request.uri.path == '/api/ai/intake') {
        received = (jsonDecode(body) as Map<String, dynamic>)['text'] as String?;
      } else {
        fileName = Uri.decodeComponent(request.headers.value('x-file-name') ?? '');
      }
      request.response
        ..headers.contentType = ContentType('application', 'json', charset: 'utf-8')
        ..add(utf8.encode(jsonEncode({'understood': answer})));
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final api = ReloApiClient(initialBaseUrl: 'http://127.0.0.1:${server.port}');
    final res = await api.requestJson(
      '/api/ai/intake',
      method: 'POST',
      data: {'text': line, 'items': const <Object>[], 'locale': 'ko'},
    );
    expect(received, line);
    expect(res['understood'], answer);

    // 파일 이름의 한글은 머리글에 그대로 실을 수 없어서 %로 바꿔 보낸다: 서버가 되돌리면 같아야 한다
    await api.requestJson(
      '/api/claims/clm_1/files',
      method: 'POST',
      rawBytes: '%PDF-1.7 order'.codeUnits,
      headers: {
        'Content-Type': 'application/pdf',
        'X-File-Name': Uri.encodeComponent('박스 파손 사진.pdf'),
      },
    );
    expect(fileName, '박스 파손 사진.pdf');
  });
}
