# ReLo Flutter — 후임 개발자 인수인계 & 아키텍처 가이드 (`ARCHITECTURE.md`)

누가 프로젝트를 이어받아도 즉시 구조를 파악하고, 패키지 버전 충돌이나 법적 분쟁 없이 유지보수할 수 있도록 설계된 **기능별(Feature-First) 모듈 아키텍처** 문서입니다.

---

## 1. 기능별(Feature-First) 폴더 구조 원칙

기존의 화면/위젯 단순 나열 방식이 아니라, **도메인 기능 단위로 응집도 높게 격리(`lib/features/<기능명>/`)**하여 특정 기능을 수정할 때 다른 기능이 깨지지 않도록 설계했습니다.

```text
flutter_app/
├── pubspec.yaml                                  # Flutter 3.41.9 SDK 핀 호환 패키지 버전 + dependency_overrides
├── .metadata                                     # Flutter 프로젝트 SDK 리비전 메타데이터
├── android/                                      # AndroidManifest.xml (INTERNET 권한만 선언, 위치/연락처/광고ID 미수집)
├── ios/                                          # Info.plist (사진 보관함 최소 목적 고지)
├── web/                                          # index.html & manifest.json
└── lib/
    ├── main.dart                                 # 앱 루트 (flutter_localizations, 테마, 5탭 라우터)
    ├── core/                                     # [1계층: 비즈니스 무관 공통 인프라]
    │   ├── config/sdk_registry.dart              # 외부 SDK 점검표 & 패키지 버전 호환성 레지스트리
    │   ├── i18n/relo_i18n.dart                   # 4개국어(KO/EN/JA/ZH) 다국어 사전
    │   ├── network/api_client.dart               # 세션 쿠키, CSRF, If-Match, Idempotency-Key HTTP 클라이언트
    │   ├── theme/relo_theme.dart                 # 미드나잇 다크(#0F172A) / 라이트(#F9FAFB) / 초고대비(WCAG AAA) 테마
    │   └── utils/money_format.dart               # 8개국 통화 무오차 정수(Minor Unit) 계산기
    ├── shared/                                   # [2계층: 앱 전역 공유 모델·상태·접근성 프리미티브]
    │   ├── models/domain_models.dart             # User, ClaimView, CookieConsentChoice 등 불변 모델
    │   ├── state/relo_store.dart                 # 전역 스토어 (실서버 API 연동 + 오프라인 폴백 + 법적 동의 상태)
    │   └── widgets/
    │       ├── relo_app_shell.dart               # 상단바 + 키보드 단축키(Alt+1~5) + 쿠키 배너 + 5탭 바
    │       ├── relo_orb_emblem.dart              # Semantics 대체 텍스트 내장 3D 블루 오브 엠블럼
    │       └── relo_primitives.dart              # FocusableActionDetector(Tab/Enter) & ReloConsentCheckbox
    └── features/                                 # [3계층: 기능별(Feature-First) 독립 모듈]
        ├── home/home_screen.dart                 # [홈] 승인 디자인 + 숨겨진 요금 0원 + 과장없는 지표 + 사업자 푸터
        ├── wizard/wizard_screen.dart             # [신청하기] 5단계 위저드 + 최소수집 안내 + 제출 전 필수/선택 동의
        ├── claims/
        │   ├── my_claims_screen.dart             # [내 환불] 통화별 환불 통장 + 상태 필터 + 클레임 카드
        │   └── claim_detail_screen.dart          # [환불 상세] AI 외국어 초안 + 판매자 답장 요약 + 실제 입금 기록
        ├── auth/auth_screen.dart                 # [인증] 만 14세 연령 확인 + 다크패턴 없는 필수/선택 동의 양식
        ├── compliance/                           # [법적보호 20선] 고소 방지 20대 안전장치 전담 모듈
        │   ├── compliance_data.dart              # 20대 체크리스트, 처리방침/약관/환불/쿠키 전문, 사업자 정보, 라이선스
        │   ├── cookie_consent_banner.dart        # 거절·동의 1:1 동등 배치 쿠키 배너
        │   ├── business_footer.dart              # 전자상거래법 사업자 정보 & 6대 정책 바로가기 푸터
        │   └── legal_center_screen.dart          # 20대 법적 보호 센터 화면
        └── settings/settings_screen.dart         # [설정] 테마/고대비 전환, 이메일 원클릭 수신거부, 즉시 탈퇴/파기
```

---

## 2. 패키지 버전 충돌 방지 규칙 (`pubspec.yaml`)

Flutter 프로젝트에서 가장 흔히 발생하는 빌드 오류는 `flutter_localizations`가 요구하는 `intl`, `collection`, `meta`, `characters`, `vector_math`, `material_color_utilities` 버전과 외부 서드파티 패키지의 구형 의존성이 충돌하는 현상입니다.

이를 방지하기 위해 [pubspec.yaml](file:///c:/Users/user_34/Agent_ReLo/flutter_app/pubspec.yaml)에 다음 두 가지 안전장치를 적용했습니다:
1. **Flutter 3.41.9 / Dart 3.11.5 SDK 내부 핀 버전과 100% 일치**:
   - `flutter_localizations: sdk: flutter`
   - `intl: ^0.20.2`, `collection: ^1.19.1`, `characters: ^1.4.1`, `meta: ^1.17.0`, `vector_math: ^2.2.0`, `material_color_utilities: ^0.13.0`, `path: ^1.9.1`
2. **`dependency_overrides` 강제 잠금**:
   - 추후 새로운 패키지를 추가하더라도 하위 구형 패키지가 SDK 핀 버전을 덮어쓰지 못하도록 고정했습니다.

---

## 3. 웹/앱 고소 방지 20대 필수 항목 코드 매핑표

| 번호 | 필수 항목 | 적용된 소스 파일 |
| :--- | :--- | :--- |
| **1** | 개인정보 처리방침 | [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
| **2** | 이용약관 | [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
| **3** | 환불정책 | [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
| **4** | 쿠키정책 | [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart) |
| **5** | 쿠키동의 배너 | [cookie_consent_banner.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/cookie_consent_banner.dart) |
| **6** | 입력 양식 동의항목 확인 | [auth_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/auth/auth_screen.dart), [wizard_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/wizard/wizard_screen.dart), [relo_primitives.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_primitives.dart) (`ReloConsentCheckbox`) |
| **7** | 불필요한 개인정보 미수집 | [AndroidManifest.xml](file:///c:/Users/user_34/Agent_ReLo/flutter_app/android/app/src/main/AndroidManifest.xml), [wizard_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/wizard/wizard_screen.dart) |
| **8** | 외부 SDK 점검 | [sdk_registry.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/core/config/sdk_registry.dart), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
| **9** | 원하지 않는 선택 유도 금지 | [cookie_consent_banner.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/cookie_consent_banner.dart), [relo_primitives.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_primitives.dart) |
| **10** | 숨겨진 요금 없애기 | [home_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/home/home_screen.dart), [wizard_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/wizard/wizard_screen.dart) |
| **11** | 가짜후기 없애기 | [home_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/home/home_screen.dart), [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart) |
| **12** | 근거없는 주장 없애기 | [home_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/home/home_screen.dart), [business_footer.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/business_footer.dart) |
| **13** | 접근성 이미지 대체 텍스트 | [relo_orb_emblem.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_orb_emblem.dart), [relo_primitives.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_primitives.dart) (`Semantics`) |
| **14** | 글자·배경 색상대비 개선 | [relo_theme.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/core/theme/relo_theme.dart) (`highContrastDark` WCAG AAA 팔레트) |
| **15** | 키보드만으로 이동 가능 | [relo_app_shell.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_app_shell.dart) (`Alt+1~5`, `FocusTraversalGroup`), [relo_primitives.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/widgets/relo_primitives.dart) (`FocusableActionDetector`) |
| **16** | 사업자 정보 추가 | [business_footer.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/business_footer.dart) |
| **17** | 아동 나이 관련 수집절차 | [auth_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/auth/auth_screen.dart) (만 14세 확인 및 법정대리인 동의 절차) |
| **18** | 이메일 수신거부 링크 확인 | [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart), [settings_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/settings/settings_screen.dart) |
| **19** | 이미지·글꼴 이용권 확보 | [compliance_data.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/compliance_data.dart), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
| **20** | 개인정보 삭제요청 기능 | [relo_store.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/shared/state/relo_store.dart) (`deleteAccountAndPurgeAllData`), [legal_center_screen.dart](file:///c:/Users/user_34/Agent_ReLo/flutter_app/lib/features/compliance/legal_center_screen.dart) |
