/**
 * @module client/features/landing/HeroProductShowcase
 * @layer View (Hero Product Preview)
 * @purpose Shows the real app screens right under the hero headline so visitors see what
 *          the service does before reading anything: receipt reading, card refund check,
 *          and the foreign-language message. Three phones on wide screens, one on phones.
 *          The row is cut off at its bottom edge on purpose; the same screens are
 *          explained one by one in the scroll story below (TossPhoneScenes).
 */

import { motion } from "motion/react";
import { PhoneHardwareFrame } from "@/client/features/landing/PhoneHardwareFrame";
import { PhoneStoryScreens } from "@/client/features/landing/PhoneStoryScreens";
import { useI18n } from "@/client/i18n";
import { cn } from "@/lib/utils";

/** Left, center, right. The center is the outcome people came for: the refund landing on the card. */
const SCENE_ORDER = [0, 2, 1] as const;

export function HeroProductShowcase() {
	const { t } = useI18n();
	const scenes = t.phoneStory.scenes;

	return (
		// Decorative preview: the same content is reachable, with full explanations, further down.
		<div
			aria-hidden="true"
			className="relative mx-auto mt-10 h-[330px] max-w-6xl overflow-hidden px-4 sm:mt-12 sm:h-[360px] sm:px-6"
		>
			<div className="pointer-events-none absolute top-2 left-1/2 h-[520px] w-[900px] -translate-x-1/2 rounded-full bg-[radial-gradient(closest-side,rgba(27,100,218,0.18),rgba(27,100,218,0))]" />
			<div className="relative flex items-start justify-center gap-7">
				{SCENE_ORDER.map((sceneIndex, position) => {
					const isSide = position !== 1;
					return (
						<motion.div
							key={sceneIndex}
							initial={{ opacity: 0, y: 36 }}
							animate={{ opacity: 1, y: 0 }}
							transition={{
								duration: 0.5,
								delay: 0.18 + position * 0.07,
								ease: [0.22, 0.61, 0.36, 1],
							}}
							className={cn(
								"shrink-0",
								// Side phones sit lower and smaller, and only appear when there is room for three.
								isSide &&
									"hidden origin-top translate-y-[54px] scale-[0.88] lg:block",
							)}
						>
							<PhoneHardwareFrame>
								<PhoneStoryScreens
									activeScene={sceneIndex}
									current={scenes[sceneIndex]}
								/>
							</PhoneHardwareFrame>
						</motion.div>
					);
				})}
			</div>
		</div>
	);
}
