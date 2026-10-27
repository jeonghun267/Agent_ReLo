# ReLo Workspace Rules (AGENTS.md / GEMINI.md)

## 1. Project Identity & Purpose
- **Project**: ReLo (2.0.0) — 해외 직구 반품·교환·AS 클레임 원스톱 기록 B2C 웹 서비스.
- **Key Focus**: 100% B2C 간편 신청(5단계 위저드), 실시간 진행 현황판, AI 도리 환불 대행, 개인정보 및 증빙 데이터 보안.

## 2. Tech Stack & Environment
- **Runtime**: Node.js >= 24.15.0 (ES Modules, `--env-file-if-exists=.env`)
- **Backend**: Native Node HTTP server (`src/server/`), SQLite (`.relo-data/relo.sqlite`)
- **Frontend**: Vanilla JS / Web Components (`src/web/`), Mobile-first responsive (390px viewport priority)
- **External Services**: Google Gemini API (주문서 파싱/문의 초안), Resend (이메일 인증/알림)
- **Testing**: Node native test runner (`node --test`), Playwright Core (`tests/browser/`)

## 3. Strict Development Constraints
- **Preserve SQLite Integrity**: Do not perform destructive DB migrations without backup (`npm run backup`).
- **Data Protection**: User claims and uploaded invoices/photos (up to 10MB) must remain strictly isolated to the authenticated user.
- **Verification Commands**:
  - `npm run check` (static check)
  - `npm test` (unit & http tests)
  - `npm run test:browser` (Playwright flow test)
