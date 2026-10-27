/**
 * @module client/i18n/ko
 * @layer Model (Localization Dictionary)
 * @purpose Default Korean consumer copy written in plain, everyday language
 *          with zero industry/developer jargon and zero legacy character names.
 */

export const koMessages = {
	common: {
		skipToContent: "본문으로 바로 이동",
		loadingScreen: "화면을 준비하고 있어요...",
		notFoundSpeech: "찾으시는 페이지 주소가 바뀌었거나 없는 화면이에요.",
		backHome: "처음 화면으로 돌아가기",
	},
	nav: {
		about: "서비스 소개",
		aboutMobile: "홈",
		apply: "환불 신청",
		applyMobile: "신청하기",
		myRefunds: "내 환불",
		myRefundsMobile: "내 환불",
		settings: "설정",
		settingsMobile: "설정",
		login: "로그인",
		applyCta: "환불 신청하기",
		userSuffix: "님",
		verifyNoticePrefix: "환불 진행 알림을 받으려면",
		verifyNoticeSuffix: "메일함을 확인해 주세요.",
		resendVerify: "인증 메일 다시 보내기",
		sending: "보내는 중...",
		languageLabel: "언어 선택",
	},
	hero: {
		badge: "해외직구 반품 · 환불 · 입금 확인 도우미",
		titleLine1: "멀리서 깨져서 온 해외직구 택배,",
		titleHighlight: "외국어 한 줄 몰라도 내 통장으로 환불.",
		subtitle:
			"주문 영수증 자동 입력부터 집 주소 가리기, 쇼핑몰에 보낼 외국어 환불 메시지 작성, 그리고 실제 카드 취소 확인까지 한곳에서 쉽게 끝내세요.",
		primaryCta: "지금 3분 만에 환불 신청하기",
		secondaryWallet: "내 환불 내역 보기",
		secondaryGlobe: "전 세계 환불 경로 보기",
		trust1: "8개국 통화 정확한 금액 계산",
		trust2: "내 사진·영수증 10MB 안전 보관",
		trust3: "말뿐인 약속이 아닌 실제 카드 취소 확인",
	},
	malls: {
		us: "미국",
		global: "글로벌",
		cn: "중국",
		jp: "일본",
		usUk: "미국·영국",
		euCa: "유럽·캐나다",
		tagAmazon: "영문 환불 메시지 즉시 작성",
		tagAli: "파손 사진 첨부 환불",
		tagTaobao: "다른 상품 도착·누락 해결",
		tagMercari: "일본어·영어 정중한 요청",
		tagIherb: "샜거나 깨진 상품 환불",
		tagEbay: "판매자 환불 약속 기록",
		tagFarfetch: "불량 상품 반품비 아끼기",
		tagTemu: "불량 상품 원화 환불",
	},
	globe: {
		eyebrow: "한눈에 보는 글로벌 환불 경로",
		titleLine1: "바다 건너 묶여 있던 내 돈,",
		titleLine2: "서울 내 계좌까지 곧장 돌아오도록.",
		description:
			"미국·일본·중국·유럽 어디서 샀든 걱정하지 마세요. 해외 쇼핑몰로 환불 요청 메시지가 비행기를 타고 날아가고, 실제로 카드 결제가 취소될 때까지 모든 과정을 챙겨드립니다.",
		routeSuffix: "실시간 환불 경로",
		startThisMall: "이 쇼핑몰 환불 시작하기",
		seoulHubLabel: "서울 · 내 계좌 도착",
		dragHint: "지구본을 마우스나 손가락으로 돌려보거나 나라 버튼을 눌러보세요",
		canvasAria:
			"미국, 일본, 중국, 유럽 대륙 위에서 비행기가 서울로 날아오며 환불 경로를 보여주는 3D 세계지도 지구본",
		corridors: {
			usSea: {
				country: "미국",
				status: "해외카드 결제 취소 완료",
				issue: "택배 상자와 제품 겉면이 깨진 상태로 도착했습니다.",
			},
			jpTyo: {
				country: "일본",
				status: "다른 상품 도착 · 전액 환불",
				issue: "주문한 것과 다른 색상의 상품이 배송되었습니다.",
			},
			cnSzx: {
				country: "중국",
				status: "반품 없이 바로 환불 완료",
				issue: "전원이 켜지지 않는 불량 상품이 도착했습니다.",
			},
			euLon: {
				country: "유럽",
				status: "쇼핑몰 고객센터 환불 확정",
				issue: "구성품 일부가 빠져 있고 포장 상자가 뜯어져 도착했습니다.",
			},
			usLax: {
				country: "미국 서부",
				status: "파손 사진 확인 후 즉시 승인",
				issue: "용기가 깨져서 내용물이 새어 나온 상태로 도착했습니다.",
			},
		},
	},
	phoneStory: {
		eyebrow: "스크롤로 보는 3분 해결 과정",
		headline: "복잡한 일은 휴대폰 안에서 알아서 끝납니다",
		scrollHint: "아래로 스크롤하면 휴대폰 화면 밖으로 핵심 카드가 떠오릅니다",
		scenes: [
			{
				step: "01",
				tab: "영수증 넣기",
				badge: "영수증 자동 입력 · 집 주소 가리기",
				titleLine1: "길고 복잡한 외국어 영수증,",
				titleLine2: "사진 한 장만 툭 넣으세요.",
				description:
					"해외 쇼핑몰 결제 내역서에서 주문번호와 가격을 일일이 찾을 필요가 없습니다. 캡처나 PDF를 올리면 자동으로 칸이 채워지고, 택배 상자에 적힌 집 주소와 전화번호는 깔끔하게 잘라냅니다.",
				screenHeader: "주문 영수증 자동 읽기",
				screenStatus: "자동 입력 완료",
				screenSubTitle: "자동으로 찾은 주문 정보",
				popLeftTitle: "주문번호 3초 자동 입력",
				popLeftSub: "#114-8920411 · $184.00",
				popRightTitle: "집 주소·연락처 가리기",
				popRightSub: "불량 부분만 선명하게 남김",
			},
			{
				step: "02",
				tab: "외국어 메시지 완성",
				badge: "쇼핑몰 맞춤 외국어 자동 작성",
				titleLine1: "우리말로 한 줄만 적으면,",
				titleLine2: "쇼핑몰에 보낼 외국어가 완성됩니다.",
				description:
					"번역기를 돌리며 어떤 단어를 써야 할지 고민하지 마세요. 파손 상태와 환불 요청 금액을 빠짐없이 담은 정중하고 분명한 외국어 메시지를 바로 만들어 드립니다.",
				screenHeader: "쇼핑몰 고객센터 발송용 메시지",
				screenStatus: "복사 준비 완료",
				screenSubTitle: "내가 적은 우리말 사유",
				popLeftTitle: "영어·일본어·중국어 지원",
				popLeftSub: "쇼핑몰 환불 규정에 맞춘 문장",
				popRightTitle: "억울한 반품 배송비 방어",
				popRightSub: "판매자 과실 조항 자동 포함",
			},
			{
				step: "03",
				tab: "실제 입금 확인",
				badge: "말뿐인 약속 방지 · 2단계 입금 확인",
				titleLine1: "“환불해 드렸어요” 말만 믿고",
				titleLine2: "기다리다 놓치지 않도록.",
				description:
					"해외 쇼핑몰이 환불을 약속만 하고 실제 카드 취소를 늦추거나 빠뜨리는 일을 막아줍니다. 판매자가 약속한 금액과 내 카드에 진짜 돌아온 금액을 나란히 비교해 끝까지 챙깁니다.",
				screenHeader: "내 카드 취소 최종 확인",
				screenStatus: "전액 입금 완료",
				screenSubTitle: "남은 받아야 할 금액 $0.00",
				popLeftTitle: "해외카드 결제 취소 도착",
				popLeftSub: "AMZ*REFUND +$184.00 확인",
				popRightTitle: "약속 금액 vs 실제 입금액 대조",
				popRightSub: "1원까지 빠짐없이 입금 확인",
			},
		],
	},
	whyRelo: {
		eyebrow: "왜 ReLo를 쓰나요?",
		titleLine1: "배송대행 업체도, 일반 번역기도",
		titleLine2: "도와주지 못하던 순간을 해결합니다.",
		description:
			"물건이 이미 한국 우리 집에 도착한 뒤에 발견한 파손과 불량. 어디에 말해야 할지 막막했던 해외직구 문제를 처음부터 입금까지 함께합니다.",
		colTopic: "비교 항목",
		colAgent: "기존 배송대행 업체",
		colTranslator: "혼자 번역기 사용",
		colRelo: "ReLo 환불 도우미",
		rows: [
			{
				topic: "우리 집 도착 후 상자를 열어보니 깨져 있을 때",
				agent: "해외 창고에서 출발하면 도움 종료",
				translator: "쇼핑몰 환불 규정을 직접 찾아야 함",
				relo: "집에서 개봉한 직후부터 끝까지 안내",
			},
			{
				topic: "해외 쇼핑몰 문의 및 비싼 반품 배송비 문제",
				agent: "별도 수수료 + 비싼 국제 반송비 부담",
				translator: "단순 번역이라 핵심 환불 조건이 빠짐",
				relo: "반품비 부담을 줄이는 맞춤 외국어 작성",
			},
			{
				topic: "택배 상자에 적힌 집 주소·개인정보 보호",
				agent: "원본 사진 그대로 전달되어 노출 위험",
				translator: "사진 편집 앱으로 직접 가려야 함",
				relo: "화면에서 바로 불량 부분만 쉽게 자르기",
			},
			{
				topic: "말로만 환불해 주고 실제 돈이 안 들어올 때",
				agent: "입금 여부 확인 불가",
				translator: "입금 여부 확인 불가",
				relo: "쇼핑몰 약속 금액과 실제 카드 취소 2번 확인",
			},
		],
	},
	flow: {
		eyebrow: "한눈에 보는 5단계 진행 순서",
		title: "신청부터 내 통장 입금까지, 택배 조회처럼 쉽게",
		subtitle:
			"원하는 단계를 눌러 각 과정에서 어떻게 도와드리는지 직접 확인해 보세요.",
		startBtn: "이 순서 그대로 내 환불 시작하기",
		steps: [
			{
				id: "scan",
				stepNo: "1단계",
				title: "주문 영수증 읽기",
				subtitle: "사진·PDF 자동 입력",
				badge: "3초 자동 입력",
				guide:
					"결제 내역 캡처나 영수증 파일만 올리면 쇼핑몰 이름, 주문번호, 금액을 알아서 채워드려요.",
				previewTitle: "자동으로 읽어온 주문 정보 예시",
				sample:
					"쇼핑몰: Amazon US · 주문번호 #114-8920411 · 주문일: 2026-10-18 · 상품: 무선 헤드폰 ($298.00)",
				points: [
					"작은 글씨 영수증도 화면에서 바로 크게 확인",
					"주문번호와 결제 금액을 일일이 칠 필요 없음",
				],
			},
			{
				id: "crop",
				stepNo: "2단계",
				title: "불량 사진 준비",
				subtitle: "집 주소 가리고 확대",
				badge: "사진 자르기",
				guide:
					"택배 스티커의 집 주소는 잘라내고, 깨지거나 긁힌 부분만 선명하게 남겨보세요.",
				previewTitle: "내 전용 사진 보관함 (최대 10MB)",
				sample:
					"[자르기 완료] 깨진_모서리_사진.png (1.4 MB · 내 계정에만 안전하게 암호화 보관됨)",
				points: [
					"손가락이나 마우스로 필요한 부분만 네모로 자르기",
					"내가 올린 사진은 오직 내 계정에서만 열람 가능",
				],
			},
			{
				id: "draft",
				stepNo: "3단계",
				title: "외국어 요청서 작성",
				subtitle: "복사해서 바로 전송",
				badge: "자동 번역·작성",
				guide:
					"우리말로 겪은 문제를 편하게 적어주세요. 해외 상담원이 바로 이해하는 정중한 외국어 메시지로 바꿔드립니다.",
				previewTitle: "해외 쇼핑몰 고객센터에 보낼 메시지",
				sample:
					"Subject: Refund Request for Damaged Item — Order #114-8920411\n\nDear Customer Support, The item arrived with exterior damage as shown in the attached photos. Could you please process a full refund of USD 298.00?",
				points: [
					"없는 사실을 지어내지 않고 내 주문 정보만 정확히 반영",
					"복사 버튼 한 번으로 쇼핑몰 채팅이나 이메일에 붙여넣기",
				],
			},
			{
				id: "reply",
				stepNo: "4단계",
				title: "판매자 답장 요약",
				subtitle: "쉬운 한국어 3줄 정리",
				badge: "답장 쉬운 해석",
				guide:
					"쇼핑몰에서 긴 외국어 답장이 왔나요? 붙여넣기만 하면 핵심 내용과 반품 기한을 쉽게 알려드려요.",
				previewTitle: "외국어 답장 핵심 요약 예시",
				sample:
					"[해석 결과: 환불 약속] 쇼핑몰에서 물건 반송 없이 $298.00 전액 환불을 약속했어요. 3~5일 뒤 실제 카드 취소 내역을 확인해 주세요!",
				points: [
					"'환불해 주겠다는 말'과 '실제 돈이 들어온 것'을 구분해 안내",
					"놓치기 쉬운 반품 마감 날짜를 콕 집어서 표시",
				],
			},
			{
				id: "settled",
				stepNo: "5단계",
				title: "실제 입금 확인",
				subtitle: "카드 취소 · 계좌 입금",
				badge: "입금 최종 확인",
				guide:
					"마지막으로 내 카드나 통장에 진짜 돈이 돌아왔는지 확인하고 깔끔하게 마무리해요.",
				previewTitle: "내 환불 입금 완료 확인표",
				sample:
					"실제 입금 확인: $298.00 / 약속 금액 $298.00 (남은 받을 금액 $0.00 · 카드 취소 확인 완료)",
				points: [
					"일부 금액만 들어왔다면 덜 받은 금액을 자동 계산",
					"입금 내역까지 확인되어야 안심 종료 처리",
				],
			},
		],
	},
	simulator: {
		eyebrow: "내가 돌려받을 금액 계산기",
		title: "얼마짜리 직구 상품에 문제가 생겼나요?",
		subtitle: "선택한 쇼핑몰과 금액 그대로 신청 화면을 바로 열 수 있어요.",
		mallLabel: "구매한 쇼핑몰",
		issueLabel: "어떤 문제가 생겼나요?",
		priceLabel: "결제했던 금액",
		previewBadge: "자동으로 작성될 영문 메시지 미리보기",
		barSolo: "혼자 번역기로 문의할 때",
		barRelo: "ReLo로 꼼꼼히 신청할 때",
		expectedLabel: "예상 환불 금액",
		completenessLabel: "서류 준비도",
		extraTitle: "혼자 끙끙 앓을 때보다 기대할 수 있는 추가 환불액",
		extraSuffix: "더 지킬 수 있어요",
		applyWithPreset: "이 조건으로 바로 신청하기",
		scenarios: {
			damaged: {
				label: "깨져서 도착",
				issue:
					"택배 상자를 열었을 때 겉상자와 제품 모서리가 깨져서 사용할 수 없습니다.",
			},
			wrong: {
				label: "다른 상품·누락",
				issue: "주문한 옵션과 다른 상품이 왔고 구성품 일부가 빠져 있습니다.",
			},
			defect: {
				label: "작동 안 됨",
				issue: "받자마자 전원을 연결해 보았지만 작동하지 않는 불량 상품입니다.",
			},
		},
	},
	closingCta: {
		titleLine1: "쇼핑몰 환불 기한이 지나기 전에,",
		titleLine2: "지금 바로 내 돈을 지키세요.",
		subtitle: "주문번호와 사진 한 장이면 3분 안에 충분합니다.",
		button: "3분 만에 환불 신청하기",
	},
	footer: {
		sloganLine1: "직구 시작부터 환불 입금까지",
		sloganLine2: "마침내 ReLo 하나로.",
		colService: "서비스 안내",
		serviceLinks: [
			{ label: "서비스 소개 홈", to: "/" },
			{ label: "3분 간편 환불 신청", to: "/wizard" },
			{ label: "내 환불 내역 조회", to: "/claims" },
			{ label: "외국어 요청서 자동 작성", to: "/wizard" },
			{ label: "판매자 답장 쉬운 해석", to: "/claims" },
		],
		colMalls: "지원 해외 쇼핑몰",
		mallLinks: [
			"Amazon US · JP · UK",
			"AliExpress · Temu",
			"Taobao · Tmall",
			"Mercari · Rakuten",
			"Farfetch · SSENSE",
			"iHerb · eBay · 글로벌 몰",
		],
		colSupport: "고객 이용 안내",
		supportLinks: [
			{ label: "진행 단계별 가이드", to: "/#interactive-tour" },
			{ label: "예상 환불금 계산기", to: "/#refund-calculator" },
			{ label: "전 세계 환불 경로", to: "/#global-network" },
			{ label: "10MB 사진 암호화 안내", to: "/settings" },
		],
		colAccount: "내 계정 관리",
		accountLinks: [
			{ label: "로그인 · 회원가입", to: "/auth" },
			{ label: "자동 작성 기능 설정", to: "/settings" },
			{ label: "내 기록 백업 내려받기", to: "/settings" },
			{ label: "계정 및 사진 영구 삭제", to: "/settings" },
		],
		colLanguage: "지원 언어",
		colSafety: "소비자 보호 원칙",
		safetyItems: ["본인 외 사진 열람 차단", "카드 취소 2단계 확인"],
		companyInfoLine1:
			"ReLo (릴로) 해외직구 소비자 환불 도우미  |  지원 통화: USD · EUR · JPY · CNY · KRW · GBP · CAD · AUD",
		companyInfoLine2:
			"고객의 주문 영수증과 불량 사진(최대 10MB)은 본인 계정에만 안전하게 분리 보관되며 설정에서 언제든 즉시 삭제할 수 있습니다.",
		privacyBold: "개인정보 처리방침",
		terms: "서비스 이용약관",
		dataSafety: "증빙 사진 보호 정책",
		consumerGuide: "해외결제 취소 안내",
		disputeNotice: "소비자 권리 보호 기준",
	},
	pages: {
		wizardTitle: "3분 간편 환불 신청",
		wizardPrev: "이전 단계",
		wizardNext: "다음 단계로",
		wizardSubmit: "환불 신청 등록하기",
		myClaimsTitle: "내 환불 내역",
		myClaimsSub:
			"신청한 금액부터 실제 카드 취소·입금 완료까지 한눈에 확인하세요.",
		myClaimsNewBtn: "새 환불 신청",
		sumClaimed: "총 신청 금액",
		sumRecovered: "실제 입금 확인",
		sumRemaining: "남은 받을 금액",
		authTitle: "내 직구 환불 내역 안전하게 보관하기",
		settingsTitle: "계정 및 개인정보 설정",
	},
} as const;
