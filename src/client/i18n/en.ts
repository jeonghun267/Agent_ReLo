/**
 * @module client/i18n/en
 * @layer Model (Localization Dictionary)
 * @purpose English (EN) consumer copy written in clear, everyday language.
 */

import type { TranslationDictionary } from "@/client/i18n/types";

export const enMessages: TranslationDictionary = {
	common: {
		skipToContent: "Skip to main content",
		loadingScreen: "Preparing your screen...",
		notFoundSpeech: "This page address has moved or does not exist.",
		backHome: "Back to Home",
	},
	nav: {
		about: "Overview",
		aboutMobile: "Home",
		apply: "Start Refund",
		applyMobile: "Apply",
		myRefunds: "My Refunds",
		myRefundsMobile: "Refunds",
		settings: "Settings",
		settingsMobile: "Settings",
		login: "Log in",
		applyCta: "Start Refund",
		userSuffix: "",
		verifyNoticePrefix: "To receive refund alerts, please check",
		verifyNoticeSuffix: "your inbox.",
		resendVerify: "Resend email",
		sending: "Sending...",
		languageLabel: "Language",
	},
	hero: {
		badge: "Cross-Border Shopping Return & Refund Care",
		titleLine1: "Damaged package from overseas?",
		titleHighlight: "Get refunded to your bank without foreign languages.",
		subtitle:
			"Auto-fill your order receipt, hide your home address on box photos, generate polite store messages, and verify actual card refunds—all in one place.",
		primaryCta: "Start Refund in 3 Minutes",
		secondaryWallet: "View My Refunds",
		secondaryGlobe: "Explore Global Routes",
		trust1: "Exact math across 8 currencies",
		trust2: "Private 10MB photo & receipt vault",
		trust3: "Verifies real card refund, not empty promises",
	},
	malls: {
		us: "US",
		global: "Global",
		cn: "China",
		jp: "Japan",
		usUk: "US · UK",
		euCa: "EU · CA",
		tagAmazon: "Instant English refund request",
		tagAli: "Photo-backed damage refund",
		tagTaobao: "Wrong or missing item help",
		tagMercari: "Polite Japanese & English notes",
		tagIherb: "Leaking or broken bottle refund",
		tagEbay: "Seller refund promise tracker",
		tagFarfetch: "Save on return shipping fees",
		tagTemu: "Full local currency refund",
	},
	globe: {
		eyebrow: "Global Refund Flight Map",
		titleLine1: "Money stuck across the ocean,",
		titleLine2: "flying straight back to Seoul.",
		description:
			"Whether you ordered from the US, Japan, China, or Europe, your refund request flies directly to the seller and tracks every dollar until your card is actually credited.",
		routeSuffix: "Live Refund Route",
		startThisMall: "Start Refund for This Store",
		seoulHubLabel: "Seoul · Back in My Account",
		dragHint: "Drag the 3D globe or tap a country button below",
		canvasAria:
			"Interactive 3D world map globe with airplanes flying refund routes from the US, Japan, China, and Europe into Seoul",
		corridors: {
			usSea: {
				country: "USA",
				status: "Card Refund Confirmed",
				issue: "Outer shipping box and item shell arrived cracked.",
			},
			jpTyo: {
				country: "Japan",
				status: "Wrong Item · Full Refund",
				issue: "Received a different color variant than ordered.",
			},
			cnSzx: {
				country: "China",
				status: "Refunded Without Return",
				issue: "Electronic item does not power on out of the box.",
			},
			euLon: {
				country: "Europe",
				status: "Store Refund Approved",
				issue: "Accessories missing and inner seal arrived torn.",
			},
			usLax: {
				country: "US West",
				status: "Approved After Photo Check",
				issue: "Bottle arrived cracked and leaked inside the parcel.",
			},
		},
	},
	phoneStory: {
		eyebrow: "3-Minute Guided Walkthrough",
		headline: "Every tricky step happens right inside your phone",
		scrollHint: "Scroll down to watch each 3D step pop out of the screen",
		scenes: [
			{
				step: "01",
				tab: "Drop Receipt",
				badge: "Auto-Read Receipt · Hide Home Address",
				titleLine1: "Long foreign order receipt?",
				titleLine2: "Just drop a single screenshot.",
				description:
					"No need to type long order numbers or item names by hand. Upload a screenshot or PDF to fill every field automatically while trimming out your home address and phone number.",
				screenHeader: "Smart Receipt Reader",
				screenStatus: "Auto-Filled",
				screenSubTitle: "Detected Order Details",
				popLeftTitle: "Order ID filled in 3 sec",
				popLeftSub: "#114-8920411 · $184.00",
				popRightTitle: "Home address trimmed out",
				popRightSub: "Keeps only the damaged spot",
			},
			{
				step: "02",
				tab: "Store Message",
				badge: "Tailored Foreign Support Message",
				titleLine1: "Write one line in your own words,",
				titleLine2: "get a ready-to-send store message.",
				description:
					"Stop guessing what to type into a translator. We craft a clear, polite message in English, Japanese, or Chinese with your exact order details and refund amount.",
				screenHeader: "Ready-to-Send Support Note",
				screenStatus: "Ready to Copy",
				screenSubTitle: "Your 1-Line Reason",
				popLeftTitle: "English · Japanese · Chinese",
				popLeftSub: "Aligned with store refund rules",
				popRightTitle: "Avoid unfair return shipping",
				popRightSub: "Highlights seller-fault terms",
			},
			{
				step: "03",
				tab: "Real Card Refund",
				badge: "No Empty Promises · 2-Step Money Check",
				titleLine1: "Never lose money waiting on",
				titleLine2: "“We already refunded you.”",
				description:
					"Stores sometimes promise a refund in chat while forgetting to cancel the card charge. We compare the promised amount side-by-side with the money that actually lands back on your card.",
				screenHeader: "Final Card Refund Check",
				screenStatus: "Paid in Full",
				screenSubTitle: "Remaining Balance $0.00",
				popLeftTitle: "Card Cancellation Landed",
				popLeftSub: "AMZ*REFUND +$184.00 verified",
				popRightTitle: "Promised vs Paid Matched",
				popRightSub: "Every cent accounted for",
			},
		],
	},
	whyRelo: {
		eyebrow: "Why Choose ReLo?",
		titleLine1: "Built for the moment shipping agents",
		titleLine2: "and plain translators stop helping.",
		description:
			"Once a package reaches your front door in Korea and turns out broken, most people get stuck. ReLo guides you all the way until the money returns.",
		colTopic: "Situation",
		colAgent: "Forwarding Warehouses",
		colTranslator: "Basic Translators",
		colRelo: "ReLo Refund Helper",
		rows: [
			{
				topic: "You open the box at home and find it broken",
				agent: "Support ends once shipped from warehouse",
				translator: "You must look up store rules yourself",
				relo: "Step-by-step care right after unboxing",
			},
			{
				topic: "Talking to overseas stores & high return shipping",
				agent: "Extra service fees + pricey return shipping",
				translator: "Literal translation misses refund terms",
				relo: "Store-ready message protecting return costs",
			},
			{
				topic: "Protecting home address & phone number on labels",
				agent: "Raw label photos risk exposing privacy",
				translator: "Must edit photos in a separate app",
				relo: "Crop only the defect right in your browser",
			},
			{
				topic: "Seller promises a refund but money never arrives",
				agent: "Does not track card settlement",
				translator: "Does not track card settlement",
				relo: "Checks both seller promise & real card credit",
			},
		],
	},
	flow: {
		eyebrow: "5 Simple Steps at a Glance",
		title: "From request to bank deposit, as easy as parcel tracking",
		subtitle: "Tap any step below to preview how ReLo helps along the way.",
		startBtn: "Start My Refund With These 5 Steps",
		steps: [
			{
				id: "scan",
				stepNo: "Step 1",
				title: "Read Receipt",
				subtitle: "Photo or PDF auto-fill",
				badge: "3-Sec Fill",
				guide:
					"Upload an order screenshot or PDF receipt and we automatically fill in the store name, order number, and price.",
				previewTitle: "Sample Auto-Filled Order Details",
				sample:
					"Store: Amazon US · Order #114-8920411 · Date: 2026-10-18 · Item: Wireless Headphones ($298.00)",
				points: [
					"Read tiny receipt text clearly on screen",
					"No manual typing of long order IDs",
				],
			},
			{
				id: "crop",
				stepNo: "Step 2",
				title: "Trim Defect Photo",
				subtitle: "Hide address & zoom in",
				badge: "Easy Crop",
				guide:
					"Trim away shipping labels with your home address and highlight only the cracked or scratched area.",
				previewTitle: "Private Photo Vault (Up to 10MB)",
				sample:
					"[Trimmed] cracked_corner_photo.png (1.4 MB · Encrypted & visible only to your account)",
				points: [
					"Drag a simple box around the damaged spot",
					"Strictly isolated to your signed-in account",
				],
			},
			{
				id: "draft",
				stepNo: "Step 3",
				title: "Write Store Message",
				subtitle: "Copy & send right away",
				badge: "Auto-Write",
				guide:
					"Describe the issue in plain words and get a polite, structured message ready for overseas customer support.",
				previewTitle: "Message Ready for Store Chat or Email",
				sample:
					"Subject: Refund Request for Damaged Item — Order #114-8920411\n\nDear Customer Support, The item arrived with exterior damage as shown in the attached photos. Could you please process a full refund of USD 298.00?",
				points: [
					"Uses only your verified order facts without guessing",
					"One-click copy for store live chat or email",
				],
			},
			{
				id: "reply",
				stepNo: "Step 4",
				title: "Summarize Store Reply",
				subtitle: "Clear 3-line summary",
				badge: "Easy Summary",
				guide:
					"Got a long foreign reply from the seller? Paste it in to see the exact offer and return deadline immediately.",
				previewTitle: "Seller Reply Summary Sample",
				sample:
					"[Result: Refund Promised] The store agreed to a full $298.00 refund with no return required. Check your card statement in 3–5 business days!",
				points: [
					"Separates a chat promise from actual money received",
					"Highlights return deadlines so you never miss out",
				],
			},
			{
				id: "settled",
				stepNo: "Step 5",
				title: "Verify Deposit",
				subtitle: "Card credit & bank check",
				badge: "Money Verified",
				guide:
					"Confirm that the exact refund amount has landed back on your card or bank account before closing.",
				previewTitle: "Final Refund Confirmation",
				sample:
					"Verified Deposit: $298.00 / Promised $298.00 (Remaining $0.00 · Card credit complete)",
				points: [
					"Automatically calculates any missing partial refund",
					"Marks complete only when real money arrives",
				],
			},
		],
	},
	simulator: {
		eyebrow: "Expected Refund Calculator",
		title: "How much was the overseas order with an issue?",
		subtitle:
			"Open the refund form right away with your selected store and amount.",
		mallLabel: "Where did you buy it?",
		issueLabel: "What went wrong?",
		priceLabel: "Order Amount Paid",
		previewBadge: "Live English Request Preview",
		barSolo: "Asking alone with a basic translator",
		barRelo: "Applying step-by-step with ReLo",
		expectedLabel: "Expected Refund",
		completenessLabel: "Readiness",
		extraTitle: "Extra refund value protected compared to doing it alone",
		extraSuffix: "better protected",
		applyWithPreset: "Start Refund With These Details",
		scenarios: {
			damaged: {
				label: "Arrived Broken",
				issue:
					"When I opened the parcel, both the box and product corner were cracked and unusable.",
			},
			wrong: {
				label: "Wrong / Missing Item",
				issue:
					"Received a different option than ordered and parts were missing from the package.",
			},
			defect: {
				label: "Does Not Work",
				issue:
					"Connected power right away, but the item does not turn on at all.",
			},
		},
	},
	closingCta: {
		titleLine1: "Before the store refund window closes,",
		titleLine2: "protect your money right now.",
		subtitle: "One order number and one photo take less than 3 minutes.",
		button: "Start Refund in 3 Minutes",
	},
	footer: {
		sloganLine1: "From overseas unboxing to card refund,",
		sloganLine2: "finally all in ReLo.",
		colService: "Service",
		serviceLinks: [
			{ label: "Overview Home", to: "/" },
			{ label: "3-Minute Refund Form", to: "/wizard" },
			{ label: "My Refund History", to: "/claims" },
			{ label: "Foreign Message Writer", to: "/wizard" },
			{ label: "Seller Reply Summary", to: "/claims" },
		],
		colMalls: "Supported Stores",
		mallLinks: [
			"Amazon US · JP · UK",
			"AliExpress · Temu",
			"Taobao · Tmall",
			"Mercari · Rakuten",
			"Farfetch · SSENSE",
			"iHerb · eBay · Global Stores",
		],
		colSupport: "Customer Guide",
		supportLinks: [
			{ label: "5-Step Refund Guide", to: "/#interactive-tour" },
			{ label: "Refund Calculator", to: "/#refund-calculator" },
			{ label: "Global Flight Routes", to: "/#global-network" },
			{ label: "10MB Photo Privacy", to: "/settings" },
		],
		colAccount: "My Account",
		accountLinks: [
			{ label: "Log in · Sign up", to: "/auth" },
			{ label: "Writing Assistant Settings", to: "/settings" },
			{ label: "Download My Backup", to: "/settings" },
			{ label: "Delete Account & Photos", to: "/settings" },
		],
		colLanguage: "Languages",
		colSafety: "Consumer Protection",
		safetyItems: ["Private account-only photos", "2-step card refund check"],
		companyInfoLine1:
			"ReLo Cross-Border Consumer Refund Care  |  Supported Currencies: USD · EUR · JPY · CNY · KRW · GBP · CAD · AUD",
		companyInfoLine2:
			"Uploaded receipts and defect photos (up to 10MB) are strictly isolated to your account and can be permanently deleted anytime in Settings.",
		privacyBold: "Privacy Policy",
		terms: "Terms of Use",
		dataSafety: "Photo Security Policy",
		consumerGuide: "Card Refund Guide",
		disputeNotice: "Consumer Protection Standards",
	},
	pages: {
		wizardTitle: "3-Minute Refund Request",
		wizardPrev: "Previous",
		wizardNext: "Next Step",
		wizardSubmit: "Submit Refund Request",
		myClaimsTitle: "My Refunds",
		myClaimsSub:
			"Track everything from requested amounts to verified card credits.",
		myClaimsNewBtn: "New Refund",
		sumClaimed: "Total Requested",
		sumRecovered: "Verified Deposit",
		sumRemaining: "Remaining Balance",
		authTitle: "Keep Your Refund Records Safe",
		settingsTitle: "Account & Privacy Settings",
	},
};
