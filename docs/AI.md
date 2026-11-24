# AI (Google Gemini)

이 문서는 AI 기능의 설정과 사용법이다. 지금 코드의 어디가 에이전트다운지는 [`AGENT_INVENTORY.md`](./AGENT_INVENTORY.md), LLM이 도구를 고르는 루프를 더하는 계획은 [`AGENT_LOOP_PLAN.md`](./AGENT_LOOP_PLAN.md)에 있다.

## 설정

1. [Google AI Studio](https://aistudio.google.com/)에서 API 키를 만든다.
2. 프로젝트 루트 `.env`에 넣는다. `.env`는 git에 올라가지 않는다.
   ```
   GEMINI_API_KEY=발급받은키
   GEMINI_MODEL=            # 비우면 gemini-3.5-flash-lite
   AI_HOURLY_LIMIT=30       # 사용자 1명이 한 시간에 쓸 수 있는 AI 호출 수
   AGENT_MAX_STEPS=5        # 에이전트 실행 한 번의 최대 단계 수 (한 단계 = AI 호출 2번)
   AGENT_AUTO_DELAY_MS=4000 # 일이 생긴 뒤 에이전트가 스스로 시작하기까지 기다리는 시간 (잇단 일을 한 번으로 묶는다)
   AGENT_NOTICE_DELAY_MS=600000 # 스스로 시작한 에이전트가 허락을 기다린 지 이만큼 지나도 답이 없으면 알림 메일 한 통 (기본 10분)
   ```
3. `npm run ai:smoke`로 네 기능을 실제로 한 번씩 호출해 확인한다. (새 클레임의 "주문서로 자동 채우기"는 주문 정보 읽기와 같은 프롬프트를 쓴다.)
4. `npm start`로 서버를 띄운다.

**모델 선택** (2026-10 Google 문서 기준)
- `gemini-3.5-flash-lite`(기본): 새 프로젝트용 저비용 모델로 권장된다.
- `gemini-3.8-flash`: 문장 품질이 더 필요할 때 쓴다.
- `gemini-2.5-*`: 이전에 써 본 계정만 쓸 수 있다.

키가 없으면 `disabled` provider가 쓰인다. 화면에서 AI 버튼이 사라지고, 문의는 기본 영문 틀(`domain/draft-template.mjs`)로 시작한다.

## 기능

| 기능 | API | 보내는 것 | 받는 것 | 프롬프트 |
|---|---|---|---|---|
| 문의 초안 | `POST /api/claims/:id/ai/draft` | 저장된 사건 사실(판매처, 주문번호, 품목, 금액, 문제 설명, 증빙 파일 **이름**, 최근 답변 3개) | 제목·본문(영문), 한국어 요약, 채워야 할 정보 | `ai/prompts/draft.mjs` |
| 문제 설명 번역 | `POST /api/ai/translate-issue` | 입력한 한국어 문장 | 영문 | `ai/prompts/translate.mjs` |
| 답변 분석 | `POST /api/claims/:id/ai/analyze-reply` | 붙여 넣은 판매처 답변 + 사건 요약 | 한국어 번역·요약, 추천 유형, 언급된 금액·기한 | `ai/prompts/translate.mjs` |
| 주문 정보 읽기 | `POST /api/claims/:id/ai/extract` | 선택한 증빙 파일(PDF·이미지) | 판매처, 주문번호, 주문일, 통화, 품목, 원문 인용 | `ai/prompts/extract.mjs` |
| 도우미 상담 (앱) | `POST /api/ai/assistant` | 질문, 직전 대화 10개, 내 클레임 요약 최대 20건(상품·판매처·주문번호·종류·상태·금액·기한·다음 할 일). 특정 건에서 물으면 그 건의 문제 설명과 최근 답변 1개 | 한국어(또는 앱 언어) 답변, 버튼 하나(`open_claim`·`draft_email`·`analyze_reply`·`new_claim`·`none`), 이어서 물을 질문 3개 | `ai/prompts/assistant.mjs` |
| 에이전트 실행 (웹) | `POST /api/claims/:id/ai/agent`, 허락 · 거절은 `POST …/ai/agent/:runId/decision`, 기다리는 실행과 지난 실행은 `GET …/ai/agent` | 고를 때마다: 건의 목표와 저장된 사건의 요약(판매처, 주문번호, 상태, 금액, 파일 이름 목록, 답변 앞부분 300자), 앞 단계의 결과 요약, 같은 건의 지난 실행 2번(고른 도구 · 허락 여부 · 그때 한 말). 읽는 도구가 실행될 때는 위 세 기능이 보내는 것. 허락 · 거절과 저장은 AI 호출이 아니다 | 단계마다 고른 도구 · 고른 까닭 · 그 도구의 결과, 허락을 기다리는 제안(무엇이 바뀌는지), 끝난 까닭, 사용자가 다음에 할 일 | `ai/prompts/plan.mjs` |
| 한 줄로 신청 읽기 (새 클레임 1단계) | `POST /api/ai/intake` | 사용자가 적은 한 줄, 주문서에서 읽은 상품의 이름 · 수량(금액은 보내지 않는다) | 종류(환불 · 교환 · 수리), 어느 상품, 몇 개, 영문 설명, AI가 이해한 한 문장 | `ai/prompts/intake.mjs` |
| 주문서로 자동 채우기 (새 클레임 1단계) | `POST /api/ai/extract` (파일 원본을 본문으로, 이름은 `X-File-Name`) | 사용자가 고른 주문서 파일(PDF·이미지). 클레임이 아직 없을 때 쓴다 | 위와 같음 | `ai/prompts/extract.mjs` |

**도우미 상담**은 아무것도 저장하거나 바꾸지 않는다. 답과 함께 버튼 하나만 제안하고, 버튼의 `claimId`가 그 사용자의 클레임이 아니면 서버가 버튼을 지운다. 이름·이메일·주소·파일은 보내지 않는다. 앱 쪽 화면과 서버가 없을 때의 동작은 [`flutter_app/README.md`](../flutter_app/README.md)에 있다.

**에이전트 실행**은 건의 목표를 받고, 모델이 도구 다섯 가운데 무엇을 할지 스스로 고르고, 서버가 그것을 실행해 결과를 다음 고르기에 넣는 루프다(`services/agent.service.mjs`). 읽는 도구 셋(`read_evidence` 주문 정보 읽기 · `analyze_reply` 답변 분석 · `write_draft` 문의 초안)은 위의 기존 기능 그대로이고 바로 실행된다. 건을 바꾸는 도구 둘(`fix_order_facts` 주문번호 · 주문일을 자료대로 고치기, `save_draft` 쓴 글을 건에 저장하기)은 실행이 멈춰서 사람에게 묻고, 허락한 것만 기존 저장 길(`claims.update`, `drafts.save`)로 한다. 바꾸는 값은 모델이 주지 않고 서버가 읽은 것에서 온다. 보내는 도구는 없다. 모델이 고른 도구 이름과 파일 · 답변 id는 서버가 다시 검사한다. 정의와 견준 표는 [`AGENT_DEFINITION.md`](./AGENT_DEFINITION.md)에 있다. 자세한 것은 [`AGENT_INVENTORY.md`](./AGENT_INVENTORY.md)의 "에이전트 실행".

**주문서로 자동 채우기**는 업로드와 같은 형식·크기 검사(`checkFile`)를 거친 뒤 파일을 Gemini에 보내고, **서버에는 저장하지 않는다**. 사용 기록(`ai_usage`)은 `claim_id` 없이 남는다. 화면은 읽은 값으로 칸을 채워 보라색으로 표시하고, 그 파일을 4단계 증빙 목록에 넣어 둔다. 증빙은 사용자가 [등록하기]를 누른 뒤 일반 업로드로 저장된다.

각 프롬프트 파일에는 세 가지가 함께 있다.
- `build*Request`: 요청을 만든다. 사용자 데이터는 `<claim_facts>` 같은 태그 안에 넣어서 지시문과 구분한다.
- 응답 스키마(Gemini `responseSchema`)
- `parse*`: 서버에서 응답을 다시 검증하고 이상한 값은 버린다.

## 안전장치

- **동의**: `users.ai_consent_at`이 없으면 서버는 `403 ai_consent_required`를 돌려준다. 웹은 AI를 부르기 전에 문 하나(`src/client/components/AiConsentDialog.tsx`의 `useAiConsentGate`)를 지난다. 동의가 없으면 무엇이 Google(국외)로 가는지 적은 창을 띄우고, [동의하고 계속하기]를 누른 뒤에만 동의를 저장하고 호출한다. 거절하면 아무것도 보내지 않는다. 설정 화면에서 철회할 수 있고, 다시 켤 때도 같은 창을 거친다.
- **자동 저장 없음**: AI 응답은 미리보기다. 금액·상태는 사용자가 저장해야 바뀐다. 주문서에서 읽은 합계는 청구액에 넣지 않는다(부분 청구일 수 있음). 새 클레임에서는 품목의 "문제 수량 × 단가" 합계를 [청구액으로 쓰기]로 제안만 한다.
- **보이는 표시**: AI가 만든 것 아래에는 "AI가 쓴 글이에요", "AI가 읽고 정리한 내용이에요", "AI가 영수증을 읽어 채운 값이에요", "AI가 옮긴 영어예요"가 한 줄씩 남고, 저장된 답장에는 "AI 요약"이 붙는다. 답변 분석은 추천 유형을 미리 골라 둔다.
- **출력 검증**: 형식이 틀리면 `502 ai_bad_output`. 통화·날짜·금액이 해석되지 않으면 null로 버린다.
- **한도**: 사용자별 시간당 `AI_HOURLY_LIMIT`회. 실패한 호출도 센다. 에이전트 실행은 읽는 도구 한 단계에 2번(고르기 + 도구), 건을 바꾸는 한 단계에 1번(고르기)이라 한 번에 최대 `2 × AGENT_MAX_STEPS`번(기본 10번)을 쓰고, 그만큼 남아 있지 않으면 시작하지 않는다. 에이전트가 **스스로 시작할 때**(사용자가 "스스로 시작하기"를 켠 경우, 신청 · 자료 추가 · 답장 저장 때)는 거기에 더해 한도의 6분의 1(기본 5번)이 남아 있어야 한다. 사람이 직접 누를 몫을 남기기 위해서다. 모자라면 시작하지 않고 화면에 까닭을 적는다.
- **실패 처리**: 네트워크 오류·429·5xx는 1회 재시도하고, 시간 제한은 30초다. 실패하면 화면은 못 했다고 알리고, 그럴듯한 결과를 지어내지 않는다. 앱은 글 쓰기만 기본 영문 틀로 대신하고 AI가 쓴 글이 아니라고 알린다(`flutter_app/test/ai_honesty_test.dart`).
- **키 보호**: 키는 `x-goog-api-key` 헤더로만 보낸다. 오류 메시지·로그·응답에 키나 Gemini 응답 본문을 남기지 않는다(`tests/unit/gemini.test.mjs`).

## 비용 확인

모든 호출이 `ai_usage` 표에 남는다.

```sql
SELECT capability, COUNT(*) AS calls, SUM(ok) AS ok,
       SUM(input_tokens) AS input_tokens, SUM(output_tokens) AS output_tokens
FROM ai_usage WHERE created_at >= date('now', '-30 days')
GROUP BY capability;
```

## 새 AI 기능 추가

1. `ai/prompts/새기능.mjs`에 `build*Request`(capability 이름, system, parts, schema)와 `parse*`를 만든다.
2. `services/ai.service.mjs`에 `run(user, claimId, request, parse)`를 쓰는 함수를 추가한다. 동의·한도·기록이 자동으로 적용된다.
3. `routes/ai.routes.mjs`에 경로를, `src/client/` API 연동 모듈에 함수를 추가한다.
4. `ai/fake.provider.mjs`에 시험용 응답을 추가하고 `tests/http/ai.test.mjs`에 시험을 쓴다.
5. `scripts/ai-smoke.mjs`에 실제 호출 확인을 한 줄 추가한다.
6. 에이전트가 고를 수 있는 도구로 만들려면 `ai/prompts/plan.mjs`의 `READ_TOOLS`와 도구 설명, `services/agent.service.mjs`의 `READERS`에 더한다. 건을 바꾸는 도구는 `ACTION_TOOLS`에 더하고, `propose`(무엇이 바뀌는지 만들기)와 `act`(허락된 뒤 기존 서비스로 저장)에 넣는다. 값은 모델에게 받지 않는다. 보내는 도구는 넣지 않는다.

모델이 사건의 상태에 따라 다르게 고르는지는 `npm run agent:branch`로 본다(진짜 Gemini, 여섯 경우를 3번씩 18번 호출, 이어서 신청 한 줄 읽기 세 문장을 한 번씩 3번 호출). 키가 거절되면 첫 호출에서 멈추고 알려 준다. 2026-11-24에 쟀고, 결과와 한계는 [`AGENT_LOOP_PLAN.md`](./AGENT_LOOP_PLAN.md) 10절 끝에 있다.

## 개인정보

- **알림 메일**: 스스로 시작한 에이전트가 허락을 기다리는데 `AGENT_NOTICE_DELAY_MS` 동안 답이 없으면, 서버가 1분마다 도는 점검에서 그 사람의 **인증된** 이메일로 한 통을 보낸다(`agent.service.mjs` `notifyWaiting`, 실행 하나에 한 통, `agent_runs.notified_at`). 사람이 직접 누른 실행 · 인증하지 않은 주소 · 스스로 시작하기를 끈 사람 · 알림 메일을 끈 사람(`users.notice_mail_off_at`, `POST /api/account/notice-mail`) · 휴지통이나 끝난 건에는 보내지 않는다. 메일에는 쇼핑몰 · 상품 · 금액 같은 주문 내용을 넣지 않고, 기다린다는 사실과 답할 주소만 넣는다. 메일 서비스가 꺼져 있으면(`MAIL_PROVIDER=disabled`) 아무것도 하지 않는다.

AI 기능을 쓰면 위 표의 "보내는 것"이 Google 서버(국외)로 전송된다. 웹의 동의 창 문구는 `src/client/i18n/screens/settings.ts`의 `consent`에, 앱의 문구는 `flutter_app/lib/core/i18n/relo_i18n.dart`의 `assistantConsentBody`와 `auC4Sub`에 있다. 이 동의 하나가 AI 기능 전부를 켜므로, 문구에는 기능 전부가 보내는 것을 적는다. AI 기능을 더하면 이 문구도 함께 고친다. 상용 운영 전에 다음이 필요하다.
- Gemini **유료 등급**으로 전환. 무료 등급은 입력이 Google의 모델 개선에 쓰일 수 있다.
- 개인정보처리방침의 국외 이전 항목 법률 검토. 동의 창에는 받는 곳의 나라와 보유 기간이 아직 없다(요금제를 정한 뒤 채운다).
