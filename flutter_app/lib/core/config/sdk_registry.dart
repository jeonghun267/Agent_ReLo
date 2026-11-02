/// @module core/config/sdk_registry
/// @layer Core Infrastructure (SDK Compatibility & Privacy Audit)
/// @purpose [법적 안전장치 #8 외부 SDK 점검 & 패키지 버전 충돌 방지 관리]
///          앱 내 탑재된 모든 Flutter SDK 패키지 및 외부 API 연동 모듈의 버전 호환성,
///          라이선스, 개인정보 외부 전송 여부, 킬스위치(ON/OFF) 제어 상태를 중앙 관리합니다.

class SdkAuditEntry {
  final String id;
  final String name;
  final String pinnedVersion;
  final String sdkConstraint;
  final String license;
  final String purpose;
  final String dataShared;
  final bool isExternalNetwork;
  final bool canUserDisable;

  const SdkAuditEntry({
    required this.id,
    required this.name,
    required this.pinnedVersion,
    required this.sdkConstraint,
    required this.license,
    required this.purpose,
    required this.dataShared,
    required this.isExternalNetwork,
    required this.canUserDisable,
  });
}

class ReloSdkRegistry {
  static const String flutterFrameworkVersion = '3.41.9 (stable)';
  static const String dartSdkVersion = '3.11.5 (stable)';

  /// 패키지 충돌 방지 매트릭스 및 외부 SDK 개인정보 점검 목록
  static const List<SdkAuditEntry> auditedSdks = [
    SdkAuditEntry(
      id: 'flutter_sdk',
      name: 'Flutter Framework & Material UI',
      pinnedVersion: '3.41.9',
      sdkConstraint: 'sdk: flutter',
      license: 'BSD-3-Clause (상업적 무료 이용)',
      purpose: '크로스플랫폼 UI 렌더링, 접근성(Semantics), 키보드 포커스 탐색 엔진',
      dataShared: '외부 전송 없음 (기기 로컬 렌더링)',
      isExternalNetwork: false,
      canUserDisable: false,
    ),
    SdkAuditEntry(
      id: 'flutter_localizations',
      name: 'flutter_localizations + intl',
      pinnedVersion: '0.20.2 (SDK Pin 고정)',
      sdkConstraint: '^0.20.2',
      license: 'BSD-3-Clause (상업적 무료 이용)',
      purpose: '한국어·영어·일본어·중국어 4개국어 로케일 및 통화/날짜 포맷팅 (dependency_overrides로 구형 0.18/0.19 충돌 차단)',
      dataShared: '외부 전송 없음 (기기 로컬 포맷팅)',
      isExternalNetwork: false,
      canUserDisable: false,
    ),
    SdkAuditEntry(
      id: 'core_collections',
      name: 'collection · characters · meta · vector_math',
      pinnedVersion: '1.19.1 / 1.4.1 / 1.17.0 / 2.2.0',
      sdkConstraint: 'Flutter 3.41.9 SDK 내부 고정 버전 일치',
      license: 'BSD-3-Clause (상업적 무료 이용)',
      purpose: '불변 컬렉션 연산, 유니코드 문자열 처리 및 3D 블루 오브 궤적 벡터 연산',
      dataShared: '외부 전송 없음',
      isExternalNetwork: false,
      canUserDisable: false,
    ),
    SdkAuditEntry(
      id: 'gemini_ai_bridge',
      name: 'Google Gemini 2.5 Flash API (백엔드 프록시 연동)',
      pinnedVersion: 'v1beta (REST Proxy)',
      sdkConstraint: 'Server-side isolated',
      license: 'Google Cloud / Gemini API Terms',
      purpose: '주문 영수증 자동 읽기, 한국어 파손 사유 외국어 번역, 쇼핑몰 답장 3줄 요약',
      dataShared: '사용자가 명시적으로 동의(Opt-in)한 경우에 한해 마스킹된 주문 텍스트만 일회성 전송 (모델 학습 미사용)',
      isExternalNetwork: true,
      canUserDisable: true,
    ),
    SdkAuditEntry(
      id: 'resend_mail_bridge',
      name: 'Resend Transactional Email API (백엔드 발송)',
      pinnedVersion: 'v1 (HTTPS REST)',
      sdkConstraint: 'Server-side isolated',
      license: 'Resend Commercial Terms',
      purpose: '이메일 본인 인증 링크 및 비밀번호 재설정 링크 발송 (모든 메일에 원클릭 수신거부 헤더 포함)',
      dataShared: '수신자 이메일 주소 (수신거부 시 즉시 발송 차단)',
      isExternalNetwork: true,
      canUserDisable: true,
    ),
  ];

  /// 제3자 광고/추적 SDK 미탑재 보증 내역
  static const List<String> blockedTrackerSdks = [
    'Facebook App Events / Meta Pixel (미탑재 · 광고 추적 안 함)',
    'Google Mobile Ads / AdMob IDFA·AAID 수집기 (미탑재)',
    'AppsFlyer / Adjust / Branch 행태정보 브로커 SDK (미탑재)',
    '무단 클립보드·연락처·위치정보 백그라운드 수집 모듈 (미탑재)',
  ];
}
