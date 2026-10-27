/**
 * @module client/App
 * @layer ViewModel & Root Composition
 * @purpose Composes QueryClientProvider, I18nProvider, ToastProvider, RouterProvider,
 *          and route-based lazy code splitting for the ReLo B2C SPA.
 */

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AnimatePresence, motion } from "motion/react";
import { lazy, Suspense } from "react";
import { AppShell } from "@/client/components/AppShell";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Button, Card, ToastProvider } from "@/client/components/ui/Primitives";
import { LandingPage } from "@/client/features/landing/LandingPage";
import { I18nProvider, useI18n } from "@/client/i18n";
import { RouterProvider, useRouter } from "@/client/lib/router";

const WizardPage = lazy(() =>
	import("@/client/features/claim-wizard/WizardPage").then((m) => ({
		default: m.WizardPage,
	})),
);
const MyClaimsPage = lazy(() =>
	import("@/client/features/my-claims/MyClaimsPage").then((m) => ({
		default: m.MyClaimsPage,
	})),
);
const ClaimDetailPage = lazy(() =>
	import("@/client/features/claim-detail/ClaimDetailPage").then((m) => ({
		default: m.ClaimDetailPage,
	})),
);
const SettingsPage = lazy(() =>
	import("@/client/features/settings/SettingsPage").then((m) => ({
		default: m.SettingsPage,
	})),
);
const AuthPage = lazy(() =>
	import("@/client/features/auth/AuthPage").then((m) => ({
		default: m.AuthPage,
	})),
);

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			refetchOnWindowFocus: false,
		},
	},
});

function RouteViewport() {
	const { pathname, navigate } = useRouter();
	const { t } = useI18n();

	const renderPage = () => {
		if (pathname === "/") {
			return <LandingPage />;
		}
		if (pathname === "/wizard" || pathname.startsWith("/wizard/")) {
			return <WizardPage />;
		}
		if (pathname === "/claims") {
			return <MyClaimsPage />;
		}
		if (pathname.startsWith("/claims/")) {
			const claimId = decodeURIComponent(pathname.slice("/claims/".length));
			if (claimId) {
				return <ClaimDetailPage claimId={claimId} />;
			}
			return <MyClaimsPage />;
		}
		if (pathname === "/settings") {
			return <SettingsPage />;
		}
		if (pathname === "/auth") {
			return <AuthPage />;
		}

		return (
			<div className="mx-auto max-w-md px-4 py-16">
				<Card className="space-y-5 text-center">
					<ReloOrbEmblem
						variant="still"
						size="md"
						speech={t.common.notFoundSpeech}
					/>
					<Button size="lg" fullWidth onClick={() => navigate("/")}>
						{t.common.backHome}
					</Button>
				</Card>
			</div>
		);
	};

	return (
		<AnimatePresence mode="wait">
			<motion.div
				key={pathname}
				initial={{ opacity: 0, y: 10 }}
				animate={{ opacity: 1, y: 0 }}
				exit={{ opacity: 0, y: -6 }}
				transition={{ duration: 0.22, ease: [0.22, 0.61, 0.36, 1] }}
			>
				<Suspense
					fallback={
						<div className="mx-auto max-w-xl px-4 py-16 text-center text-sm font-semibold text-relo-muted">
							{t.common.loadingScreen}
						</div>
					}
				>
					{renderPage()}
				</Suspense>
			</motion.div>
		</AnimatePresence>
	);
}

export function App() {
	return (
		<QueryClientProvider client={queryClient}>
			<I18nProvider>
				<ToastProvider>
					<RouterProvider>
						<AppShell>
							<RouteViewport />
						</AppShell>
					</RouterProvider>
				</ToastProvider>
			</I18nProvider>
		</QueryClientProvider>
	);
}
