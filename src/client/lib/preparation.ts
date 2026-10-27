/**
 * @module client/lib/preparation
 * @layer ViewModel (Smooth Async Transition Timer)
 * @purpose Ensures async document-reading and translation transitions remain visible for
 *          at least 2.5 seconds so consumers experience calm, jitter-free state updates.
 */

import { useCallback, useEffect, useRef, useState } from "react";

export const MIN_PREPARATION_EXPOSURE_MS = 2500;

export function useCalmPreparation(
	minDurationMs = MIN_PREPARATION_EXPOSURE_MS,
) {
	const [isPreparing, setIsPreparing] = useState(false);
	const abortRef = useRef(0);

	useEffect(() => {
		return () => {
			abortRef.current += 1;
		};
	}, []);

	const runCalmly = useCallback(
		async <T>(work: () => Promise<T>): Promise<T | null> => {
			const token = abortRef.current + 1;
			abortRef.current = token;
			setIsPreparing(true);

			const minWait = new Promise<void>((resolve) => {
				window.setTimeout(resolve, minDurationMs);
			});

			try {
				const [result] = await Promise.all([work(), minWait]);
				if (abortRef.current !== token) {
					return null;
				}
				return result;
			} finally {
				if (abortRef.current === token) {
					setIsPreparing(false);
				}
			}
		},
		[minDurationMs],
	);

	const cancelPreparation = useCallback(() => {
		abortRef.current += 1;
		setIsPreparing(false);
	}, []);

	return {
		isPreparing,
		runCalmly,
		cancelPreparation,
	};
}
