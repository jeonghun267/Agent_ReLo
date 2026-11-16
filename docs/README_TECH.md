# ReLo — 기술

ReLo를 만드는 데 쓴 기술을 **앱**과 **웹**으로 나누고, 그 안에서 부분별로 정리했습니다. (2026-11-16 기준)

- 무엇을 할 수 있는지는 → [기능](./README_FEATURES.md)
- 코드가 어디에 있고 무엇을 맡는지는 → [파트별](./README_PARTS.md)

## 한눈에 보기

| | 앱 | 웹 |
|---|---|---|
| 위치 | `flutter_app/` | 화면 `src/client/` · 서버 `src/server/` |
| 언어 | Dart 3.11, Kotlin(안드로이드 기기 기능) | TypeScript(화면), JavaScript ES Modules(서버) |
| 틀 | Flutter 3.41 · Material 3 | React 19 + Vite · Node.js 24 기본 HTTP 서버 |
| 저장 | 기기 안 설정 저장소 + 서버 | SQLite (`node:sqlite`) |
| 서버 | 웹과 같은 서버(4180 포트)를 씀. 없으면 내장 데모 데이터 | 자체 서버 |
| 검사 | `flutter analyze` · `flutter test` | `typecheck` · `lint` · `audit:client` · `check` · `test` |

---

## 앱

### 1. 언어와 틀

- **Flutter 3.41 / Dart 3.11 / Material 3**. `pubspec.yaml` 기준 최소 버전은 Dart 3.4, Flutter 3.22입니다.
- 안드로이드 기기 기능(사진, 공유, 알림)은 패키지를 더하지 않고 **Kotlin으로 직접** 만들었습니다.
- iOS 프로젝트는 없습니다 (Mac이 있어야 만들 수 있음).

### 2. 구조와 상태

- **기능별 폴더(Feature-First)**: `core/`(공통 기반) · `shared/`(모델·상태·위젯) · `features/`(화면).
- **전역 상태는 하나**: `ReloStore`(`ChangeNotifier`)를 `ReloScope`(`InheritedNotifier`)로 화면에 내려 줍니다. 상태 관리 패키지는 쓰지 않습니다.
- **모델**: 서버 응답과 1:1로 맞춘 바뀌지 않는(불변) 모델 (`shared/models/domain_models.dart`).

### 3. 서버와 통신

- `core/network/api_client.dart`가 세션 쿠키, CSRF 토큰, `If-Match`(버전), `Idempotency-Key`(같은 요청을 두 번 보내도 한 번만 처리)를 붙입니다.
- 서버 주소는 빌드할 때 `--dart-define=RELO_API_BASE=…`로 줍니다. 주지 않으면 개발용 주소(에뮬레이터는 `http://10.0.2.2:4180`)를 씁니다.
- 서버에 붙지 못하면 **앱에 들어 있는 데모 데이터**로 동작하고, 상단에 한 줄로 알립니다.
- `dart:io`의 `HttpClient`를 써서 Flutter 웹 빌드에서는 서버와 통신하지 못합니다.

### 4. 화면 그리기

- **지구본**: 외부 패키지 없이 해안선 좌표를 Canvas에 직접 투영합니다. 웹 첫 화면의 지구본과 같은 코드를 Dart로 옮겼습니다 (`refund_globe.dart`).
- **도우미 캐릭터 "말랑이"**: 그림 파일 없이 코드로 그립니다 (`relo_mascot.dart`).
- **아이콘**: 선 아이콘 한 가지(`lucide_icons_flutter`)만 쓰고, 화면에서는 `ReloIcons`의 이름으로만 가져옵니다.
- **테마**: 다크 · 라이트 · 고대비 팔레트 (`core/theme/relo_theme.dart`).
- 색 · 간격 · 글자 · 움직임 · 문구 기준은 [`flutter_app/DESIGN.md`](../flutter_app/DESIGN.md)에 숫자로 적어 두었습니다.

### 5. 움직임

| 패키지 | 쓰는 곳 |
|---|---|
| `animations` | 탭 전환(FadeThrough), 신청 단계(SharedAxis), 카드 → 상세(OpenContainer) |
| `flutter_animate` | 목록 줄 등장, 홈 첫 등장 |
| `confetti` | 신청 완료 · 입금 확인 축하 |
| `smooth_sheets` | 도우미 대화 창 (끌어서 닫기) |

- 시간과 곡선은 `core/theme/motion_tokens.dart` 한 곳에서 정합니다.
- 시작 연출(`relo_intro.dart`, 1.3초)은 기기의 시작 화면에서 로고 자리를 그대로 이어받습니다 (`splash_handoff.dart`).
- 기기의 "모션 줄이기" 설정을 따릅니다.

### 6. 기기 기능 (안드로이드)

- Dart와 Kotlin은 통로 하나(`MethodChannel('relo/native')`)로 이어집니다.
- `ReloEvidence.kt`: 기기의 카메라 앱 · 사진 고르기 · 파일 고르기를 부르고, 다른 앱에서 공유받은 파일을 읽습니다. 사진은 바로 세우고 2560px로 줄인 뒤 촬영 위치 같은 덧붙은 정보를 지웁니다.
- `ReloReminders.kt`: 알람 예약, 알림 표시, 기기를 다시 켰을 때 알람 다시 맞추기.
- 그래서 앱이 갖는 **권한은 셋뿐**입니다: 인터넷 · 알림 · 기기를 켰을 때 다시 맞추기. 카메라 · 사진첩 권한은 없습니다.

### 7. 기기에 저장하는 것

- `shared_preferences`: 도우미 지난 대화, 캐릭터 표시 여부, 마감 알림 설정.
- 로그인 정보는 기기에 저장하지 않습니다 (앱을 껐다 켜면 다시 로그인).

### 8. 다국어 · 계산 규칙

- 4개 언어 사전(`core/i18n/relo_i18n.dart`) + `flutter_localizations` · `intl`.
- 통화별 소수점 자리(`money_format.dart`), D-day(`dday.dart`), 입력 규칙(`input_rules.dart`).

### 9. 빌드와 검사

- 검사: `flutter analyze`, `flutter test` (시험 파일 3개: 기본 화면 · 화면 품질 · 기기 기능).
- APK: `flutter build apk --release --dart-define=RELO_API_BASE=…` (전체 약 54MB, arm64만 약 20MB). 지금은 **디버그 키로 서명**됩니다.
- 패키지 버전 충돌을 막으려고 `dependency_overrides`로 기본 패키지 버전을 고정했습니다.

---

## 웹

### 1. 화면 (React)

| 기술 | 쓰는 곳 |
|---|---|
| React 19 · TypeScript · Vite | 화면 전체. 화면별로 `lazy()`로 나눠 필요한 때 받음 |
| Tailwind CSS 4 | 스타일. 색 · 글꼴 토큰은 `styles/index.css` 한 곳 |
| TanStack Query | 서버에서 받은 값 보관 · 다시 받기 (`hooks/`) |
| TanStack Table | 내 환불 목록 표 |
| React Hook Form + Zod | 입력칸과 입력 검사. 오류 문구는 사전의 열쇠로 찾아 4개 언어로 보여 줌 |
| Motion | 화면 전환 · 등장 움직임 |
| lucide-react | 아이콘 (선 아이콘 한 가지) |
| Uppy · Cropper.js · PDF.js | 파일 올리기 · 사진 자르기 · PDF 미리보기 |
| canvas-confetti | 축하 효과 |
| @xyflow/react | 첫 화면의 5단계 흐름 그림 |

직접 만든 것:

- **라우터** (`lib/router.tsx`): 주소와 화면을 잇고, 메일 링크(`/#/verify/…`)도 알아봅니다.
- **다국어** (`i18n/`): 화면별 사전을 4개 언어로 두고, 모양이 서로 같은지 타입으로 검사합니다. `?lang=en`이나 헤더에서 바꿉니다.
- **지구본** (`features/landing/globeCanvasRenderer.ts`): Canvas에 대륙 좌표를 직접 그립니다.
- **패스키 호출** (`lib/passkey.ts`): 브라우저의 WebAuthn을 감쌉니다.
- **신청 이어 쓰기** (`lib/wizard-draft.ts`): 적던 신청을 브라우저의 `localStorage`에 계정별로 보관합니다. 글자와 단계만 담고 파일은 이름만 기억합니다. 불러올 때 형식 · 날짜를 확인해 망가졌거나 일주일 넘은 것은 버립니다.

### 2. 서버 (Node.js)

- **Node.js 24, 프레임워크 없음, 서버가 쓰는 외부 패키지 0개.** `package.json`의 패키지는 모두 화면용입니다.
- 계층: `http` → `routes` → `services` → `repositories` → SQLite, 그리고 순수 규칙만 담는 `domain`.
- 모든 부품은 `app.mjs` 한 곳에서 조립합니다. 그래서 시험에서는 가짜 AI · 가짜 메일함 · 가짜 구글을 끼워 넣을 수 있습니다.
- 계층 규칙(예: SQL은 `repositories`만)은 `tests/unit/architecture.test.mjs`가 소스를 읽어서 지키게 합니다.

### 3. 데이터 (SQLite)

- Node에 들어 있는 `node:sqlite`를 씁니다. 파일은 `.relo-data/relo.sqlite`.
- 표 14개: `users` `sessions` `claims` `files` `ledger` `drafts` `draft_submissions` `audit` `idempotency` `ai_usage` `purges` `email_tokens` `identities` `passkeys`.
- 구조 변경은 `repositories/migrations/NNN_이름.sql`을 **새로 더하는 방식**이고, 서버가 시작할 때 순서대로 한 번 적용합니다 (지금 3개).
- **본인 것만**: 모든 조회가 `owner_id`로 거릅니다. 남의 것은 404입니다.
- **동시에 고칠 때**: `version` + `If-Match`로 나중 요청을 거절합니다.
- **두 번 보내도 한 번만**: 생성 · 첨부 · 초안 · 입금 기록은 `Idempotency-Key`를 받습니다.
- **고칠 수 없는 표**: 입금 기록(`ledger`) · 메시지 버전(`drafts`) · 변경 이력(`audit`)은 DB 트리거로 수정 · 삭제를 막습니다.
- **금액**: 통화의 가장 작은 단위 정수로 저장합니다 (EUR 39.90 → 3990). 8개 통화를 서로 더하지 않습니다.

### 4. 보안

| 항목 | 방법 |
|---|---|
| 로그인 상태 | `relo_session` 쿠키 (HttpOnly, SameSite=Strict, 기본 7일) |
| 비밀번호 | `scrypt`로 바꿔 저장. 없는 이메일에도 같은 계산을 해서 걸리는 시간으로 계정 유무를 알 수 없음 |
| 요청 위조 막기 | CSRF 토큰 헤더 + Host · Origin 검사 |
| 화면에 끼워 넣기 막기 | CSP `default-src 'self'` (인라인 스크립트 · 스타일 금지, 외부 주소 금지) |
| 시도 제한 | 로그인 5분에 8번, 가입 시간당 10번, 비밀번호 찾기 주소당 시간당 3번 등 |
| 일회용 링크 | 토큰은 SHA-256 해시만 저장. 쓰면 바로 지움. 인증 24시간 · 비밀번호 30분 |
| 올린 파일 | PDF · PNG · JPEG · WebP만, 파일 첫 바이트로 종류 확인, 10MB까지 |

### 5. 로그인 방식

- **이메일 + 비밀번호**, 이메일 인증, 비밀번호 다시 정하기.
- **구글 로그인**: 인가 코드 + PKCE. 구글 SDK나 외부 스크립트 없이 서버가 직접 주고받습니다. `GOOGLE_CLIENT_ID` · `GOOGLE_CLIENT_SECRET`을 둘 다 넣어야 켜집니다.
- **패스키**: WebAuthn 검증을 `node:crypto`만으로 합니다 (CBOR 해석 직접 구현, ES256 · RS256, 사용자 확인 필수). 공개키만 저장합니다. `PASSKEY_RP_ID`를 넣어야 켜집니다.

### 6. AI (Google Gemini)

- SDK 없이 REST로 부릅니다. 기본 모델 `gemini-3.5-flash-lite`.
- `gemini` · `fake`(개발 · 시험) · `disabled` 셋 중 하나를 끼웁니다.
- 프롬프트마다 **요청 만들기 + 응답 틀 + 응답 다시 검사**가 한 파일에 있습니다 (`ai/prompts/`).
- 안전장치: 동의한 사용자만, 결과는 미리보기(자동 저장 없음), 사용자별 시간당 30번, 30초 제한, 실패하면 한 번만 다시.
- 자세한 것은 [`AI.md`](./AI.md).

### 7. 메일

- Resend REST API를 SDK 없이 부릅니다. 같은 메일이 두 번 가지 않게 `Idempotency-Key`를 붙이고, 실패하면 한 번만 다시 보냅니다.
- 개발 · 시험은 `console`(링크를 서버 기록에 찍음), 키가 없는 운영은 `disabled`입니다.

### 8. 빨리 뜨게 하는 것

- **압축 전송**: 글자로 된 파일(화면 코드 · 스타일 · 첫 페이지)을 Brotli 또는 gzip으로 눌러 보냅니다. 한 번 누른 결과는 파일이 바뀔 때까지 기억합니다. 화면 코드 873KB → 252KB.
- **오래 보관**: 이름에 해시가 붙은 파일은 브라우저가 1년 보관합니다.
- **뼈대 먼저**: 화면 코드를 받는 동안 `index.html`에 들어 있는 위쪽 줄과 자리 표시가 먼저 보입니다.
- **나눠 받기**: 신청 · 내 환불 · 상세 · 설정 · 로그인 화면은 들어갈 때 받습니다.
- **글꼴도 나눠 받기**: Pretendard를 글자 묶음 92개로 나눈 공식 판(`pretendard@1.3.9`의 dynamic subset)을 저장소에 넣어 직접 내보냅니다. 브라우저는 화면에 나온 글자의 묶음만 받습니다. 한 파일 2MB → 첫 화면 약 420KB(묶음 16개), 로그인 화면 약 230KB. 묶음 목록은 `styles/pretendard.css`에 있습니다.

### 9. 품질 검사

| 명령 | 보는 것 |
|---|---|
| `npm run typecheck` | TypeScript 타입 |
| `npm run lint` | Biome (형식 · 흔한 실수) |
| `npm run audit:client` | 화면 코드 규칙: 파일 머리말, `.tsx` 460줄 이하, 4개 언어 사전 일치, 쓰지 않기로 한 말 · 색 |
| `npm run check` | 서버 모듈 문법 |
| `npm test` | 단위 + 실제 서버를 띄운 HTTP 시험 66개 |
| `npm run build:react` | 타입 검사 뒤 `dist/` 빌드 (`dist/`는 저장소에 함께 둠) |

운영 도구: `npm run backup`(DB 백업) · `ai:smoke` · `mail:smoke` · `verify`.

### 10. 알려진 기술 빚

- 글꼴 묶음 목록 때문에 스타일 파일이 108KB → 157KB로 커졌습니다 (눌러 보내면 약 15KB 늘어남). 글자는 기기 글꼴로 먼저 보이다가 글꼴 묶음을 받으면 바뀝니다.
- `chart.js` · `react-chartjs-2`는 `package.json`에 남아 있지만 지금 화면에서는 쓰지 않습니다.
- `npm run test:browser`가 가리키는 `tests/browser/` 폴더가 지금은 없습니다.
- [`ARCHITECTURE.md`](./ARCHITECTURE.md)의 화면 쪽 설명 일부(`views/`, `viewmodels/`, `pages/`)는 예전 구조 기준입니다. 서버 폴더 표와 "계정과 메일" 절은 지금 코드와 맞습니다.
- 시도 제한과 패스키 확인값은 메모리에 두어서 서버 프로세스 하나를 기준으로 합니다.
- 서버가 만드는 안내 문구 · AI 요약 · 메일 본문은 한국어로만 나옵니다.
