/**
 * @module client/components/AppShell
 * @layer View (Application Chrome & Responsive Navigation)
 * @purpose Renders the Toss-style sticky navigation header, header 4-language switcher,
 *          unverified-email banner, main content viewport, Toss multi-column closing footer,
 *          and mobile bottom tab bar.
 */

import {
	CheckCircle2,
	FilePlus2,
	Home,
	LogIn,
	MailCheck,
	ReceiptText,
	Settings,
} from "lucide-react";
import { motion } from "motion/react";
import type { ReactNode } from "react";
import { TossClosingFooter } from "@/client/components/TossClosingFooter";
import { Button, useToast } from "@/client/components/ui/Primitives";
import {
	useAppConfig,
	useResendVerificationMutation,
	useSession,
} from "@/client/hooks/useSession";
import { LanguageSwitcher, useI18n } from "@/client/i18n";
import { AppLink, useRouter } from "@/client/lib/router";
import { cn } from "@/lib/utils";

interface NavItem {
	to: string;
	label: string;
	mobileLabel: string;
	icon: typeof Home;
	match: (pathname: string) => boolean;
}

function ReloBrandMark() {
	return (
		<svg
			xmlns="http://www.w3.org/2000/svg"
			viewBox="0 0 36 36"
			aria-hidden="true"
			className="h-8 w-8 shrink-0 rounded-[10px] shadow-2xs"
		>
			<defs>
				<linearGradient id="reloNavGrad" x1="0" y1="0" x2="1" y2="1">
					<stop offset="0%" stopColor="#3182f6" />
					<stop offset="100%" stopColor="#1b64da" />
				</linearGradient>
			</defs>
			<rect width="36" height="36" rx="10" fill="url(#reloNavGrad)" />
			<circle
				cx="18"
				cy="18"
				r="9.5"
				fill="none"
				stroke="rgba(255,255,255,0.32)"
				strokeWidth="1.5"
			/>
			<path
				d="M9 21c4.5-8 12.5-9.5 18-4.5"
				fill="none"
				stroke="#ffffff"
				strokeWidth="2.4"
				strokeLinecap="round"
			/>
			<g transform="translate(26.5, 16.5) rotate(28)">
				<path d="M 3.2 0 L -2.6 -2.2 L -1.2 0 L -2.6 2.2 Z" fill="#ffffff" />
			</g>
		</svg>
	);
}

export function AppShell({ children }: { children: ReactNode }) {
	const { pathname, navigate } = useRouter();
	const { t } = useI18n();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const resendMutation = useResendVerificationMutation();
	const { showToast } = useToast();

	const navItems: NavItem[] = [
		{
			to: "/",
			label: t.nav.about,
			mobileLabel: t.nav.aboutMobile,
			icon: Home,
			match: (p) => p === "/",
		},
		{
			to: "/wizard",
			label: t.nav.apply,
			mobileLabel: t.nav.applyMobile,
			icon: FilePlus2,
			match: (p) => p.startsWith("/wizard"),
		},
		{
			to: "/claims",
			label: t.nav.myRefunds,
			mobileLabel: t.nav.myRefundsMobile,
			icon: ReceiptText,
			match: (p) => p.startsWith("/claims"),
		},
		{
			to: "/settings",
			label: t.nav.settings,
			mobileLabel: t.nav.settingsMobile,
			icon: Settings,
			match: (p) => p.startsWith("/settings"),
		},
	];

	const user = session?.user ?? null;
	const showVerifyBanner = Boolean(
		user && !user.emailVerifiedAt && config?.mail.enabled,
	);

	const handleResendVerification = async () => {
		try {
			const res = await resendMutation.mutateAsync();
			showToast(
				res.sent
					? "인증 링크를 이메일로 다시 보내드렸어요."
					: "이미 이메일 인증이 완료된 계정이에요.",
			);
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "인증 메일 발송에 실패했어요.",
				"error",
			);
		}
	};

	return (
		<div className="flex min-h-dvh flex-col bg-relo-canvas">
			<a
				href="#main-content"
				className="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-50 focus:rounded-xl focus:bg-relo-brand focus:px-4 focus:py-2 focus:text-sm focus:font-bold focus:text-white"
			>
				{t.common.skipToContent}
			</a>

			{showVerifyBanner ? (
				<div className="border-b border-relo-brand-line bg-relo-brand-soft px-4 py-2 text-xs text-relo-brand">
					<div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-2">
						<span className="inline-flex items-center gap-1.5 font-medium">
							<MailCheck className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
							<span>
								{t.nav.verifyNoticePrefix} <strong>{user?.email}</strong>{" "}
								{t.nav.verifyNoticeSuffix}
							</span>
						</span>
						<button
							type="button"
							disabled={resendMutation.isPending}
							onClick={handleResendVerification}
							className="cursor-pointer rounded-full bg-white px-3 py-1 text-xs font-semibold text-relo-brand hover:bg-white/90 disabled:opacity-60"
						>
							{resendMutation.isPending ? t.nav.sending : t.nav.resendVerify}
						</button>
					</div>
				</div>
			) : null}

			{/* Toss-Style Minimalist Sticky Header */}
			<header className="sticky top-0 z-30 border-b border-relo-line/70 bg-white/88 backdrop-blur-xl">
				<div className="mx-auto flex h-15 max-w-6xl items-center justify-between gap-3 px-4 sm:px-6">
					<AppLink
						to="/"
						className="inline-flex items-center gap-2.5 text-[19px] font-bold tracking-[-0.04em] text-relo-ink"
					>
						<ReloBrandMark />
						<span>ReLo</span>
					</AppLink>

					{/* Desktop Navigation */}
					<nav
						aria-label={t.nav.about}
						className="hidden items-center gap-1 md:flex"
					>
						{navItems.map((item) => {
							const active = item.match(pathname);
							return (
								<AppLink
									key={item.to}
									to={item.to}
									className={cn(
										"relative rounded-xl px-4 py-2 text-[15px] font-medium transition-colors",
										active
											? "font-semibold text-relo-ink"
											: "text-relo-muted hover:bg-relo-sunken hover:text-relo-ink",
									)}
								>
									{item.label}
								</AppLink>
							);
						})}
					</nav>

					{/* Header Right Actions: 4-Language Switcher + Auth + Primary CTA */}
					<div className="flex items-center gap-2">
						<LanguageSwitcher variant="header" />

						{user ? (
							<AppLink
								to="/settings"
								className="inline-flex min-h-9 items-center gap-1.5 rounded-full bg-relo-sunken px-3 py-1.5 text-xs font-semibold text-relo-ink hover:bg-[#e5e8eb] sm:px-3.5 sm:text-sm"
							>
								<CheckCircle2
									className="h-3.5 w-3.5 text-relo-brand"
									aria-hidden="true"
								/>
								<span className="max-w-24 truncate sm:max-w-28">
									{user.name}
									{t.nav.userSuffix}
								</span>
							</AppLink>
						) : (
							<Button
								variant="ghost"
								size="sm"
								onClick={() => navigate("/auth")}
								className="rounded-full px-3 text-xs sm:px-3.5 sm:text-sm"
							>
								<LogIn className="h-4 w-4" aria-hidden="true" />
								<span>{t.nav.login}</span>
							</Button>
						)}

						<Button
							variant="primary"
							size="sm"
							onClick={() => navigate("/wizard")}
							className="hidden rounded-full px-4 text-sm lg:inline-flex"
						>
							<span>{t.nav.applyCta}</span>
						</Button>
					</div>
				</div>
			</header>

			{/* Main Content Area */}
			<main id="main-content" className="flex-1">
				{children}
			</main>

			{/* Toss-Style Atmospheric Multi-Column Closing Footer */}
			<TossClosingFooter />

			{/* Mobile Bottom Navigation */}
			<nav
				aria-label="모바일 하단 메뉴"
				className="pb-safe fixed inset-x-0 bottom-0 z-40 border-t border-relo-line bg-white/95 backdrop-blur-xl md:hidden"
			>
				<div className="mx-auto grid max-w-md grid-cols-4 px-2 pt-1.5">
					{navItems.map((item) => {
						const Icon = item.icon;
						const active = item.match(pathname);
						return (
							<AppLink
								key={item.to}
								to={item.to}
								className={cn(
									"relative flex min-h-13 flex-col items-center justify-center gap-1 rounded-2xl py-1 text-[11px] font-semibold transition-colors",
									active ? "text-relo-ink" : "text-relo-muted",
								)}
							>
								{active ? (
									<motion.span
										layoutId="mobile-nav-indicator"
										className="absolute top-0 h-0.5 w-7 rounded-full bg-relo-ink"
									/>
								) : null}
								<Icon
									className={cn(
										"h-5 w-5",
										active ? "text-relo-brand" : "text-relo-muted",
									)}
									aria-hidden="true"
								/>
								<span>{item.mobileLabel}</span>
							</AppLink>
						);
					})}
				</div>
			</nav>
		</div>
	);
}
