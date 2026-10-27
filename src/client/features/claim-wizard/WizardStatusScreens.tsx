/**
 * @module client/features/claim-wizard/WizardStatusScreens
 * @layer View (Wizard Gate & Completion Screens)
 * @purpose Renders the guest sign-in gate before starting a private refund request
 *          and the celebratory confirmation screen once a request is saved.
 */

import { CheckCircle2, LogIn, Sparkles } from "lucide-react";
import { InteractiveAuroraCanvas } from "@/client/components/effects/InteractiveAuroraCanvas";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Badge, Button, Card } from "@/client/components/ui/Primitives";
import type { ClaimView } from "@/client/types";

interface WizardGuestGateProps {
	demoAccountName?: string;
	isLoggingIn: boolean;
	onDemoLogin: () => void;
	onNavigateAuth: () => void;
}

export function WizardGuestGate({
	demoAccountName,
	isLoggingIn,
	onDemoLogin,
	onNavigateAuth,
}: WizardGuestGateProps) {
	return (
		<InteractiveAuroraCanvas className="py-12">
			<div className="mx-auto max-w-lg px-4">
				<Card className="space-y-5 p-6 text-center sm:p-8">
					<Badge tone="brand">내 계정 전용 안전 보관</Badge>
					<ReloOrbEmblem
						variant="default"
						size="md"
						speech="내 주문 영수증과 환불 금액은 본인 계정에만 안전하게 저장돼요. 지금 바로 시작해 볼까요?"
					/>
					<div className="space-y-2.5 pt-2">
						{demoAccountName ? (
							<Button
								variant="primary"
								size="lg"
								fullWidth
								isLoading={isLoggingIn}
								onClick={onDemoLogin}
							>
								<Sparkles className="h-5 w-5" aria-hidden="true" />
								<span>체험 계정({demoAccountName})으로 1초 시작</span>
							</Button>
						) : null}
						<Button
							variant="secondary"
							size="lg"
							fullWidth
							onClick={onNavigateAuth}
						>
							<LogIn className="h-4 w-4" aria-hidden="true" />
							<span>내 이메일로 로그인 · 회원가입</span>
						</Button>
					</div>
				</Card>
			</div>
		</InteractiveAuroraCanvas>
	);
}

interface WizardSuccessScreenProps {
	claim: ClaimView;
	onOpenDetail: () => void;
	onOpenList: () => void;
}

export function WizardSuccessScreen({
	claim,
	onOpenDetail,
	onOpenList,
}: WizardSuccessScreenProps) {
	return (
		<InteractiveAuroraCanvas className="py-10">
			<div className="mx-auto max-w-xl px-4">
				<Card className="space-y-6 p-6 text-center sm:p-8">
					<Badge tone="brand">
						<CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>등록 완료 · 첨부 파일 {claim.files.length}개 보관됨</span>
					</Badge>
					<ReloOrbEmblem
						variant="verified"
						size="lg"
						speech="등록이 완료되었어요! 이제 다음 화면에서 쇼핑몰에 보낼 외국어 환불 메시지를 바로 복사해 보세요."
					/>
					<div className="space-y-1.5 rounded-2xl bg-relo-sunken p-4 text-left text-xs">
						<p className="text-sm font-extrabold text-relo-ink">
							{claim.vendor} · {claim.title}
						</p>
						<p className="text-relo-muted">
							주문번호 {claim.orderRef} · 다음 할 일:{" "}
							<strong className="text-relo-brand">{claim.nextStep}</strong>
						</p>
					</div>
					<div className="flex flex-col gap-2.5 sm:flex-row">
						<Button
							variant="primary"
							size="lg"
							fullWidth
							onClick={onOpenDetail}
						>
							<Sparkles className="h-5 w-5" aria-hidden="true" />
							<span>외국어 환불 메시지 만들러 가기</span>
						</Button>
						<Button variant="secondary" size="lg" onClick={onOpenList}>
							내 환불 내역
						</Button>
					</div>
				</Card>
			</div>
		</InteractiveAuroraCanvas>
	);
}
