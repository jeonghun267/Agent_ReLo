/**
 * @module scripts/audit-client-quality
 * @purpose Automated frontend code quality, MVVM architecture header, modular line-budget,
 *          color-harmony, and plain-consumer-language governance audit for `src/client/`.
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import { extname, join, relative } from "node:path";

const ROOT = process.cwd();
const CLIENT_DIR = join(ROOT, "src", "client");

const FORBIDDEN_PATTERNS = [
	{ regex: /도리/u, reason: "Legacy mascot name '도리' must not appear in UI" },
	{
		regex: /\bDori\b/,
		reason: "Legacy identifier 'Dori' must not appear in client code",
	},
	{
		regex: /배대지/u,
		reason:
			"Use everyday consumer phrase ('해외 배송 대행업체' / '반품 주소') instead of '배대지'",
	},
	{
		regex: /인보이스/u,
		reason:
			"Use everyday consumer phrase ('영수증' / '주문 내역') instead of '인보이스'",
	},
	{
		regex: /유령\s*환불/u,
		reason:
			"Use everyday consumer phrase ('말뿐인 환불 약속') instead of '유령 환불'",
	},
	{
		regex: /해시\s*체인/u,
		reason: "Avoid cryptographic jargon ('해시 체인') in B2C UI",
	},
	{
		regex: /회수\s*원장/u,
		reason:
			"Use everyday consumer phrase ('환불 통장' / '입금 기록') instead of '회수 원장'",
	},
	{
		regex: /Cropper\.js|PDF\.js|SHA-256/,
		reason: "Library/hash internals must not be exposed in consumer copy",
	},
	{
		regex: /#047857|#4338ca/i,
		reason:
			"Keep unified Toss-Blue (#1b64da / #3182f6) + Slate palette without pine-green/purple clashes",
	},
];

const MAX_TSX_LINES = 460;

function collectFiles(dir, acc = []) {
	for (const entry of readdirSync(dir)) {
		const full = join(dir, entry);
		const st = statSync(full);
		if (st.isDirectory()) {
			collectFiles(full, acc);
		} else {
			acc.push(full);
		}
	}
	return acc;
}

function stripComments(source) {
	return source.replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
}

const files = collectFiles(CLIENT_DIR);
const issues = [];

for (const filePath of files) {
	const rel = relative(ROOT, filePath).replaceAll("\\", "/");
	const ext = extname(filePath);
	const raw = readFileSync(filePath, "utf8");
	const lines = raw.split(/\r?\n/);

	if ((ext === ".ts" || ext === ".tsx") && !rel.endsWith("vite-env.d.ts")) {
		const headerSlice = lines.slice(0, 12).join("\n");
		if (
			!headerSlice.includes("@module") ||
			!headerSlice.includes("@layer") ||
			!headerSlice.includes("@purpose")
		) {
			issues.push(
				`[HEADER] ${rel}: Missing @module / @layer / @purpose architecture JSDoc header in top 12 lines.`,
			);
		}
	}

	if (ext === ".tsx" && lines.length > MAX_TSX_LINES) {
		issues.push(
			`[MODULARITY] ${rel}: ${lines.length} lines exceeds ${MAX_TSX_LINES}-line component budget. Split into focused sub-modules.`,
		);
	}

	if (ext === ".ts" || ext === ".tsx" || ext === ".css") {
		const codeOnly = stripComments(raw);
		for (const rule of FORBIDDEN_PATTERNS) {
			if (rule.regex.test(codeOnly)) {
				issues.push(`[POLICY] ${rel}: ${rule.reason}`);
			}
		}
	}
}

const requiredLocales = ["ko.ts", "en.ts", "zh.ts", "ja.ts"];
for (const localeFile of requiredLocales) {
	const full = join(CLIENT_DIR, "i18n", localeFile);
	try {
		const st = statSync(full);
		if (!st.isFile()) {
			issues.push(`[I18N] Missing locale file src/client/i18n/${localeFile}`);
		}
	} catch {
		issues.push(`[I18N] Missing locale file src/client/i18n/${localeFile}`);
	}
}

if (issues.length > 0) {
	console.error(
		`\nClient Quality Audit failed with ${issues.length} issue(s):`,
	);
	for (const issue of issues) {
		console.error(`  - ${issue}`);
	}
	process.exit(1);
}

console.log(
	`Client Quality Audit passed: ${files.length} files verified (MVVM headers, <=${MAX_TSX_LINES}L TSX modularity, 4-locale parity, Toss color harmony & plain consumer language).`,
);
