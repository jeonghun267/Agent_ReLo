<div align="center">

# ReLo 앱 (`flutter_app/`)

**해외직구 반품·교환·환불을 신청하고, 판매자가 약속한 돈이 실제로 내 통장에 들어올 때까지 따라가는 Flutter 앱**

![Flutter](https://img.shields.io/badge/Flutter_3.41-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart_3.11-0175C2?style=flat-square&logo=dart&logoColor=white)
![Material 3](https://img.shields.io/badge/Material_3-1B64DA?style=flat-square)

</div>

> 웹 서비스(React 19 + Node.js)는 루트의 [`README.md`](../README.md)에서 설명합니다. 앱은 같은 백엔드(`:4180`)를 쓰고, 서버가 없으면 내장 데모 데이터로 동작합니다.

---

## 화면

| 홈 | 신청 | 내 환불 | 신청 완료 | AI 도우미 |
|---|---|---|---|---|
| 지구본 배경 위에 "3분 만에 환불 신청하기". 아래에 돌려받을 돈과 오늘 할 일 | 한 화면에 질문 하나. 영수증 스캔이 맨 위 | 건마다 "약속 → 입금" 막대와 D-day. 카드를 누르면 그대로 커지며 상세가 열림 | 지구본이 앞으로 나와 그 나라에서 비행기가 출발 | 떠 있는 캐릭터를 누르면 아래에서 대화 창이 올라옴. 내 환불 기록을 보고 답하고, 필요한 화면으로 가는 버튼을 줌 |

- **지구본**은 웹 랜딩과 같은 코드를 Dart Canvas로 옮긴 것입니다 ([`refund_globe.dart`](./lib/shared/widgets/refund_globe.dart)). 외부 패키지 없이 해안선 좌표를 직접 투영합니다.
- 하단 탭은 **홈 · 내 환불 · ＋신청 · 설정** 4개입니다. 약관·정책과 언어·테마·고대비는 설정 안에 있습니다.
- 앱을 켜면 로고 고리가 그려지고 상단 바 자리로 옮겨 가면서 홈이 나타납니다 (0.9초, [`relo_intro.dart`](./lib/shared/widgets/relo_intro.dart)).
- **AI 도우미**는 화면 오른쪽 아래에 떠 있는 ReLo 캐릭터입니다 ([`assistant_sheet.dart`](./lib/features/assistant/assistant_sheet.dart), [`relo_mascot.dart`](./lib/shared/widgets/relo_mascot.dart)). 끌어서 옮길 수 있고 설정에서 끌 수 있습니다. 환불 상세의 "이 건 물어보기"로 열면 그 건을 두고 대화합니다. 답은 서버 `POST /api/ai/assistant`(Gemini)가 하고, 서버가 없으면 앱이 내 환불 기록으로 기본 안내를 합니다.
- 디자인 기준(색·간격·글자·움직임·문구)은 [`DESIGN.md`](./DESIGN.md)에 숫자로 적어 두었습니다.

## 기능

- **5단계 신청**: 쇼핑몰·주문번호 → 상품·금액 → 해결 방법·사유(외국어 자동 번역) → 영수증·사진(집 주소 자동 가림, 10MB) → 동의 후 등록
- **환불 통장**: USD · JPY · CNY · EUR · KRW · GBP · CAD · AUD 8개 통화를 소수점 단위까지 정확하게 따로 집계
- **입금 확인 원장**: 판매자가 약속한 금액과 실제 카드 취소·통장 입금 금액을 대조해 차액을 끝까지 추적
- **AI 도우미**: "내 환불 어디까지 왔어?", "독촉 메일 써 줘", "답장 해석해 줘" 같은 질문에 답하고 상세·메시지·답장·신청 화면으로 바로 보내 줌. 저장·전송은 하지 않음
- **4개 언어**: 한국어 · 영어 · 일본어 · 중국어
- **접근성**: 키보드만으로 모든 화면 이동(Tab, Enter, Alt+1~5), 고대비 모드, 모션 줄이기 설정을 따름
- **개인정보 보호**: 주민번호·통관번호·집 주소·카드 전체 번호를 받지 않음. 처리방침·약관·환불 정책·쿠키 설정·내 정보 삭제를 설정 > 약관·정책에서 봄

## 실행

```bash
cd flutter_app
flutter pub get
flutter run        # 또는 flutter run -d chrome / windows / android
```

백엔드까지 같이 보려면 루트에서 `npm install && npm start`(4180 포트)를 먼저 띄웁니다. Windows에서는 [`run_flutter.bat`](./run_flutter.bat)으로도 실행됩니다.

### 검사

```bash
flutter analyze
flutter test
```

## 구조

```text
lib/
├── main.dart                         # 테마·다국어·탭 라우팅·시작 연출
├── core/
│   ├── i18n/relo_i18n.dart           # 4개 언어 사전
│   ├── network/api_client.dart       # 세션 쿠키 · CSRF · If-Match · Idempotency-Key
│   ├── theme/relo_theme.dart         # 다크 · 라이트 · 고대비 팔레트
│   ├── theme/motion_tokens.dart      # 움직임 시간·곡선 (DESIGN.md 5절)
│   └── utils/                        # 통화 계산, D-day
├── shared/
│   ├── models/domain_models.dart     # 백엔드와 1:1인 불변 모델
│   ├── state/relo_store.dart         # 전역 상태, API 호출, 오프라인 데모 폴백
│   └── widgets/                      # 앱 셸(4탭), 시작 연출, 지구본, 버튼·카드·배지
└── features/
    ├── home/                         # 홈
    ├── wizard/                       # 5단계 신청 + 완료 화면
    ├── claims/                       # 내 환불 목록 · 상세
    ├── auth/                         # 로그인 · 회원가입
    ├── settings/                     # 화면 · 알림 · 백업 · 약관 · 탈퇴
    └── compliance/                   # 약관·정책 문서와 보호 항목
```

계층 설명은 [`ARCHITECTURE.md`](./ARCHITECTURE.md)에 있습니다.

## 쓰는 패키지

| 패키지 | 용도 |
|---|---|
| animations | 탭 전환(FadeThrough), 신청 단계(SharedAxis), 카드→상세(OpenContainer) |
| flutter_animate | 목록 카드 등장, 홈 첫 등장 |
| confetti | 신청 완료 · 입금 확인 축하 효과 |
| smooth_sheets | AI 도우미 대화 시트 (끌어서 닫기) |
| skeletonizer, lucide_icons_flutter | 로딩 뼈대 · 아이콘 (다음 단계에서 적용) |

## 아직 안 된 것

- 안드로이드 12+ 시스템 스플래시 배경색 맞추기 (`flutter_native_splash`)
- 쇼핑몰 선택·스캔 결과도 아래 시트로 바꾸기 (smooth_sheets)
- 웹 빌드는 서버와 통신하지 못해(`dart:io` HttpClient) 도우미가 늘 기본 안내로 답함. 실제 Gemini 답은 Android·iOS·Windows에서 확인 필요
- 도우미 대화는 앱을 켜 둔 동안만 기억함 (지난 대화 목록 없음)
- 실제 기기(Android · iOS)에서 확인. 지금까지는 웹과 테스트로만 확인했습니다
