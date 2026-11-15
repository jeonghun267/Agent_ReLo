/**
 * @module client/features/settings/PasskeyCard
 * @layer View (Settings — Passkeys)
 * @purpose Lists the passkeys of the signed-in user and lets them register this device or
 *          remove one. Rendered only when the server has passkeys switched on.
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { KeyRound, Trash2 } from "lucide-react";
import { Button, Card, useToast } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { accountApi } from "@/client/lib/api-client";
import { errorText } from "@/client/lib/claim-words";
import { fill, formatLocalDate } from "@/client/lib/format";
import { createPasskey, passkeysSupported } from "@/client/lib/passkey";

const PASSKEYS_KEY = ["account", "passkeys"] as const;

export function PasskeyCard() {
	const { t, locale, localeOption } = useI18n();
	const p = t.signin.passkey;
	const { showToast } = useToast();
	const queryClient = useQueryClient();
	const supported = passkeysSupported();

	const { data } = useQuery({
		queryKey: PASSKEYS_KEY,
		queryFn: accountApi.passkeys,
	});
	const passkeys = data?.passkeys ?? [];

	const addMutation = useMutation({
		mutationFn: async () => {
			const options = await accountApi.passkeyRegisterOptions();
			const answer = await createPasskey(options);
			return accountApi.passkeyRegister({ name: p.defaultName, ...answer });
		},
		onSuccess: (result) => {
			queryClient.setQueryData(PASSKEYS_KEY, result);
			showToast(p.toastAdded);
		},
		onError: (error) => {
			// Closing the device's prompt is a choice, not a failure worth a message.
			if (error instanceof DOMException && error.name === "NotAllowedError") {
				return;
			}
			showToast(errorText(error, p.toastAddFail, locale), "error");
		},
	});

	const removeMutation = useMutation({
		mutationFn: (id: string) => accountApi.passkeyRemove(id),
		onSuccess: (result) => {
			queryClient.setQueryData(PASSKEYS_KEY, result);
			showToast(p.toastRemoved);
		},
		onError: (error) => {
			showToast(errorText(error, p.toastRemoveFail, locale), "error");
		},
	});

	return (
		<Card className="space-y-3">
			<h2 className="text-base font-bold text-relo-ink">{p.title}</h2>
			<p className="text-xs leading-relaxed text-relo-muted">{p.body}</p>

			{passkeys.length > 0 ? (
				<ul className="space-y-2">
					{passkeys.map((passkey) => (
						<li
							key={passkey.id}
							className="flex items-center justify-between gap-3 rounded-2xl bg-relo-sunken px-4 py-3"
						>
							<div className="min-w-0">
								<p className="truncate text-sm font-semibold text-relo-ink">
									{passkey.name}
								</p>
								<p className="text-xs text-relo-muted">
									{fill(p.added, {
										date: formatLocalDate(
											passkey.createdAt,
											localeOption.bcp47,
										),
									})}{" "}
									·{" "}
									{passkey.lastUsedAt
										? fill(p.lastUsed, {
												date: formatLocalDate(
													passkey.lastUsedAt,
													localeOption.bcp47,
												),
											})
										: p.neverUsed}
								</p>
							</div>
							<Button
								variant="ghost"
								size="sm"
								aria-label={fill(p.removeAria, { name: passkey.name })}
								isLoading={
									removeMutation.isPending &&
									removeMutation.variables === passkey.id
								}
								onClick={() => removeMutation.mutate(passkey.id)}
								className="min-h-11 shrink-0"
							>
								<Trash2 className="h-4 w-4" aria-hidden="true" />
								<span>{p.remove}</span>
							</Button>
						</li>
					))}
				</ul>
			) : (
				<p className="text-xs text-relo-muted">{p.empty}</p>
			)}

			{supported ? (
				<Button
					variant="secondary"
					fullWidth
					isLoading={addMutation.isPending}
					onClick={() => addMutation.mutate()}
				>
					<KeyRound className="h-4 w-4" aria-hidden="true" />
					<span>{p.add}</span>
				</Button>
			) : (
				<p className="text-xs font-medium text-relo-body">{p.unsupported}</p>
			)}
		</Card>
	);
}
