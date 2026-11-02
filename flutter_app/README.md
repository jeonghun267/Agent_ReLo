<div align="center">

# ReLo App (`flutter_app/`)

**해외 직구 반품·교환·환불 원스톱 기록 및 실제 카드 취소·통장 입금 확인 공식 Flutter 애플리케이션**

![Flutter](https://img.shields.io/badge/Flutter_3.41-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart_3.11-0175C2?style=flat-square&logo=dart&logoColor=white)
![Material 3](https://img.shields.io/badge/Material_3-1B64DA?style=flat-square)
![WCAG AAA](https://img.shields.io/badge/Accessibility-WCAG_AAA-10B981?style=flat-square)

</div>

> 🌐 **웹 서비스(React 19 + Node.js 백엔드) 문서**: 웹 프론트엔드 및 백엔드 서버 설명은 루트의 **[`../README.md`](../README.md)**에서 별도로 관리됩니다.

---

## 1. 다른 컴퓨터에서 클론(`git clone`) 후 바로 실행하는 방법

다른 컴퓨터에서 저장소를 클론 받으신 뒤에도 복잡한 환경변수 설정 없이 **그냥 바로 실행됩니다.**

### ① Flutter 앱만 바로 켜서 볼 때 (오프라인/데모 모드 자동 작동)
백엔드 서버를 켜지 않아도 앱 자체에 내장된 오프라인 데모 보관함이 자동으로 작동하여 모든 화면과 기능을 즉시 테스트할 수 있습니다.

```bash
git clone https://github.com/jeonghun267/Agent_ReLo.git
cd Agent_ReLo/flutter_app
flutter pub get
flutter run   # 또는 flutter run -d windows / chrome / edge / android / ios
```
*(VS Code나 Android Studio에서 `flutter_app` 폴더를 열고 바로 **Run (F5)** 버튼을 누르셔도 자동으로 `pub get`이 진행되면서 즉시 켜집니다.)*

### ② ReLo 백엔드 서버(SQLite DB)까지 함께 연결해서 볼 때
- **터미널 1 (루트 폴더에서 백엔드 서버 실행 — `4180` 포트)**:
  ```bash
  npm install
  npm start
  ```
- **터미널 2 (Flutter 앱 실행)**:
  ```bash
  npm run flutter:get
  npm run flutter:run
  ```

### 💡 다른 PC에서 클론 시 패키지·경로 에러 없이 바로 실행되는 이유
1. **패키지 버전 핀 고정 (`dependency_overrides`)**: [`pubspec.yaml`](./pubspec.yaml)과 [`pubspec.lock`](./pubspec.lock)에 Flutter 3.41 / Dart 3.11 호환 버전(`intl 0.20.2`, `collection 1.19.1`, `characters 1.4.1`, `meta 1.17.0`, `vector_math 2.2.0`, `material_color_utilities 0.13.0`, `path 1.9.1`)이 정확히 고정되어 있어 구형·신형 패키지 버전 충돌이 원천 차단됩니다.
2. **로컬 PC 경로 파일 제외 (`.gitignore`)**: 특정 PC의 사용자 계정 경로가 적히는 `.dart_tool/` 및 `build/` 폴더는 [`.gitignore`](./.gitignore)로 제외되어 있으므로, 새 컴퓨터에서 `flutter pub get`을 실행하면 그 컴퓨터의 OS(Windows / macOS / Linux)와 경로에 맞게 자동 생성됩니다.

---

## 2. 핵심 기능 및 디자인

- **승인된 다크 에디토리얼 디자인**: 실배포 미드나잇 다크 블루(`#0F172A`) + 3D 블루 글로우 오브 엠블럼([`ReloOrbEmblem`](./lib/shared/widgets/relo_orb_emblem.dart)) + 토스 일렉트릭 블루(`#1B64DA`) + 라이트 모드 + **시각 약자용 WCAG AAA 초고대비 모드** 지원
- **5단계 간편 환불 신청 위저드**: 쇼핑몰·주문번호 입력 → 영수증 AI 스캔 → 우리말 사유 외국어 자동 번역 → 영수증 집 주소 자동 마스킹 및 10MB 증빙 첨부 → 필수/선택 동의 확인 후 제출
- **8개국 통화 무오차 환불 통장**: `USD`, `JPY`, `CNY`, `EUR`, `KRW`, `GBP`, `CAD`, `AUD` 소수점/정수 통화별 분리 집계
- **실제 카드 취소·통장 입금 확인 원장**: 판매자의 "환불해 줄게요" 약속 금액과 실제 내 카드/통장에 돌아온 입금 금액을 대조하여 미입금 차액을 끝까지 추적
- **4개 국어 원클릭 전환**: 한국어(`KO`) · 영어(`EN`) · 중국어(`ZH`) · 일본어(`JA`) 실시간 전환

---

## 3. 고소 방지 필수 20대 법적·개인정보·접근성 보호망 완비

앱 내 하단 **`법적보호 20선`** 탭([`legal_center_screen.dart`](./lib/features/compliance/legal_center_screen.dart)) 및 전체 양식에 아래 20가지 필수 요건이 실제 작동 코드로 구현되어 있습니다:

| 번호 | 필수 보호 항목 | 구현 위치 |
|---|---|---|
| 1 ~ 4 | **개인정보 처리방침 · 이용약관 · 환불정책 · 쿠키정책** | [`compliance_data.dart`](./lib/features/compliance/compliance_data.dart), [`legal_center_screen.dart`](./lib/features/compliance/legal_center_screen.dart) |
| 5 | **쿠키동의 배너** (거절·필수만 허용과 전체 동의 대등 배치) | [`cookie_consent_banner.dart`](./lib/features/compliance/cookie_consent_banner.dart) |
| 6 & 9 | **입력 양식 동의항목 확인 & 다크패턴 방지** (기본 미체크 원칙) | [`auth_screen.dart`](./lib/features/auth/auth_screen.dart), [`wizard_screen.dart`](./lib/features/wizard/wizard_screen.dart) |
| 7 | **불필요한 개인정보 미수집** (주민번호·집 주소·카드 전체번호 미수집) | [`wizard_screen.dart`](./lib/features/wizard/wizard_screen.dart), [`claim_detail_screen.dart`](./lib/features/claims/claim_detail_screen.dart) |
| 8 | **외부 SDK 점검 및 사용자 전송 제어 스위치** | [`sdk_registry.dart`](./lib/core/config/sdk_registry.dart), [`legal_center_screen.dart`](./lib/features/compliance/legal_center_screen.dart) |
| 10 ~ 12 | **숨겨진 요금 0원 · 가짜후기 배제 · 근거없는 과장주장 배제** | [`home_screen.dart`](./lib/features/home/home_screen.dart), [`wizard_screen.dart`](./lib/features/wizard/wizard_screen.dart) |
| 13 ~ 15 | **접근성 대체 텍스트(`Semantics`) · 고대비 모드 · 키보드 전용 이동(`Tab`/`Enter`)** | [`relo_primitives.dart`](./lib/shared/widgets/relo_primitives.dart), [`relo_theme.dart`](./lib/core/theme/relo_theme.dart) |
| 16 | **사업자 정보 푸터** (상호, 대표자, 사업자번호, 주소, 분쟁조정 안내) | [`business_footer.dart`](./lib/features/compliance/business_footer.dart) |
| 17 | **아동 나이 확인 수집절차** (만 14세 이상 확인 및 법정대리인 동의 절차) | [`auth_screen.dart`](./lib/features/auth/auth_screen.dart) |
| 18 | **이메일 원클릭 수신거부 링크 및 즉시 거부 스위치** | [`settings_screen.dart`](./lib/features/settings/settings_screen.dart), [`legal_center_screen.dart`](./lib/features/compliance/legal_center_screen.dart) |
| 19 | **사용 이미지·글꼴 상업적 이용권 검증서** (OFL 오픈소스 폰트 & 자체 코드 그래픽) | [`compliance_data.dart`](./lib/features/compliance/compliance_data.dart) |
| 20 | **개인정보 즉시 영구 삭제요청 기능** (`POST /api/account/delete` 직결) | [`relo_store.dart`](./lib/shared/state/relo_store.dart), [`legal_center_screen.dart`](./lib/features/compliance/legal_center_screen.dart) |

---

## 4. 기능별 파일 구조 (Feature-First Architecture)

누가 나중에 프로젝트를 이어받아도 즉시 유지보수할 수 있도록 `core` / `shared` / `features` 3계층 구조로 설계되어 있습니다. (상세 설계는 [`ARCHITECTURE.md`](./ARCHITECTURE.md) 참고)

```text
flutter_app/
├── lib/
│   ├── main.dart                                # 앱 엔트리포인트 (한국어/다국어 로컬라이제이션 & 테마 주입)
│   ├── core/                                    # [1계층] 전역 설정 · 테마 · 네트워크 · 유틸
│   │   ├── config/sdk_registry.dart             # 탑재 SDK 버전 핀 레지스트리 및 외부 추적 SDK 차단 목록
│   │   ├── i18n/relo_i18n.dart                  # 4개 국어(KO/EN/ZH/JA) 사전
│   │   ├── network/api_client.dart              # Node 백엔드(:4180) 세션 쿠키 · CSRF · Idempotency 클라이언트
│   │   ├── theme/relo_theme.dart                # 다크(#0F172A) · 라이트 · WCAG AAA 초고대비 컬러 팔레트
│   │   └── utils/money_format.dart              # 8개국 통화 무오차 정수/소수 변환기
│   ├── shared/                                  # [2계층] 도메인 모델 · 상태 저장소 · 공통 위젯
│   │   ├── models/domain_models.dart            # 백엔드 1:1 호환 불변 도메인 모델 (ClaimView, LedgerEntry 등)
│   │   ├── state/relo_store.dart                # 중앙 상태 관리 스토어 및 오프라인 데모 폴백
│   │   └── widgets/                             # 앱 셸, 3D 오브 엠블럼, 키보드 포커스/접근성 내장 공통 버튼·카드
│   └── features/                                # [3계층] 도메인 기능별 화면 모듈
│       ├── home/home_screen.dart                # 메인 홈 화면
│       ├── wizard/wizard_screen.dart            # 5단계 환불 신청 위저드
│       ├── claims/                              # 내 환불 통장 목록 및 개별 클레임 상세 워크스페이스
│       ├── auth/auth_screen.dart                # 로그인 · 회원가입 (만 14세 확인 및 다크패턴 방지 동의)
│       ├── compliance/                          # 법적보호 20선 센터, 쿠키 배너, 사업자 푸터
│       └── settings/settings_screen.dart        # 테마/고대비 전환, 다국어, JSON 백업, 수신거부, 즉시 탈퇴
└── test/
    └── widget_test.dart                         # 390px 모바일 뷰포트 전체 탭 · 단위 검증 테스트
```

---

## 5. 정적 분석 및 테스트 실행

```bash
cd flutter_app

# 1) Dart 정적 분석 (에러·경고 0건 확인)
flutter analyze

# 2) 390px 모바일 뷰포트 통합 위젯 테스트
flutter test
```
*(Windows 환경에서는 [`test_flutter.bat`](./test_flutter.bat) 또는 [`run_flutter.bat`](./run_flutter.bat)으로도 바로 실행할 수 있습니다.)*
