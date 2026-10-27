# ReLo 2.0 B2C 전면 전환 마스터 설계 명세서 (RELO_REACT_SPEC.md)

> **프로젝트 목표**: 해외 직구로 피해를 입은 일반 소비자를 위한 **100% B2C 원스톱 반품·환불·교환 AI 대행 서비스 ReLo** 구축.  
> **핵심 철학**: "100% Consumer B2C First, Toss/Karrot 스타일의 극단적 단순함, Zero Mock, 복잡한 B2B 기능 전면 배제."

---

## 1. 🥊 경쟁사 분석 & ReLo B2C 킬러 차별화 전략 (Consumer Moat)

경쟁사 분석 에이전트(`competitor-analysis`) 평가 기반 ReLo의 100% 소비자 중심 4대 차별점:

| 분석 항목 | 기존 배송대행지 반품 (몰테일 등) | 해외 직구 포기 / 소비자 직접 해결 | **ReLo B2C (소비자 관점 킬러 기능)** |
| :--- | :--- | :--- | :--- |
| **적용 범위** | 특정 제휴 배대지 이용 건만 가능 | 해외 셀러와 직접 영어/중국어로 싸워야 함 | **전 세계 모든 해외 쇼핑몰 무제한 지원** (아마존, 알리, 타오바오, 쉬인, 독립몰) |
| **언어 장벽** | 번역기 돌려 복잡한 영문 메일 수기 작성 | 판매자 전문 용어에 밀려 환불 거절당함 | **Gemini AI + 펭귄 도리(Dori)가 정중하고 단호한 판매자 문의 편지 자동 작성** |
| **증빙 제출 UX** | 단순 첨부 (용량 제한, 화질 저하, 누락) | 복잡한 파일 형식 변환 요구 | **스마트폰 촬영 파손 사진 손가락 크롭 (`Cropper.js`) + 영수증 PDF 즉시 파싱** |
| **환불 가시성** | "접수 후 무기한 대기" (블랙박스) | 판매자 답장 해석 불가로 방치 | **택배 배송 조회처럼 명확한 단계별 실시간 환불 타임라인 + 입금 정산 추적** |

---

## 2. 🎨 B2C 시각 디자인 원칙 (Toss & Karrot 스타일)

디자인 크리틱 에이전트(`critiquing-visual-design`, `taste-skill`, `design-review`) 기준:

1. **절대 B2B 복잡한 엑셀 표나 기업용 대시보드 금지**:
   - 20~30대 일반 직구 소비자를 위한 따뜻하고 친근하며 직관적인 B2C 감성.
   - 큰 폰트, 시원한 여백, 1화면 1질문 중심의 쉬운 카드 UI.
2. **소비자의 든든한 AI 친구, 펭귄 '도리(Dori)'**:
   - 노란 크로스백을 맨 귀여운 펭귄 캐릭터가 단계마다 말풍선으로 친절히 가이드 (최소 2.5초 노출 정책 준수).
   - *"억울하게 깨져서 온 물건, 도리가 대신 영어로 환불 따져드릴게요!"*
3. **모바일 퍼스트 390px 뷰포트 최우선**:
   - 택배 상자를 뜯으며 스마트폰으로 바로 신청할 수 있도록 엄지손가락 터치 반경(최소 44px) 최우선 배치.
4. **감성적인 마이크로 인터랙션 (`motion` & `canvas-confetti`)**:
   - 위저드 카드 간의 부드러운 수평 슬라이드 트랜지션.
   - 환불 접수 완료 및 환불 승인 시 기분 좋은 축하 파티클 폭죽.

---

## 3. 📦 설치된 패키지 1:1 B2C 역할 매핑표

| 패키지명 | B2C 소비자 적용처 |
| :--- | :--- |
| **`react` & `react-dom` (v19)** | 핵심 리액트 웹 런타임 |
| **`vite` & `@tailwindcss/vite`** | 초고속 HMR 번들러 및 유틸리티 CSS 엔진 |
| **`motion` (v14)** | 5단계 위저드 슬라이드 애니메이션, 도리 말풍선 인터랙션 |
| **`canvas-confetti`** | 반품 신청 완료 & 환불금 입금 확인 시 축하 파티클 |
| **`@xyflow/react` (v12)** | 내 사건 진행 단계(접수 ➔ 판매자 협의 ➔ 승인 ➔ 입금) 직관적 타임라인 |
| **`pdfjs-dist`** | 고객이 올린 해외 주문서/인보이스 PDF 즉시 열람 및 주문번호 자동 추출 |
| **`cropperjs`** | 스마트폰으로 찍은 택배 파손 부위/송장 사진 손쉬운 네모 크롭 |
| **`@uppy/core` & `@uppy/react`** | 최대 10MB 증빙자료 모바일 업로드 진행률 UI 및 자동 재시도 |
| **`react-hook-form` & `zod`** | 5단계 간편 신청 폼 상태 관리 및 주문번호/금액 실시간 검증 |
| **`@tanstack/react-query`** | 내 환불 내역 실시간 캐싱 및 백그라운드 동기화 |
| **`@tanstack/react-table`** | 내 전체 클레임 히스토리(신청일, 구매처, 환불금액, 상태) 정렬/조회 |
| **`chart.js` & `react-chartjs-2`** | 내가 도리를 통해 돌려받은 **"누적 환불 성공 금액"** 개인 지표 카드 |
| **`lucide-react`** | 쇼핑몰, 카메라, 송장, 환불금 등 친근한 모바일 아이콘 세트 |
| **`clsx` & `tailwind-merge`** | `src/lib/utils.ts`의 `cn` 유틸리티 함수 |

---

## 4. 🏛️ 시스템 아키텍처 및 디렉터리 구조 (100% B2C)

```
AI_Agent/
├── src/
│   ├── client/                  # [신규] React 19 B2C Web SPA
│   │   ├── components/          # 공통 UI 컴포넌트 (DoriMascot, Button, Card, Modal, Input)
│   │   ├── features/
│   │   │   ├── auth/            # 간편 로그인 / 회원가입 / 비밀번호 재설정
│   │   │   ├── claim-wizard/    # 5단계 간편 신청 위저드 (Uppy, Cropper, Zod, Motion)
│   │   │   ├── my-claims/       # 내 클레임 모아보기 (환불 진행 상태, 누적 환불액)
│   │   │   ├── claim-detail/    # 특정 사건 상세 (도리의 영문 편지, 판매자 답장 분석, 타임라인)
│   │   │   └── evidence/        # 영수증 PDF 뷰어 및 파손 사진 크롭 모듈
│   │   ├── hooks/               # React Query 커스텀 훅 (`useMyClaims`, `useAiDraft`)
│   │   ├── lib/                 # 유틸리티 (`api-client.ts`, `cn`, `format.ts`)
│   │   ├── types/               # TypeScript 인터페이스 및 Zod 스키마
│   │   ├── App.tsx              # B2C 최상위 라우터 및 프로바이더
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
- **소비자 클레임 (`/api/claims`)**:
  - `GET /api/claims`: 내 클레임 목록 조회
  - `POST /api/claims`: 신규 클레임 간편 접수 (위저드 완료 시 제출)
  - `GET /api/claims/:id`: 내 특정 사건 상세, 도리의 영문 편지, 진행 타임라인, 정산 내역
- **증빙 파일 (`/api/claims/:id/files`)**:
  - `POST /api/claims/:id/files`: 10MB 증빙 사진/영수증 업로드
- **AI 도리 어시스턴트 (`/api/ai/*`)**:
  - `POST /api/ai/draft`: Gemini 기반 영문/일문/중문 판매자 문의 편지 자동 생성
  - `POST /api/ai/analyze-reply`: 판매자가 보낸 답장 이메일 판독 (환불 승인/거절 여부 판정)
  - `POST /api/ai/extract-order`: 주문서 PDF 텍스트 자동 파싱

---

## 6. 🚀 100% B2C 단계별 구현 체크리스트 (Task Execution List)

AI 에이전트는 아래 체크리스트를 순차적으로 실행하며 완료 시 체크(`[x]`)합니다:

- [ ] **Phase 1: B2C 모바일 친화 Shell & 도리(Dori) 마스코트 셋업**
  - [ ] `index.html` 연동 및 `src/client/main.tsx` React 19 엔트리포인트 구성
  - [ ] 도리(Dori) 펭귄 캐릭터 SVG 컴포넌트 및 최소 2.5초 노출 애니메이션 구현
  - [ ] 모바일 퍼스트 바텀 네비게이션바 [신청하기 / 내 환불 / 설정] 셸 구축
  - [ ] 간편 인증(로그인, 회원가입) 폼 연동 (`react-hook-form` + `zod`)

- [ ] **Phase 2: B2C 5단계 간편 신청 위저드 (Core Wizard)**
  - [ ] Step 1: 구매 쇼핑몰(아마존, 알리, 타오바오 등) 원클릭 로고 선택 & 주문번호 입력
  - [ ] Step 2: 문제 유형 선택(파손/오배송/미도착) 및 피해 금액/통화 입력
  - [ ] Step 3: 피해 내용 간편 선택 및 상세 설명 작성
  - [ ] Step 4: Uppy + Cropper.js 연동 10MB 파손 사진 크롭 및 영수증 업로드 UX
  - [ ] Step 5: 최종 요약 확인 & 원클릭 접수 (`motion` 슬라이드 전환 + 완료 시 `canvas-confetti`)

- [ ] **Phase 3: 내 환불 현황 대시보드 & 타임라인**
  - [ ] 진행 중인 내 사건 요약 카드 (지금 해야 할 일 안내)
  - [ ] 내가 돌려받은 누적 환불액 통계 카드 (`Chart.js`)
  - [ ] `@xyflow/react` 기반의 배송조회 스타일 단계별 환불 진행 타임라인
  - [ ] `@tanstack/react-query`를 통한 내 사건 목록 실시간 동기화

- [ ] **Phase 4: AI 도리 영문 조율 & 증빙 PDF 뷰어**
  - [ ] 도리가 대신 써준 영문 판매자 문의 편지 미리보기 및 복사/전송 다이얼로그
  - [ ] `pdfjs-dist` 기반의 인보이스 PDF 영수증 브라우저 즉시 뷰어
  - [ ] 판매자 수신 메일 붙여넣기 및 AI 환불 승인/거절 자동 판정 화면

- [ ] **Phase 5: 내 사건 이력 & 환불 정산 원장 (Consumer Ledger)**
  - [ ] `@tanstack/react-table` 기반의 내 과거 클레임/환불 이력 모아보기
  - [ ] 환불 입금 영수증 기록 및 내 정산 내역 확인 화면

- [ ] **Phase 6: QA 및 프로덕션 검증**
  - [ ] TypeScript 정적 타입 검사 (`npm run typecheck` ➔ 0 errors)
  - [ ] Biome 린트/포매팅 검사 (`npm run lint`)
  - [ ] 기존 백엔드 63개 유닛/HTTP 테스트 통과 유지 (`npm test`)
  - [ ] Playwright E2E 브라우저 흐름 및 웹 접근성 검사 (`npm run test:browser`)
