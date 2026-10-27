/**
 * @module client/lib/router
 * @layer ViewModel (Client History Router)
 * @purpose Lightweight History API router supporting clean paths, backend email verification
 *          hash normalization, and smooth anchor-section scrolling (e.g. /#global-network).
 */

import {
	createContext,
	type MouseEvent,
	type ReactNode,
	useCallback,
	useContext,
	useEffect,
	useMemo,
	useState,
} from "react";

export interface RouteState {
	pathname: string;
	search: string;
	hash: string;
}

interface RouterContextValue extends RouteState {
	navigate: (to: string, options?: { replace?: boolean }) => void;
}

const RouterContext = createContext<RouterContextValue | null>(null);

function readBrowserLocation(): RouteState {
	const rawHash = window.location.hash;
	if (rawHash.startsWith("#/verify/") || rawHash.startsWith("#/reset/")) {
		const [, action, token] = rawHash.slice(1).split("/");
		if (action && token) {
			const normalizedUrl = `/auth?mode=${encodeURIComponent(action)}&token=${encodeURIComponent(token)}`;
			window.history.replaceState(null, "", normalizedUrl);
		}
	}

	return {
		pathname: window.location.pathname || "/",
		search: window.location.search || "",
		hash: window.location.hash || "",
	};
}

function scrollToHashOrTop(hash: string) {
	if (hash && hash.length > 1 && !hash.startsWith("#/")) {
		const targetId = decodeURIComponent(hash.slice(1));
		const scrollTarget = () => {
			const el = document.getElementById(targetId);
			if (el) {
				el.scrollIntoView({ behavior: "smooth", block: "start" });
				return true;
			}
			return false;
		};
		if (!scrollTarget()) {
			window.setTimeout(scrollTarget, 120);
		}
		return;
	}
	window.scrollTo({ top: 0, behavior: "smooth" });
}

export function RouterProvider({ children }: { children: ReactNode }) {
	const [route, setRoute] = useState<RouteState>(() => readBrowserLocation());

	useEffect(() => {
		const syncLocation = () => {
			setRoute(readBrowserLocation());
		};
		window.addEventListener("popstate", syncLocation);
		window.addEventListener("hashchange", syncLocation);
		return () => {
			window.removeEventListener("popstate", syncLocation);
			window.removeEventListener("hashchange", syncLocation);
		};
	}, []);

	const navigate = useCallback(
		(to: string, options?: { replace?: boolean }) => {
			const url = new URL(to, window.location.origin);
			const nextPath = `${url.pathname}${url.search}${url.hash}`;
			const currentPath = `${window.location.pathname}${window.location.search}${window.location.hash}`;

			if (nextPath !== currentPath) {
				if (options?.replace) {
					window.history.replaceState(null, "", nextPath);
				} else {
					window.history.pushState(null, "", nextPath);
				}
			}

			setRoute({
				pathname: url.pathname,
				search: url.search,
				hash: url.hash,
			});
			scrollToHashOrTop(url.hash);
		},
		[],
	);

	const value = useMemo(
		() => ({
			...route,
			navigate,
		}),
		[route, navigate],
	);

	return (
		<RouterContext.Provider value={value}>{children}</RouterContext.Provider>
	);
}

export function useRouter(): RouterContextValue {
	const ctx = useContext(RouterContext);
	if (!ctx) {
		throw new Error("useRouter must be used inside RouterProvider");
	}
	return ctx;
}

interface AppLinkProps {
	to: string;
	className?: string;
	children: ReactNode;
	replace?: boolean;
	ariaLabel?: string;
	onClick?: () => void;
}

export function AppLink({
	to,
	className,
	children,
	replace,
	ariaLabel,
	onClick,
}: AppLinkProps) {
	const { navigate } = useRouter();

	const handleClick = (event: MouseEvent<HTMLAnchorElement>) => {
		if (
			event.defaultPrevented ||
			event.button !== 0 ||
			event.metaKey ||
			event.altKey ||
			event.ctrlKey ||
			event.shiftKey
		) {
			return;
		}
		event.preventDefault();
		onClick?.();
		navigate(to, { replace });
	};

	return (
		<a
			href={to}
			onClick={handleClick}
			className={className}
			aria-label={ariaLabel}
		>
			{children}
		</a>
	);
}
