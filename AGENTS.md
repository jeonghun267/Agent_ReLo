# ReLo Workspace Rules (AGENTS.md / GEMINI.md)

## 1. Project Identity & Purpose
- **Project**: ReLo (2.0.0) — 해외 직구 반품·교환·AS 클레임 원스톱 기록 B2C 웹 서비스.
- **Key Focus**: 100% B2C 간편 신청(5단계 위저드), 실시간 진행 현황판, AI 직구 환불 지원, 다국어(ko/en/zh/ja) 지원, 개인정보 및 증빙 데이터 보안.

## 2. Tech Stack & Environment
- **Runtime**: Node.js >= 24.15.0 (ES Modules, `--env-file-if-exists=.env`)
- **Backend**: Native Node HTTP server (`src/server/`), SQLite (`.relo-data/relo.sqlite`), serving React SPA from `dist/` on port 4180
- **Frontend**: React 19 / TypeScript / Vite / Tailwind CSS v4 (`src/client/`), Mobile-first responsive (390px viewport priority)
- **External Services**: Google Gemini API (주문서 파싱/문의 초안), Resend (이메일 인증/알림)
- **Testing & Quality**:
  - `npm run check` (Node static check)
  - `npm test` (unit & http tests)
  - `npm run audit:client` (Client code quality & i18n parity check)
  - `npm run typecheck` (TypeScript check)
  - `npm run lint` (Biome linter)

## 3. Strict Development Constraints
- **Preserve SQLite Integrity**: Do not perform destructive DB migrations without backup (`npm run backup`).
- **Data Protection**: User claims and uploaded invoices/photos (up to 10MB) must remain strictly isolated to the authenticated user.
- **Production Bundle**: Keep `dist/` built and synchronized with `src/client/` (`npm run build:react`).
