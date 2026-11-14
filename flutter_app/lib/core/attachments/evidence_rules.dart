import 'dart:typed_data';

/// @module core/attachments/evidence_rules
/// @purpose 기기에서 고른 영수증 · 사진을 서버로 보내기 전에 손본다. 화면도 기기 기능도 쓰지 않는
///          순수한 규칙이라 그대로 시험할 수 있다.
///          - 종류는 파일 앞머리로 알아낸다 (이름과 확장자는 믿지 않는다).
///            서버(src/server/services/file.service.mjs)가 받는 네 가지만 통과시킨다.
///          - 사진(JPEG)에 들어 있는 촬영 위치 · 기기 정보를 지운다.
///          - 10MB를 넘으면 올리지 않는다.
///          - 파일 이름에서 경로와 이상한 글자를 뺀다.

/// 파일을 붙이지 못한 까닭
enum EvidenceProblem {
  /// 10MB를 넘는다
  tooLarge,

  /// 사진(JPG · PNG · WebP)이나 PDF가 아니다
  unsupportedType,

  /// 파일을 읽지 못했다
  unreadable,

  /// 이 기기에서는 고를 수 없다 (카메라가 없는 기기 등)
  unavailable,
}

class EvidenceException implements Exception {
  final EvidenceProblem problem;
  const EvidenceException(this.problem);

  @override
  String toString() => 'EvidenceException(${problem.name})';
}

/// 손보기를 마친, 올릴 준비가 된 파일
class PickedEvidence {
  final String name;
  final String mime;
  final Uint8List bytes;

  const PickedEvidence({
    required this.name,
    required this.mime,
    required this.bytes,
  });

  int get size => bytes.length;
}

class EvidenceRules {
  EvidenceRules._();

  /// 서버와 같은 한도
  static const int maxBytes = 10 * 1024 * 1024;

  static const Map<String, String> _extensionOf = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'application/pdf': 'pdf',
  };

  /// 파일 앞머리로 종류를 알아낸다. 받지 않는 종류면 null.
  static String? sniffMime(List<int> b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (b.length >= 8 &&
        b[0] == 137 &&
        b[1] == 80 &&
        b[2] == 78 &&
        b[3] == 71 &&
        b[4] == 13 &&
        b[5] == 10 &&
        b[6] == 26 &&
        b[7] == 10) {
      return 'image/png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 && // R
        b[1] == 0x49 && // I
        b[2] == 0x46 && // F
        b[3] == 0x46 && // F
        b[8] == 0x57 && // W
        b[9] == 0x45 && // E
        b[10] == 0x42 && // B
        b[11] == 0x50) {
      return 'image/webp';
    }
    if (b.length >= 5 &&
        b[0] == 0x25 && // %
        b[1] == 0x50 && // P
        b[2] == 0x44 && // D
        b[3] == 0x46 && // F
        b[4] == 0x2D) {
      return 'application/pdf';
    }
    return null;
  }

  /// JPEG에서 촬영 정보 덩어리를 뺀다: 위치 · 기기 · 시각이 든 EXIF와 XMP(APP1),
  /// 저작자 정보가 든 IPTC(APP13), 메모(COM). 그림과 색 정보(JFIF · ICC)는 그대로 둔다.
  /// 구조를 읽을 수 없으면 손대지 않고 돌려준다.
  ///
  /// 사진이 돌아가 보이지 않게 하는 "방향" 값도 EXIF 안에 있다. 그래서 기기 쪽
  /// (안드로이드 ReloEvidence.kt)에서 사진을 바로 세워 다시 저장한 뒤에 이 함수를 거친다.
  static Uint8List stripJpegMetadata(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return bytes;
    final out = BytesBuilder(copy: false);
    out.add(const [0xFF, 0xD8]);
    var i = 2;
    var removed = false;
    while (i < bytes.length) {
      if (bytes[i] != 0xFF) return bytes; // 덩어리 경계가 아니다
      if (i + 1 >= bytes.length) return bytes;
      final marker = bytes[i + 1];
      if (marker == 0xFF) {
        i += 1; // 채움 바이트
        continue;
      }
      // 그림 데이터가 시작되면(SOS) 나머지는 그대로 붙인다
      if (marker == 0xDA || marker == 0xD9) {
        out.add(Uint8List.sublistView(bytes, i));
        return removed ? out.toBytes() : bytes;
      }
      // 길이가 없는 표식
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        out.add([0xFF, marker]);
        i += 2;
        continue;
      }
      if (i + 3 >= bytes.length) return bytes;
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      final end = i + 2 + length;
      if (length < 2 || end > bytes.length) return bytes;
      final drop = marker == 0xE1 || marker == 0xED || marker == 0xFE;
      if (drop) {
        removed = true;
      } else {
        out.add(Uint8List.sublistView(bytes, i, end));
      }
      i = end;
    }
    return bytes; // 그림 데이터를 만나지 못했다: 온전한 JPEG가 아니다
  }

  /// 촬영 정보(EXIF)가 남아 있는지. 시험과 확인용.
  static bool hasJpegExif(List<int> bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return false;
    var i = 2;
    while (i + 3 < bytes.length) {
      if (bytes[i] != 0xFF) return false;
      final marker = bytes[i + 1];
      if (marker == 0xFF) {
        i += 1;
        continue;
      }
      if (marker == 0xDA || marker == 0xD9) return false;
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (length < 2) return false;
      if (marker == 0xE1) return true;
      i += 2 + length;
    }
    return false;
  }

  /// 경로와 이상한 글자를 빼고, 확장자를 실제 종류에 맞춘다.
  static String safeName(String raw, String mime, {String fallback = 'evidence'}) {
    final ext = _extensionOf[mime] ?? 'bin';
    var name = raw.split(RegExp(r'[\\/]')).last;
    name = name
        .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final dot = name.lastIndexOf('.');
    var stem = dot > 0 ? name.substring(0, dot) : name;
    stem = stem.replaceAll(RegExp(r'^\.+'), '').trim();
    if (stem.isEmpty) stem = fallback;
    if (stem.length > 60) stem = stem.substring(0, 60).trim();
    return '$stem.$ext';
  }

  /// 고른 파일 하나를 올릴 수 있는 모양으로 만든다. 안 되면 [EvidenceException].
  static PickedEvidence prepare({
    required String name,
    required List<int> bytes,
  }) {
    if (bytes.isEmpty) throw const EvidenceException(EvidenceProblem.unreadable);
    final mime = sniffMime(bytes);
    if (mime == null) {
      throw const EvidenceException(EvidenceProblem.unsupportedType);
    }
    var data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (mime == 'image/jpeg') data = stripJpegMetadata(data);
    if (data.length > maxBytes) {
      throw const EvidenceException(EvidenceProblem.tooLarge);
    }
    return PickedEvidence(name: safeName(name, mime), mime: mime, bytes: data);
  }
}
