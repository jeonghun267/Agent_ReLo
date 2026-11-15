/**
 * @module client/components/ui/Primitives
 * @layer View (Design System Primitives)
 * @purpose Provides accessible, Toss-inspired UI building blocks: Button, Badge, Card,
 *          MoneyDisplay (tabular split typography), TextField, PasswordField, and ToastProvider.
 */

import { cva, type VariantProps } from "class-variance-authority";
import { Eye, EyeOff } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import {
	type ButtonHTMLAttributes,
	createContext,
	type InputHTMLAttributes,
	type ReactNode,
	useCallback,
	useContext,
	useId,
	useMemo,
	useState,
} from "react";
import { splitMinorMoneyParts } from "@/client/lib/format";
import type { CurrencyCode } from "@/client/types/domain";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
	"inline-flex items-center justify-center gap-2 transition-all duration-150 select-none disabled:pointer-events-none cursor-pointer tracking-[-0.02em]",
	{
		variants: {
			variant: {
				primary:
					"bg-relo-brand text-white hover:bg-relo-brand-hover active:scale-[0.985] disabled:bg-relo-line-strong disabled:text-white",
				secondary:
					"bg-relo-sunken text-relo-body hover:bg-[#e5e8eb] active:scale-[0.985] disabled:opacity-55",
				soft: "bg-relo-brand-soft text-relo-brand hover:bg-[#d7e8ff] active:scale-[0.985] disabled:opacity-55",
				ai: "bg-relo-brand text-white hover:bg-relo-brand-hover active:scale-[0.985] disabled:opacity-55",
				ghost:
					"bg-transparent text-relo-body hover:bg-relo-sunken active:scale-[0.985] disabled:opacity-50",
				danger:
					"bg-relo-danger-soft text-relo-danger hover:bg-red-100 active:scale-[0.985] disabled:opacity-55",
			},
			size: {
				sm: "min-h-9 rounded-xl px-3.5 py-1.5 text-xs font-semibold",
				md: "min-h-11 rounded-2xl px-4.5 py-2.5 text-sm font-semibold",
				lg: "min-h-13.5 rounded-2xl px-6 py-3.5 text-[15px] font-bold",
			},
			fullWidth: {
				true: "w-full",
				false: "",
			},
		},
		defaultVariants: {
			variant: "primary",
			size: "md",
			fullWidth: false,
		},
	},
);

export interface ButtonProps
	extends ButtonHTMLAttributes<HTMLButtonElement>,
		VariantProps<typeof buttonVariants> {
	isLoading?: boolean;
}

export function Button({
	variant,
	size,
	fullWidth,
	isLoading = false,
	type = "button",
	disabled,
	className,
	children,
	...rest
}: ButtonProps) {
	return (
		<button
			type={type}
			disabled={disabled || isLoading}
			className={cn(buttonVariants({ variant, size, fullWidth }), className)}
			{...rest}
		>
			{isLoading ? (
				<span
					aria-hidden="true"
					className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
				/>
			) : null}
			{children}
		</button>
	);
}

// Labels are plain text, not colored pills: the product keeps to one blue accent and gray
// text, the same as the app. A tone only picks the text color:
//   brand / ai / emerald → blue, for a label that names a feature or an action
//   danger               → red, for something that needs the person's attention
//   neutral / sunny      → dark gray, for a state or a note ("sunny" used to be a yellow pill)
const badgeVariants = cva(
	"inline-flex items-center gap-1.5 text-xs font-semibold tracking-[-0.01em]",
	{
		variants: {
			tone: {
				brand: "text-relo-brand",
				ai: "text-relo-brand",
				sunny: "text-relo-body",
				emerald: "text-relo-brand",
				danger: "text-relo-danger",
				neutral: "text-relo-body",
			},
		},
		defaultVariants: {
			tone: "brand",
		},
	},
);

export function Badge({
	tone,
	className,
	children,
}: VariantProps<typeof badgeVariants> & {
	className?: string;
	children: ReactNode;
}) {
	return (
		<span className={cn(badgeVariants({ tone }), className)}>{children}</span>
	);
}

interface CardProps {
	children: ReactNode;
	className?: string;
}

export function Card({ children, className }: CardProps) {
	return (
		<section
			className={cn(
				"rounded-[28px] border border-relo-line/80 bg-relo-surface p-6 shadow-[0_8px_30px_rgba(15,23,42,0.035)] sm:p-7",
				className,
			)}
		>
			{children}
		</section>
	);
}

/**
 * Toss-inspired split money typography: subtle currency symbol, crisp bold integer, quiet decimal.
 * The symbol and the decimals are smaller than the integer but never below 12px.
 */
export function MoneyDisplay({
	minor,
	currency,
	className,
}: {
	minor: number;
	currency: CurrencyCode;
	className?: string;
}) {
	const { symbol, integerPart, fractionPart } = splitMinorMoneyParts(
		minor,
		currency,
	);
	return (
		<span
			className={cn(
				"inline-flex items-baseline tabular-nums tracking-[-0.035em]",
				className,
			)}
		>
			<span className="mr-0.5 text-[max(0.72em,12px)] font-medium">
				{symbol}
			</span>
			<span className="font-bold">{integerPart}</span>
			{fractionPart ? (
				<span className="text-[max(0.76em,12px)] font-medium">
					{fractionPart}
				</span>
			) : null}
		</span>
	);
}

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
	label: string;
	hint?: string;
	error?: string;
}

/** The look of an input box, shared by the plain field and the password field. */
function fieldInputClass(hasError: boolean): string {
	return cn(
		"min-h-13 w-full rounded-2xl border px-4 py-3 text-[15px] font-medium text-relo-ink outline-none transition-all placeholder:font-normal placeholder:text-relo-subtle",
		hasError
			? "border-relo-danger bg-relo-danger-soft/30"
			: "border-transparent bg-relo-sunken hover:bg-[#e8ebef] focus:border-relo-brand focus:bg-white focus:ring-4 focus:ring-relo-brand/10",
	);
}

/** The line under an input: what is wrong with it, or else a hint on what to enter. */
function FieldMessage({
	id,
	hint,
	error,
}: {
	id: string;
	hint?: string;
	error?: string;
}) {
	if (error) {
		return (
			<p
				id={`${id}-error`}
				role="alert"
				className="text-xs font-medium text-relo-danger"
			>
				{error}
			</p>
		);
	}
	if (hint) {
		return (
			<p id={`${id}-hint`} className="text-xs text-relo-muted">
				{hint}
			</p>
		);
	}
	return null;
}

export function TextField({
	label,
	hint,
	error,
	className,
	id: providedId,
	...inputProps
}: TextFieldProps) {
	const autoId = useId();
	const id = providedId ?? autoId;

	return (
		<div className="space-y-2">
			<label
				htmlFor={id}
				className="block text-[13px] font-semibold text-relo-body"
			>
				{label}
			</label>
			<input
				id={id}
				aria-invalid={Boolean(error)}
				aria-describedby={
					error ? `${id}-error` : hint ? `${id}-hint` : undefined
				}
				className={cn(fieldInputClass(Boolean(error)), className)}
				{...inputProps}
			/>
			<FieldMessage id={id} hint={hint} error={error} />
		</div>
	);
}

interface PasswordFieldProps
	extends Omit<InputHTMLAttributes<HTMLInputElement>, "type"> {
	label: string;
	hint?: string;
	error?: string;
	/** What the eye button is called while the password is hidden / shown. */
	showLabel: string;
	hideLabel: string;
}

/**
 * A password input with an eye button, so a person can check what they typed
 * instead of typing it twice. Hidden by default.
 */
export function PasswordField({
	label,
	hint,
	error,
	showLabel,
	hideLabel,
	className,
	id: providedId,
	...inputProps
}: PasswordFieldProps) {
	const autoId = useId();
	const id = providedId ?? autoId;
	const [shown, setShown] = useState(false);

	return (
		<div className="space-y-2">
			<label
				htmlFor={id}
				className="block text-[13px] font-semibold text-relo-body"
			>
				{label}
			</label>
			<div className="relative">
				<input
					id={id}
					type={shown ? "text" : "password"}
					aria-invalid={Boolean(error)}
					aria-describedby={
						error ? `${id}-error` : hint ? `${id}-hint` : undefined
					}
					className={cn(fieldInputClass(Boolean(error)), "pr-14", className)}
					{...inputProps}
				/>
				<button
					type="button"
					aria-label={shown ? hideLabel : showLabel}
					aria-pressed={shown}
					onClick={() => setShown((v) => !v)}
					className="absolute top-1/2 right-1 flex h-11 w-11 -translate-y-1/2 cursor-pointer items-center justify-center rounded-xl text-relo-muted transition-colors hover:text-relo-ink"
				>
					{shown ? (
						<EyeOff className="h-5 w-5" aria-hidden="true" />
					) : (
						<Eye className="h-5 w-5" aria-hidden="true" />
					)}
				</button>
			</div>
			<FieldMessage id={id} hint={hint} error={error} />
		</div>
	);
}

interface ToastMessage {
	id: string;
	text: string;
	tone: "default" | "error";
}

interface ToastContextValue {
	showToast: (text: string, tone?: "default" | "error") => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
	const [toast, setToast] = useState<ToastMessage | null>(null);

	const showToast = useCallback(
		(text: string, tone: "default" | "error" = "default") => {
			const id = crypto.randomUUID();
			setToast({ id, text, tone });
			window.setTimeout(() => {
				setToast((prev) => (prev?.id === id ? null : prev));
			}, 3600);
		},
		[],
	);

	const value = useMemo(() => ({ showToast }), [showToast]);

	return (
		<ToastContext.Provider value={value}>
			{children}
			<div
				aria-live="polite"
				className="pointer-events-none fixed inset-x-0 bottom-22 z-50 flex justify-center px-4 sm:bottom-6"
			>
				<AnimatePresence mode="wait">
					{toast ? (
						<motion.div
							key={toast.id}
							initial={{ opacity: 0, y: 14, scale: 0.96 }}
							animate={{ opacity: 1, y: 0, scale: 1 }}
							exit={{ opacity: 0, y: 8, scale: 0.96 }}
							transition={{ duration: 0.2 }}
							className={cn(
								"pointer-events-auto max-w-md rounded-full px-5 py-3 text-sm font-semibold text-white shadow-float",
								toast.tone === "error" ? "bg-relo-danger" : "bg-relo-ink/95",
							)}
						>
							{toast.text}
						</motion.div>
					) : null}
				</AnimatePresence>
			</div>
		</ToastContext.Provider>
	);
}

export function useToast(): ToastContextValue {
	const ctx = useContext(ToastContext);
	if (!ctx) {
		throw new Error("useToast must be used within ToastProvider");
	}
	return ctx;
}
