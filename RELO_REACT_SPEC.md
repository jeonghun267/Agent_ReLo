# ReLo 2.0 React 전면 전환 마스터 설계 명세서 (RELO_REACT_SPEC.md)

> **프로젝트 목표**: 해외 직구 반품·교환·AS 클레임 원스톱 기록 및 AI 끝장 대행 서비스 **ReLo**의 프론트엔드를 기존 바닐라 Web Components에서 **Vite + React 19 + TypeScript + Tailwind CSS v4** 스택으로 전면 재구축한다.  
> **핵심 철학**: "Search & Reuse First, Write Production-Grade Code, Protect Existing Environments, Zero Mock, AI 템플릿 탈피."

---

## 1. 🥊 경쟁사 분석 & ReLo 킬러 차별화 전략 (Competitor Moat)

경쟁사 분석 에이전트(`competitor-analysis`) 평가를 기반으로 도출된 ReLo의 4대 핵심 전략:

| 분석 축 | 기존 배송대행지 반품 대행 (몰테일 등) | 글로벌 반품 SaaS (Loop, Returnly) | **ReLo 2.0 (킬러 차별화)** |
| :--- | :--- | :--- | :--- |
| **적용 범위** | 특정 제휴 배대지 이용 건 한정 | 해당 쇼핑몰이 솔루션을 도입해야 가능 | **전 세계 모든 해외 쇼핑몰 무제한 지원** (아마존, 알리, 타오바오, 독립몰) |
| **언어/교섭 장벽** | 고객이 파파고 번역기로 수기 작성 | 영미권 중심 (한국어 미지원) | **Gemini AI 기반 다국어 판매자 문의 초안 자동 생성 & 판매자 답장 분석** |
| **증빙 제출 UX** | 단순 이미지 첨부 (용량 제한, 화질 저하) | 단순 텍스트 입력 위주 | **PDF.js 인보이스 뷰어 + Cropper.js 파손 부위 정밀 크롭 + Uppy 실시간 업로드** |
| **진행 가시성** | "접수 후 무기한 대기" (블랙박스) | 단순 텍스트 상태 변경 | **`@xyflow/react` 기반 실시간 사건 타임라인 + 정산 원장(Ledger)** |
| **B2B 확장성** | 개인 고객 위주 | 단순 쇼핑몰 반품 포털 | **TanStack Table + Chart.js 기반 구매대행/셀러용 일괄 클레임 관리** |

---

## 2. 🎨 시각 디자인 원칙 (Stops AI UIs Looking Templated)

디자인 크리틱 에이전트(`critiquing-visual-design`, `taste-skill`, `design-review`) 기준 준수:

1. **전형적인 AI 보라색 그라디언트/부트스트랩 카드 레이아웃 금지**:
   - 모던하고 차분한 테크 SaaS 톤앤매너: Deep Neutral Slate (`#0B0F17`, `#111827`, `#F8FAFC`), 세련된 브랜드 액센트 컬러 (Electric Indigo / Emerald).
2. **명확한 정보 계층 구조 (Typographic Hierarchy)**:
   - Pretendard 기반 가변 폰트 적극 활용, 숫자/통화는 고정폭(tabular-nums) 및 볼드 처리.
3. **모바일 퍼스트 390px 뷰포트 최우선 설계**:
   - 직구 고객의 80%는 스마트폰으로 택배 박스를 뜯으며 신청함. 엄지손가락 터치 영역 최소 44px 확보.
4. **마이크로 인터랙션 (`motion` & `canvas-confetti`)**:
   - 위저드 단계 전환 시 부드러운 수평 슬라이드 트랜지션.
   - 사건 접수 및 환불 승인 완료 시 터지는 절제된 축하 파티클.

---

## 3. 📦 설치된 패키지 1:1 역할 매핑표

| 패키지명 | 역할 및 적용 화면 |
| :--- | :--- |
| **`react` & `react-dom` (v19)** | 핵심 리액트 런타임 |
| **`vite` & `@tailwindcss/vite`** | 초고속 HMR 번들러 및 유틸리티 CSS 엔진 |
| **`motion` (v14)** | 위저드 단계 전환 애니메이션, 아코디언, 모달 열림/닫힘 인터랙션 |
| **`canvas-confetti`** | 클레임 접수 성공 및 환불 승인 완료 화면 축하 인터랙션 |
| **`@xyflow/react` (v12)** | 클레임 상세 페이지 사건 진행 워크플로우 타임라인 시각화 |
| **`pdfjs-dist`** | 해외 쇼핑몰 주문서/인보이스 PDF 브라우저 즉시 뷰어 및 텍스트 추출 |
| **`cropperjs`** | 택배 박스 송장, 제품 파손 부위, 시리얼 번호 사진 정밀 크롭 도구 |
| **`@uppy/core` & `@uppy/react`** | 최대 10MB 증빙자료 모바일 업로드 진행률 UI 및 자동 재시도 |
| **`react-hook-form` & `zod`** | B2C 5단계 간편 신청 폼 상태 관리 및 런타임 스키마 유효성 검증 |
| **`@tanstack/react-query`** | 백엔드 API 캐싱, 무효화, 백그라운드 리패칭 (REST 엔드포인트 연동) |
| **`@tanstack/react-table`** | B2B 관리자 대시보드 다중 정렬, 필터링, 페이지네이션 고성능 테이블 |
| **`chart.js` & `react-chartjs-2`** | B2B 클레임 통계, 월별 환불 회수액, 쇼핑몰별 불량률 도넛/바 차트 |
| **`lucide-react`** | 글로벌 표준 모던 SaaS 아이콘 세트 |
| **`clsx` & `tailwind-merge`** | `src/lib/utils.ts`의 `cn` 유틸리티 함수 (클래스 충돌 방지) |

---

## 4. 🏛️ 시스템 아키텍처 및 디렉터리 구조

기존 백엔드(`src/server/`)와 공존하며 `src/client/`로 React 코드를 모듈화합니다.

```
AI_Agent/
├── src/
│   ├── client/                  # [신규] React 19 Frontend SPA
│   │   ├── components/          # 공통 UI 컴포넌트 (Button, Card, Modal, Input 등)
│   │   ├── features/
│   │   │   ├── auth/            # 로그인, 회원가입, 비밀번호 재설정
│   │   │   ├── claim-wizard/    # B2C 5단계 간편 신청 위저드 (Uppy, Cropper, Zod)
│   │   │   ├── dashboard/       # 메인 홈 (Bento Grid, 진행 중인 사건, 다음 행동)
│   │   │   ├── claim-detail/    # 사건 상세 (xyflow 타임라인, AI 초안, 답장 분석)
│   │   │   ├── b2b-admin/       # B2B 일괄 관리 (TanStack Table, Chart.js)
│   │   │   └── evidence/        # PDF.js 뷰어 및 이미지 크롭 모듈
│   │   ├── hooks/               # React Query 커스텀 훅 (`useClaims`, `useAiDraft` 등)
│   │   ├── lib/                 # 유틸리티 (`api-client.ts`, `cn`, `format.ts`)
│   │   ├── types/               # TypeScript 인터페이스 및 Zod 스키마
│   │   ├── App.tsx              # 최상위 라우터 및 글로벌 프로바이더
│   │   └── main.tsx             # React DOM 엔트리포인트
│   ├── server/                  # [기존 유지] Native Node 24 HTTP 서버 (SQLite, AI, Mail)
│   └── lib/utils.ts             # Tailwind cn() 유틸리티
├── vite.config.ts               # Vite 설정 (API Proxy: 127.0.0.1:4180)
├── tsconfig.json                # TypeScript 엄격 모드 설정
└── biome.json                   # Biome 린터/포매터 설정
```

---

## 5. 🔌 백엔드 API 계약 (Zero Mock 필수 연동)

Vite 개발 서버(`/api`, `/auth`)가 백엔드 `http://127.0.0.1:4180`으로 자동 프록시됩니다.

- **인증 (`/auth/*`)**:
  - `POST /auth/signup`, `POST /auth/login`, `POST /auth/logout`, `GET /auth/session`
  - `POST /auth/forgot-password`, `POST /auth/reset-password`
- **클레임 관리 (`/api/claims`)**:
  - `GET /api/claims`: 전체 클레임 조회 (필터/정렬 지원)
  - `POST /api/claims`: 신규 클레임 생성 (5단계 위저드 완료 시 제출)
  - `GET /api/claims/:id`: 특정 클레임 상세, 증빙 파일, 판매자 교섭 이력, 정산 원장
- **증빙 파일 (`/api/claims/:id/files`)**:
  - `POST /api/claims/:id/files`: 10MB 증빙자료 업로드 (멀티파트)
- **AI 어시스턴트 (`/api/ai/*`)**:
  - `POST /api/ai/draft`: Gemini 기반 영문/일문/중문 판매자 문의 초안 생성
  - `POST /api/ai/analyze-reply`: 판매자 답장 이메일 텍스트/캡처 AI 판독
  - `POST /api/ai/extract-order`: 주문서 PDF 텍스트 자동 파싱

---

## 6. 🚀 단계별 구현 체크리스트 (Task Execution List)

AI 에이전트는 아래 체크리스트를 순차적으로 실행하며 완료 시 체크(`[x]`)합니다:

- [ ] **Phase 1: React 기반 인프라 & Shell 셋업**
  - [ ] `index.html`을 React 마운트용으로 연동 및 `src/client/main.tsx` 생성
  - [ ] Tailwind v4 테마 및 shadcn 스타일 기본 컴포넌트(`Button`, `Input`, `Badge`, `Card`, `Modal`) 구축
  - [ ] 글로벌 네비게이션(B2C 모바일 바텀바 + B2B 데스크톱 사이드바) Shell 완성
  - [ ] 세션 및 인증 폼(`useAuth`, `react-hook-form` + `zod` 기반 로그인/회원가입) 연동

- [ ] **Phase 2: B2C 5단계 간편 신청 위저드 (Core Wizard)**
  - [ ] Step 1: 구매처(쇼핑몰), 주문번호, 주문일자 입력 (자동 검증)
  - [ ] Step 2: 클레임 유형(반품/환불/교환/파손) 및 피해 금액/통화(USD, JPY, EUR, CNY, KRW)
  - [ ] Step 3: 피해 상세 사유 작성 및 AI 사전 진단 가이드
  - [ ] Step 4: Uppy + Cropper.js 연동 10MB 증빙 사진/인보이스 업로드 & 크롭 UX
  - [ ] Step 5: 최종 요약 확인 및 제출 (`motion` 슬라이드 전환 + 완료 시 `canvas-confetti`)

- [ ] **Phase 3: 메인 대시보드 & 인터랙티브 타임라인**
  - [ ] Bento Grid 레이아웃의 대시보드 홈 (미회수 금액 지표, 지금 해야 할 일(Next Action) 카드)
  - [ ] `@xyflow/react`를 활용한 클레임 사건 진행 상태 노드 다이어그램 타임라인
  - [ ] `@tanstack/react-query`를 통한 실시간 클레임 목록 조회, 필터링, 검색

- [ ] **Phase 4: AI 사건 처리 어시스턴트 & 증빙 PDF 뷰어**
  - [ ] Gemini AI 해외 판매자 문의 초안 생성 및 원클릭 복사/메일 전송 다이얼로그
  - [ ] `pdfjs-dist` 기반의 인보이스 PDF 뷰어 (페이지 넘김, 확대/축소, 주문번호 하이라이트)
  - [ ] 판매자 수신 메일 붙여넣기 및 AI 환불 승인/거절 판독 컴포넌트

- [ ] **Phase 5: ReLo Business B2B 관리자 대시보드**
  - [ ] `@tanstack/react-table` 기반의 고성능 엔터프라이즈 클레임 데이터 그리드
  - [ ] `chart.js` 기반의 월별 클레임 추이 및 환불 성공률 분석 대시보드

- [ ] **Phase 6: QA 및 프로덕션 검증**
  - [ ] TypeScript 정적 타입 검사 (`npm run typecheck` ➔ 0 errors)
  - [ ] Biome 린트/포매팅 검사 (`npm run lint`)
  - [ ] 기존 백엔드 63개 유닛/HTTP 테스트 통과 유지 (`npm test`)
  - [ ] Playwright E2E 브라우저 흐름 및 웹 접근성 검사 (`npm run test:browser`)
