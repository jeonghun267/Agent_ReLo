# ReLo 2.0.0 Flutter Application (`flutter_app/`)

해외직구 반품 · 교환 · 환불 원스톱 기록 및 **실제 카드 취소·통장 입금 확인** B2C 서비스 **ReLo**의 공식 Flutter 애플리케이션입니다.
- **승인된 디자인**: 실배포 미드나잇 다크 블루(`#0F172A`) + 3D 블루 오브 엠블럼 + 토스 일렉트릭 블루(`#1B64DA`) + 라이트 모드 + **시각 약자용 WCAG AAA 초고대비 모드**
- **20대 법적 컴플라이언스 완비**: 개인정보 처리방침, 이용약관, 환불정책, 쿠키정책, 다크패턴 없는 쿠키동의 배너, 양식 필수/선택 동의 체크박스, 최소수집 원칙, 외부 SDK 점검, 숨겨진 요금 0원, 가짜후기/과장광고 배제, 접근성 대체 텍스트(Semantics), 명도 대비 개선, 키보드 전용 이동(`Tab`/`Enter`/`Alt+1~5`), 사업자 정보 푸터, 만 14세 연령 확인, 원클릭 이메일 수신거부, 글꼴/이미지 이용권 검증, 개인정보 즉시 파기 요청.
- **인수인계 표준 아키텍처**: 기능별(`lib/features/`) + 공통(`lib/shared/`) + 코어(`lib/core/`) 3계층 모듈 분리 ([ARCHITECTURE.md](file:///c:/Users/user_34/Agent_ReLo/flutter_app/ARCHITECTURE.md) 참조).

---

## 실행 방법

```powershell
# 1) (선택) 루트 폴더에서 ReLo 백엔드 서버 실행
npm start

# 2) Flutter 앱 실행
cd flutter_app
flutter pub get
flutter run -d windows   # 또는 chrome, edge, android, ios
```
