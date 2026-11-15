/**
 * @module client/lib/passkey
 * @layer Model / Utility (Passkey — WebAuthn Browser Calls)
 * @purpose Asks the browser to make a passkey or to sign in with one, turning the server's
 *          text values into the bytes the browser needs and its answer back into text.
 *          The private key never leaves the person's device; only the answer is sent.
 */

export interface PasskeySummary {
	id: string;
	name: string;
	createdAt: string;
	lastUsedAt: string | null;
}

export interface PasskeyRegistrationOptions {
	challenge: string;
	rp: { id: string; name: string };
	user: { id: string; name: string; displayName: string };
	pubKeyCredParams: Array<{ type: "public-key"; alg: number }>;
	timeout: number;
	attestation: "none";
	authenticatorSelection: {
		residentKey: "required";
		userVerification: "required";
	};
	excludeCredentials: Array<{ type: "public-key"; id: string }>;
}

export interface PasskeyLoginOptions {
	challenge: string;
	rpId: string;
	timeout: number;
	userVerification: "required";
}

export interface PasskeyRegistrationAnswer {
	response: { clientDataJSON: string; attestationObject: string };
}

export interface PasskeyLoginAnswer {
	id: string;
	response: {
		clientDataJSON: string;
		authenticatorData: string;
		signature: string;
	};
}

function toBuffer(base64Url: string): ArrayBuffer {
	const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
	const binary = atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "="));
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
	return bytes.buffer;
}

function toBase64Url(buffer: ArrayBuffer): string {
	let binary = "";
	for (const byte of new Uint8Array(buffer))
		binary += String.fromCharCode(byte);
	return btoa(binary)
		.replace(/\+/g, "-")
		.replace(/\//g, "_")
		.replace(/=+$/, "");
}

/** True when this browser can make and use passkeys at all. */
export function passkeysSupported(): boolean {
	return (
		typeof window !== "undefined" &&
		typeof window.PublicKeyCredential === "function" &&
		Boolean(navigator.credentials)
	);
}

/** Makes a new passkey on this device. Rejects if the person closes the prompt. */
export async function createPasskey(
	options: PasskeyRegistrationOptions,
): Promise<PasskeyRegistrationAnswer> {
	const credential = (await navigator.credentials.create({
		publicKey: {
			...options,
			challenge: toBuffer(options.challenge),
			user: { ...options.user, id: toBuffer(options.user.id) },
			excludeCredentials: options.excludeCredentials.map((item) => ({
				...item,
				id: toBuffer(item.id),
			})),
		},
	})) as PublicKeyCredential | null;
	if (!credential) throw new Error("passkey_cancelled");
	const response = credential.response as AuthenticatorAttestationResponse;
	return {
		response: {
			clientDataJSON: toBase64Url(response.clientDataJSON),
			attestationObject: toBase64Url(response.attestationObject),
		},
	};
}

/** Signs in with a passkey this device holds for the site. */
export async function getPasskey(
	options: PasskeyLoginOptions,
): Promise<PasskeyLoginAnswer> {
	const credential = (await navigator.credentials.get({
		publicKey: {
			challenge: toBuffer(options.challenge),
			rpId: options.rpId,
			timeout: options.timeout,
			userVerification: options.userVerification,
		},
	})) as PublicKeyCredential | null;
	if (!credential) throw new Error("passkey_cancelled");
	const response = credential.response as AuthenticatorAssertionResponse;
	return {
		id: toBase64Url(credential.rawId),
		response: {
			clientDataJSON: toBase64Url(response.clientDataJSON),
			authenticatorData: toBase64Url(response.authenticatorData),
			signature: toBase64Url(response.signature),
		},
	};
}
