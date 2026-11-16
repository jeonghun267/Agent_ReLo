# ReLo — 파트별

코드가 **어디에 있고 무엇을 맡는지**를 **앱**과 **웹**으로 나누고, 그 안에서 폴더(파트)별로 정리했습니다. 고칠 곳을 찾을 때 보는 문서입니다. (2026-11-16 기준)

- 어떤 기술로 만들었는지는 → [기술](./README_TECH.md)
- 무엇을 할 수 있는지는 → [기능](./README_FEATURES.md)

## 저장소 지도

```text
Agent_ReLo/
├── flutter_app/        # 앱 (Flutter)
├── src/client/         # 웹 화면 (React)
├── src/server/         # 서버 (Node.js) — 웹과 앱이 함께 씀
├── tests/              # 서버 시험
├── scripts/            # 검사 · 운영 도구
├── dist/               # 빌드된 웹 화면 (서버가 그대로 내보냄)
├── index.html          # 웹 첫 페이지 틀 (받는 동안 보이는 뼈대 포함)
└── docs/               # 문서
```

| | 앱 | 웹 |
|---|---|---|
| 화면 | `flutter_app/lib/features/` | `src/client/features/` |
| 공통 부품 | `flutter_app/lib/shared/` | `src/client/components/` |
| 기반 | `flutter_app/lib/core/` | `src/client/lib/` · `hooks/` · `i18n/` |
| 기기 · 서버 | `flutter_app/android/` (Kotlin) | `src/server/` |
| 시험 | `flutter_app/test/` | `tests/` |

---

## 앱 (`flutter_app/`)

### 1. 진입과 틀

| 파일 | 맡은 일 |
|---|---|
| `lib/main.dart` | 테마 · 다국어 · 탭 이동 · 시작 연출을 엮어 앱을 띄움 |
| `lib/shared/widgets/relo_app_shell.dart` | 하단 탭 셋(홈 · 내 환불 · 설정)과 키보드 이동 |
| `lib/shared/widgets/relo_intro.dart` | 시작 연출 (로고 → 말랑이 → 홈) |

### 2. 기반 `lib/core/`

| 폴더 | 맡은 일 |
|---|---|
| `i18n/` | 4개 언어 사전 (`relo_i18n.dart`) |
| `network/` | 서버 호출 (`api_client.dart`): 세션 쿠키 · CSRF · 버전 · 재시도 키, 서버 주소 |
| `attachments/` | 붙일 파일 규칙(종류 확인 · 촬영 정보 지우기 · 10MB)과 고르기 · 공유받기 |
| `reminders/` | 마감 알림: 언제 무엇을 알릴지(`reminder_planner.dart`), 기기에 맡기기(`reminder_scheduler.dart`) |
| `platform/` | 안드로이드와 잇는 통로(`relo_native_channel.dart`), 시작 화면 넘겨받기, 쓴 글을 다른 앱으로 넘기기 |
| `theme/` | 다크 · 라이트 · 고대비 색(`relo_theme.dart`), 움직임 시간 · 곡선(`motion_tokens.dart`) |
| `storage/` | 이 기기에만 두는 것: 도우미 대화 기록, 알림 설정 |
| `utils/` | 통화 계산(`money_format.dart`), D-day(`dday.dart`), 입력 규칙(`input_rules.dart`) |
| `config/` | 앱이 쓰는 외부 SDK 목록 (`sdk_registry.dart`, 약관 화면에 그대로 보여 줌) |

### 3. 공통 `lib/shared/`

| 폴더 | 맡은 일 |
|---|---|
| `models/domain_models.dart` | 서버 응답과 1:1인 모델 |
| `state/relo_store.dart` | **전역 상태 하나.** 서버 호출, 서버가 없을 때의 데모 데이터, 화면에 알릴 변화 |
| `widgets/` | 지구본(`refund_globe.dart`), 말랑이(`relo_mascot.dart`), 로고, 아이콘 이름(`relo_icons.dart`), 환불 한 줄(`claim_row.dart`), 버튼 · 입력칸 · 칩(`relo_primitives.dart`), 파일 붙이기 창(`evidence_source_sheet.dart`) |

### 4. 화면 `lib/features/`

| 폴더 | 화면 |
|---|---|
| `home/` | 홈 = 대화 화면 (`home_screen.dart`) |
| `wizard/` | 5단계 신청과 완료 화면 (`wizard_screen.dart`) |
| `claims/` | 내 환불 목록(`my_claims_screen.dart`), 상세(`claim_detail_screen.dart`), 받은 것 기록 · 기록 되돌리기(`receipt_section.dart`), 분쟁 해결 안내 · 답 없는 쇼핑몰 · 다시 열기(`dispute_guide.dart`), 마감일 적기(`deadline_sheet.dart`) |
| `shared/models/` | 서버와 같은 규칙(`claim_rules.dart`: 받은 것 합계, 다 받았는지, 다음 할 일, 이의 제기 마감), 환불 · 교환 · 수리의 말(`claim_words.dart`) |
| `assistant/` | 아래에서 올라오는 도우미 대화 창 (`assistant_sheet.dart`) |
| `auth/` | 로그인 · 회원가입 (`auth_screen.dart`) |
| `settings/` | 계정 · 화면 · 알림 · 백업 · 약관 열기 · 탈퇴 (`settings_screen.dart`) |
| `compliance/` | 약관 · 정책 문서, 쿠키 동의, 사업자 정보 |

### 5. 안드로이드 `android/app/src/main/`

| 파일 | 맡은 일 |
|---|---|
| `kotlin/…/MainActivity.kt` | 앱 화면과 기기 기능을 잇는 곳 (통로 이름 `relo/native`) |
| `kotlin/…/ReloEvidence.kt` | 카메라 · 사진 고르기 · 파일 고르기 · 공유받은 파일 읽기, 사진 세우고 줄이기 |
| `kotlin/…/ReloReminders.kt` | 알람 맞추기 · 알림 띄우기 · 기기를 다시 켰을 때 다시 맞추기 |
| `AndroidManifest.xml` | 권한 셋(인터넷 · 알림 · 기기 켰을 때), 공유받기 등록 |
| `res/` | 앱 아이콘, 시작 화면 바탕 |

### 6. 시험과 문서

| 위치 | 내용 |
|---|---|
| `test/widget_test.dart` | 기본 화면 |
| `test/app_quality_test.dart` | 화면 품질 |
| `test/device_features_test.dart` | 붙이기 규칙 · 알림 계획 같은 기기 기능의 Dart 쪽 |
| `README.md` | 화면 · 기능 · 실행 · 아직 안 된 것 |
| `ARCHITECTURE.md` | 폴더 원칙, 패키지 버전 규칙, 보호 항목 20개와 코드 짝 |
| `DESIGN.md` | 색 · 간격 · 글자 · 움직임 · 문구 기준 |
| `docs/` | 시연 영상, 안드로이드에서 확인한 화면(`android_check/`) |

### 7. 앱에서 무언가 고칠 때

- **글자**를 바꾸면 `core/i18n/relo_i18n.dart`의 4개 언어를 함께 바꿉니다.
- **서버와 주고받는 것**을 바꾸면 `domain_models.dart` → `api_client.dart` → `relo_store.dart` 순서로 봅니다.
- **기기 기능**은 Dart 쪽(`core/attachments`, `core/reminders`, `core/platform`)과 Kotlin 쪽을 함께 고칩니다.
- **색 · 간격 · 움직임**은 화면에 숫자를 직접 쓰지 않고 `core/theme/`의 값을 씁니다.

---

## 웹

웹은 **화면**(`src/client/`)과 **서버**(`src/server/`) 두 덩어리입니다. 서버는 앱도 함께 씁니다.

### 1. 화면의 틀

| 파일 | 맡은 일 |
|---|---|
| `index.html` | 첫 페이지 틀. 화면 코드를 받는 동안 보이는 뼈대(위쪽 줄 · 자리 표시)가 들어 있음 |
| `src/client/main.tsx` | React 시작점 |
| `src/client/App.tsx` | 주소에 맞는 화면 고르기, 화면별로 나눠 받기 |
| `src/client/components/AppShell.tsx` | 위쪽 줄(로고 · 메뉴 · 언어), 이메일 인증 안내 띠, 아래쪽 정보, 휴대폰 하단 탭 |

### 2. 화면 `src/client/features/`

| 폴더 | 화면 | 주요 파일 |
|---|---|---|
| `landing/` | 첫 화면 | `LandingPage.tsx`(구성), `HeroProductShowcase.tsx`(실제 화면 보여 주기), `GlobalRefundGlobe.tsx` + `globeCanvasRenderer.ts`(지구본), `TossPhoneScenes.tsx`(스마트폰 이야기), `WhyReloSection.tsx`(비교 표), `LandingFlowPlayground.tsx`(5단계 흐름), `RefundSimulatorSection.tsx`(예상 환불 계산기) |
| `auth/` | 로그인 · 가입 · 비밀번호 찾기 · 이메일 인증 | `AuthPage.tsx`, `AuthRecoveryPanels.tsx`, `ExtraSignIn.tsx`(구글 · 패스키 버튼) |
| `claim-wizard/` | 5단계 신청 | `WizardPage.tsx`, `WizardStepsContent.tsx`, `WizardInvoiceScanCard.tsx`(영수증 자동 읽기), `WizardStatusScreens.tsx`(완료 · 안내), `useWizardDraft.ts`(적던 내용 불러오기 · 보관) |
| `my-claims/` | 내 환불 | `MyClaimsPage.tsx`, `ConsumerClaimsLedger.tsx`(목록 · 검색 · 정렬), `ClaimsAnalyticsCard.tsx`(통화별 요약) |
| `claim-detail/` | 환불 상세 | `ClaimDetailPage.tsx`, `ClaimLifecycleFlow.tsx`(단계 표시), `ForeignMessageStudio.tsx`(메시지), `SellerReplyAnalyzer.tsx`(답장), `EvidenceAndSettlementTab.tsx`(사진 · 입금), `ReceiptForm.tsx`(받은 것 기록), `ReceiptLedgerList.tsx`(받은 기록 · 되돌리기), `ClaimFilesVaultCard.tsx`(보관함), `ClaimProgressSummary.tsx`(맨 위 요약: 돈 · 받은 수량 · 수리 결과), `ClaimStateNotice.tsx`(답 없는 쇼핑몰 · 다시 열기), `DisputeGuideCard.tsx`(분쟁 해결 안내) |
| `settings/` | 설정 | `SettingsPage.tsx`, `PasskeyCard.tsx` |

### 3. 화면의 공통 부품과 기반

| 위치 | 맡은 일 |
|---|---|
| `components/ui/Primitives.tsx` | 버튼 · 카드 · 입력칸 · 비밀번호 칸 · 금액 표시 |
| `components/media/` | 파일 올리기(`UppyEvidenceUploader`), 사진 자르기, PDF 미리보기 |
| `components/effects/` | 첫 화면 배경, 마우스를 따라오는 버튼, 숫자 올라가기, 쇼핑몰 줄 |
| `components/ReloOrbEmblem.tsx` | 로고 캐릭터와 말풍선 |
| `hooks/useSession.ts` · `useClaims.ts` | 서버에서 받은 값 보관과 바꾸기 (로그인 상태, 환불 건) |
| `lib/api-client.ts` | 서버 호출 한 곳. CSRF · 버전 · 재시도 키를 붙임 |
| `lib/router.tsx` | 주소 ↔ 화면 |
| `lib/claim-words.ts` | 단계 이름, "다음에 할 일", 오류 문구를 고른 언어로 |
| `lib/wizard-draft.ts` | 적던 신청을 이 브라우저에 계정별로 보관 (글자만, 일주일, 로그아웃하면 모두 지움) |
| `lib/dispute.ts` | 분쟁 때의 마감일 계산(주문일 + 120일 · 180일)과 붙여 넣을 요약 글 만들기 |
| `lib/claim-progress.ts` | 얼마나 받았는지(환불은 돈, 교환은 수량, 수리는 확인 여부), 다 받았는지, 닫힌 건인지, 되돌린 기록 |
| `i18n/screens/kinds.ts` | 교환 · 수리가 돈 대신 쓰는 말, 번호 없는 입금 · 기록 되돌리기 · 답 없는 쇼핑몰의 말 (4개 언어) |
| `lib/format.ts` · `passkey.ts` · `preparation.ts` | 날짜 · 금액 모양, 패스키 호출, AI가 읽는 동안의 안내를 잠깐 유지하는 타이머 |
| `i18n/` | `ko` `en` `ja` `zh` + 화면별 사전 `screens/`(공통 · 내 환불 · 상세 · 신청 · 설정 · 올리기 · 계정 · 로그인 방식) |
| `types/` | 서버와 맞춘 타입, 입력 검사 규칙(`claim.schema.ts`, `auth.schema.ts`) |
| `styles/index.css` | 색 · 글꼴 토큰 |
| `styles/pretendard.css` · `assets/fonts/pretendard/` | 글자 묶음 92개로 나눈 글꼴과 그 목록, 사용 허가서(`LICENSE.txt`). 목록은 손으로 고치지 않음 |

### 4. 서버 `src/server/`

요청은 `http` → `routes` → `services` → `repositories` 순서로 지나가고, 규칙은 `domain`에 있습니다.

| 폴더 | 맡은 일 | 지킬 것 |
|---|---|---|
| `main.mjs` · `app.mjs` · `config.mjs` | 시작, **모든 부품 조립**, 환경변수 읽기 · 검사 | 부품 연결은 `app.mjs`에서만 |
| `http/` | 주소 찾기, 요청 · 응답 도우미, 보안 헤더 · Host · Origin · CSRF, 시도 제한, 정적 파일(압축 전송) | |
| `routes/` | 주소 ↔ 서비스 (`auth` `google` `passkey` `account` `claims` `files` `inquiry` `ai` `meta`) | 저장소를 직접 부르지 않음 |
| `services/` | 업무 흐름: 본인 것만, 버전 검사, 재시도 키, 변경 이력 | SQL 금지. 트랜잭션은 여기서만 |
| `repositories/` | 표별 SQL, DB 열기, `migrations/`(구조 변경 파일) | SQL은 여기만. 적용된 파일은 고치지 않고 새로 더함 |
| `domain/` | 순수 규칙: 입력 검사, 금액, 단계 바뀜, 입금 기록, 기본 영문 양식, 패스키 검증 | 입출력 없음. `node:crypto` 말고는 가져오지 않음 |
| `ai/` | Gemini · 가짜 · 꺼짐, `prompts/`(초안 · 번역 · 읽기 · 도우미) | 미리보기만 만들고 저장하지 않음 |
| `auth/` | 구글과 주고받기 (`google.provider.mjs`) | |
| `mail/` | Resend · 기록에 찍기 · 꺼짐, 메일 본문 | 발송을 기다리지 않음. 키는 `.env`에만 |
| `dev/` | 개발용 체험 계정과 예시 주문서 | 운영에서는 쓰지 않음 |

**주소(API) 묶음**

| 묶음 | 주소 |
|---|---|
| 계정 | `/api/auth/signup` `login` `logout` `verify` `verify/resend` `forgot` `reset`, `/api/me` |
| 다른 로그인 | `/api/auth/google/start` `callback`, `/api/auth/passkey/options` `login`, `/api/account/passkeys…` |
| 내 정보 | `/api/account/ai-consent` `export` `delete` |
| 환불 건 | `/api/claims` (목록 · 만들기), `/api/claims/:id` (보기 · 고치기 · 휴지통), `restore`, `transition` |
| 파일 | `/api/claims/:id/files`, `/api/files/:fileId` |
| 메시지 · 답장 · 입금 | `/api/claims/:id/draft-template` `drafts` `drafts/submit` `replies` `receipts` |
| AI | `/api/ai/extract` `translate-issue` `assistant`, `/api/claims/:id/ai/draft` `analyze-reply` `extract` |
| 그 밖 | `/api/config` (켜진 기능), `/api/health` |

### 5. 시험 `tests/`

| 위치 | 내용 |
|---|---|
| `unit/domain.test.mjs` | 금액 · 단계 · 입력 검사 규칙 |
| `unit/database.test.mjs` | 고칠 수 없는 표, 탈퇴 때 지우기 |
| `unit/architecture.test.mjs` | 계층 규칙을 소스를 읽어 확인 |
| `unit/gemini` · `resend` · `google` · `webauthn` | 바깥과 주고받는 부품을 가짜 응답으로 |
| `http/auth` · `email` · `signin` · `account` | 가입 · 세션 · 인증 링크 · 구글 · 패스키 · 내보내기 · 탈퇴 |
| `http/claims` · `inquiry` · `ai` · `seed` | 환불 건, 메시지 · 답장 · 입금, AI 동의 · 한도, 체험 계정 |
| `http/static.test.mjs` | 압축 전송 |
| `helpers/` | 임시 DB로 실제 서버 띄우기, 가짜 메일함, 소프트웨어 패스키 장치 |

### 6. 도구와 결과물

| 위치 | 맡은 일 |
|---|---|
| `scripts/audit-client-quality.mjs` | 화면 코드 규칙 검사 (`npm run audit:client`) |
| `scripts/check.mjs` | 서버 모듈 문법 검사 |
| `scripts/backup-db.mjs` | DB 백업 (`npm run backup`) |
| `scripts/ai-smoke.mjs` · `mail-smoke.mjs` | 실제 AI · 메일 연결 확인 |
| `scripts/verify.mjs` | 검사를 순서대로 실행 |
| `dist/` | `npm run build:react` 결과. 저장소에 함께 두고 서버가 그대로 내보냄 |
| `.env.example` | 환경변수 설명 (AI · 메일 · 구글 · 패스키) |
| `.claude/launch.json` | 미리보기 서버 설정 (개발 · 가짜 AI · 로그인 방식 시험) |

### 7. 문서 `docs/`

| 파일 | 내용 |
|---|---|
| `README_TECH.md` · `README_FEATURES.md` · `README_PARTS.md` | 기술 · 기능 · 파트별 정리 (이 문서들) |
| `ARCHITECTURE.md` | 서버 구조와 규칙, 계정과 메일 |
| `AI.md` | AI 기능, 안전장치, 비용 |
| `DESIGN.md` · `FRONTEND_ARCHITECTURE.md` · `RELO_REACT_SPEC.md` | 웹 디자인 기준과 화면 설계 |
| `relo_web_demo.gif` · `relo_web_demo.webm` | 웹을 처음부터 끝까지 써 보는 영상 (루트 README 맨 위에 보임). 앱 영상은 `flutter_app/docs/` |
| `screenshots/` · `archive/` | 화면 그림, 예전 문서 |

### 8. 웹에서 무언가 고칠 때

- **화면 글자**를 바꾸면 `i18n/screens/`의 4개 언어를 함께 바꿉니다. 하나라도 빠지면 타입 검사와 `audit:client`가 막습니다.
- **화면 파일(`.tsx`)은 460줄까지**입니다. 넘으면 부품으로 나눕니다.
- **새 주소(API)**: `repositories`(SQL) → `services`(흐름) → `routes`(주소) → `lib/api-client.ts` → `tests/http/` 순서로 더합니다. 다른 사람 것이 404인지 꼭 시험합니다.
- **DB 구조**를 바꾸면 `migrations/`에 새 파일을 더하고, 먼저 `npm run backup`을 합니다.
- **화면을 고친 뒤**에는 `npm run build:react`로 `dist/`를 다시 만듭니다.
- **서버 코드를 고친 뒤**에는 서버를 다시 켜야 반영됩니다.
