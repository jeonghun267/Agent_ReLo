# ReLo 2.0.0 Flutter Application (`flutter_app/`)

해외직구 반품 · 교환 · 환불 원스톱 기록 및 **실제 카드 취소·통장 입금 확인** B2C 서비스 **ReLo**의 공식 Flutter 크로스플랫폼 애플리케이션입니다.

- **승인된 디자인**: 실배포 미드나잇 다크 블루 (`#0F172A`) + 3D 블루 오브 엠블럼 + 토스 일렉트릭 블루 (`#1B64DA`) + 라이트 모드 + **시각 약자용 WCAG AAA 초고대비 모드**
- **20대 법적 컴플라이언스 완비**: 개인정보 처리방침, 이용약관, 환불정책, 쿠키정책, 다크패턴 없는 쿠키동의 배너, 양식 필수/선택 동의 체크박스, 최소수집 원칙, 외부 SDK 점검, 숨겨진 요금 0원, 가짜후기/과장광고 배제, 접근성 대체 텍스트(Semantics), 명도 대비 개선, 키보드 전용 이동(`Tab`/`Enter`), 사업자 정보 푸터, 만 14세 연령 확인, 원클릭 이메일 수신거부, 글꼴/이미지 이용권 검증, 개인정보 즉시 파기 요청.
- **인수인계 표준 아키텍처**: 기능별(`lib/features/`) + 공통(`lib/shared/`) + 코어(`lib/core/`) 3계층 모듈 분리 ([ARCHITECTURE.md](./ARCHITECTURE.md) 참조).

---

## 다른 개발자 로컬 실행 방법 (GitHub Clone 시)

일반적인 개발 환경(본인 PC)에서는 Flutter의 표준 명령어로 즉시 구동됩니다.
`pubspec.lock`에 패키지 버전이 정확히 핀(Pin) 고정되어 있어 구형/신형 패키지 충돌이 발생하지 않으며, `.dart_tool/` 등 로컬 머신 경로는 Git에서 제외되어 있으므로 본인 PC 환경에 맞춰 자동 생성됩니다.

```bash
# 1) 루트에서 ReLo 백엔드 서버 구동 (포트 4180)
npm start

# 2) Flutter 앱 디렉토리로 이동 및 패키지 설치
cd flutter_app
flutter pub get

# 3) 앱 실행 (Windows, Chrome, Edge, Android, iOS 등)
flutter run -d windows
# 또는 브라우저 실행: flutter run -d chrome
```

---

## 테스트 및 코드 검증

```bash
# 정적 분석 (dart analyze)
flutter analyze

# 390px 모바일 뷰포트 위젯 테스트 (flutter test)
flutter test
```

> **참고 (사내망/다중 계정 Windows 환경 지원)**:
> 별도의 Windows 배치 스크립트([test_flutter.bat](./test_flutter.bat), [run_flutter.bat](./run_flutter.bat))는 PATH에 Flutter가 설치되어 있으면 표준 명령어로 자동 동작하고, 특정 오프라인 샌드박스 PC 환경인 경우 로컬 캐시 폴백으로 자동 전환됩니다.
