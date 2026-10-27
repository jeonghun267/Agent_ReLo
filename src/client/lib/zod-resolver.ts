/**
 * @module client/lib/zod-resolver
 * @layer Adapter (Zod v4 -> React Hook Form Resolver)
 * @purpose Non-conflicting adapter bridging Zod v4 schemas with react-hook-form without runtime version conflicts.
 */

import type {
	FieldError,
	FieldErrors,
	FieldValues,
	Resolver,
} from "react-hook-form";
import type { z } from "zod";

function setNestedError(
	target: Record<string, unknown>,
	path: PropertyKey[],
	error: FieldError,
): void {
	if (path.length === 0) {
		if (!target.root) {
			target.root = error;
		}
		return;
	}

	let current: Record<string, unknown> = target;
	for (let i = 0; i < path.length - 1; i += 1) {
		const segment = String(path[i]);
		if (typeof current[segment] !== "object" || current[segment] === null) {
			current[segment] = {};
		}
		current = current[segment] as Record<string, unknown>;
	}

	const leaf = String(path[path.length - 1]);
	if (!current[leaf]) {
		current[leaf] = error;
	}
}

/**
 * Non-conflicting Zod v4 adapter for react-hook-form.
 * Prevents Zod v4 vs @hookform/resolvers v3 runtime mismatch while keeping strict typing.
 */
export function zodV4Resolver<TFieldValues extends FieldValues>(
	schema: z.ZodType<TFieldValues>,
): Resolver<TFieldValues> {
	return async (values) => {
		const parsed = await schema.safeParseAsync(values);
		if (parsed.success) {
			return {
				values: parsed.data,
				errors: {},
			};
		}

		const fieldErrors: Record<string, unknown> = {};
		for (const issue of parsed.error.issues) {
			setNestedError(fieldErrors, issue.path, {
				type: issue.code,
				message: issue.message,
			});
		}

		return {
			values: {},
			errors: fieldErrors as FieldErrors<TFieldValues>,
		};
	};
}
