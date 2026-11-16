/**
 * @module client/i18n/screens/kinds
 * @layer Model (Localization Dictionary — exchange, repair, and fixing a record)
 * @purpose The words an exchange or a repair uses where a refund talks about money (states,
 *          next steps, tabs, stages, the "I received it" form), and the words for the ways
 *          out of a stuck refund: no reply from the shop, a deposit with no number, undoing
 *          a wrong record, changing how it is settled. Four languages.
 */

import type { DeepStringShape } from "@/client/i18n/types";

export const kindsKo = {
	/** An exchange: what comes back is the replacement, counted in items. */
	exchange: {
		states: { partial: "일부 수령", recovered: "수령 확인" },
		nextSteps: {
			completed: "마무리된 건이에요. 교환품을 받은 기록을 확인할 수 있어요.",
			recovered: "교환품을 모두 받았어요. 내용을 살펴보고 마무리해 주세요.",
			remaining: "아직 받지 못한 교환품이 있어요. 도착하면 기록해 주세요.",
			awaiting: "쇼핑몰 답장이 오면 붙여 넣어 주세요.",
			needProof: "교환품을 받으면 사진과 함께 기록해 주세요.",
		},
		history: {
			receiptRecorded: "교환품 수령 기록",
			receiptCorrected: "수령 기록 되돌림",
		},
		replyKinds: { agreement: "교환 약속", refund_notice: "교환품 발송 알림" },
		replyOptions: {
			agreement: "교환 약속 (보내 주기로 함)",
			refund_notice: "교환품 발송 안내 (아직 도착 전)",
			denied: "교환 거절 · 다시 문의해야 함",
		},
		tabs: { reply: "쇼핑몰 답장", settlement: "사진 · 교환품 확인" },
		stages: {
			negotiatingSub: "교환 방법 확인",
			recoveredLabel: "수령 확인",
			recoveredSub: "교환품 도착",
			partial: "일부 수령",
		},
		settlement: {
			eyebrow: "교환품 도착 확인",
			title: "쇼핑몰 말만 믿지 않고, 실제로 받은 교환품을 직접 확인해요",
			proofLabel: "받은 교환품 사진",
			dateLabel: "실제로 받은 날짜",
			confirmLabel: "발송 안내 메일이 아니라, 교환품을 직접 받아서 확인했어요.",
			submit: "받았다고 기록하기",
			ledgerTitle: "받은 기록 {n}건",
			toastDone: "받은 교환품을 기록했어요.",
			toastFail: "기록하지 못했어요.",
		},
	},
	/** A repair: what comes back is the repaired item or the parts, once. */
	repair: {
		states: { partial: "일부 수령", recovered: "수리 확인" },
		nextSteps: {
			completed: "마무리된 건이에요. 수리 결과 기록을 확인할 수 있어요.",
			recovered: "수리 결과를 확인했어요. 내용을 살펴보고 마무리해 주세요.",
			remaining: "수리된 물건이나 부품을 받으면 기록해 주세요.",
			awaiting: "쇼핑몰 답장이 오면 붙여 넣어 주세요.",
			needProof: "수리된 물건이나 부품을 받으면 사진과 함께 기록해 주세요.",
		},
		history: {
			receiptRecorded: "수리 결과 확인 기록",
			receiptCorrected: "수리 기록 되돌림",
		},
		replyKinds: { agreement: "수리 약속", refund_notice: "수리 · 발송 알림" },
		replyOptions: {
			agreement: "수리 · 부품 약속 (해 주기로 함)",
			refund_notice: "수리 · 발송 안내 (아직 받기 전)",
			denied: "수리 거절 · 다시 문의해야 함",
		},
		tabs: { reply: "쇼핑몰 답장", settlement: "사진 · 수리 확인" },
		stages: {
			negotiatingSub: "수리 방법 확인",
			recoveredLabel: "수리 확인",
			recoveredSub: "수리 · 부품 도착",
			partial: "일부 수령",
		},
		settlement: {
			eyebrow: "수리 결과 확인",
			title: "쇼핑몰 말만 믿지 않고, 수리된 물건이나 부품을 직접 확인해요",
			proofLabel: "수리된 물건 · 받은 부품 사진",
			dateLabel: "실제로 받은 날짜",
			confirmLabel:
				"안내 메일이 아니라, 수리된 물건이나 부품을 직접 받아서 확인했어요.",
			submit: "수리 결과 기록하기",
			ledgerTitle: "확인한 기록 {n}건",
			toastDone: "수리 결과를 기록했어요.",
			toastFail: "기록하지 못했어요.",
		},
	},
	/** The summary at the top of an exchange or a repair (a refund shows money there). */
	progress: {
		goodsLabel: "받은 교환품",
		count: "{n}개",
		ofTotal: "/ {n}개",
		requested: "요청 수량",
		received: "받은 수량",
		left: "남은 수량",
		repairLabel: "수리 결과",
		repairPending: "아직 확인 전",
		repairDone: "받아서 확인함",
		itemPrice: "상품 금액",
	},
	/** One quiet line under the summary: a way out when the shop goes silent, or a finished one. */
	notices: {
		noAnswer: "쇼핑몰이 답하지 않거나 약속을 지키지 않나요?",
		noAnswerAction: "다른 해결 방법 보기",
		toastDisputed: "쇼핑몰 밖에서 해결하는 방법을 정리했어요.",
		completed: "마무리한 건이에요. 기록을 고치려면 다시 열어 주세요.",
		reopen: "다시 열기",
		toastReopened: "다시 열었어요.",
		toastFail: "바꾸지 못했어요. 잠시 뒤 다시 해 주세요.",
	},
	/** Changing how it is settled (a refund that became an exchange, or the other way). */
	method: {
		label: "쇼핑몰과 정한 해결 방법",
		locked:
			"받은 기록이 있어서 바꿀 수 없어요. 바꾸려면 기록을 먼저 되돌려 주세요.",
		toastSaved: "해결 방법을 바꿨어요.",
		toastFail: "해결 방법을 바꾸지 못했어요.",
	},
	/** A deposit whose statement line has no number. */
	noRef: {
		noteLabel: "어디에서 확인했는지 메모 (10자 이상)",
		notePlaceholder: "예: 카드 앱 취소 내역에서 금액과 날짜를 확인함",
		confirm: "번호가 없는 내역이고, 같은 입금을 앞에서 적지 않았어요.",
	},
	/** The list of what was received, and taking a wrong line back. */
	ledger: {
		goods: "교환품 {n}개",
		repair: "수리 결과 확인",
		undo: "기록 되돌리기",
		undone: "되돌린 기록",
		reasonLabel: "되돌리는 이유",
		reasonPlaceholder: "예: 금액을 잘못 적었어요",
		confirmUndo: "되돌리기",
		cancel: "취소",
		toastUndone: "기록을 되돌렸어요.",
		toastUndoFail: "기록을 되돌리지 못했어요.",
	},
	receipt: {
		quantityLabel: "받은 수량 (남은 {n}개)",
		allDone: "받을 것을 모두 기록했어요.",
		locked: "마무리했거나 멈춘 건이라 새로 기록할 수 없어요.",
	},
	/** Lines of the dispute summary that are not about money. */
	summary: {
		goodsLine: "교환품 {n}개 받음",
		repairLine: "수리 결과 확인",
		goodsOf: "{got} / {total}개",
	},
} as const;

type Shape = DeepStringShape<typeof kindsKo>;

export const kindsEn: Shape = {
	exchange: {
		states: { partial: "Partly received", recovered: "Replacement received" },
		nextSteps: {
			completed: "This one is finished. You can look over what was received.",
			recovered: "Every replacement has arrived. Look it over and finish up.",
			remaining:
				"Some replacements have not arrived yet. Record them when they do.",
			awaiting: "When the shop replies, paste it in.",
			needProof: "When the replacement arrives, record it with a photo.",
		},
		history: {
			receiptRecorded: "Replacement recorded",
			receiptCorrected: "Receipt record undone",
		},
		replyKinds: {
			agreement: "Promised a replacement",
			refund_notice: "Replacement on its way",
		},
		replyOptions: {
			agreement: "Promised a replacement",
			refund_notice: "Replacement shipped (not arrived yet)",
			denied: "Refused · need to ask again",
		},
		tabs: { reply: "Shop reply", settlement: "Photos · Replacement check" },
		stages: {
			negotiatingSub: "Agree how to swap",
			recoveredLabel: "Received",
			recoveredSub: "Replacement arrived",
			partial: "Partly received",
		},
		settlement: {
			eyebrow: "Check the replacement really arrived",
			title:
				"Do not take the shop's word for it: check the replacement you actually received",
			proofLabel: "Photo of the replacement you received",
			dateLabel: "Date you actually received it",
			confirmLabel:
				"I received and checked the replacement myself, not just a shipping email.",
			submit: "Record as received",
			ledgerTitle: "Received · {n}",
			toastDone: "The replacement is recorded.",
			toastFail: "Could not record it.",
		},
	},
	repair: {
		states: { partial: "Partly received", recovered: "Repair checked" },
		nextSteps: {
			completed: "This one is finished. You can look over the repair record.",
			recovered: "The repair is checked. Look it over and finish up.",
			remaining: "When the repaired item or the parts arrive, record them.",
			awaiting: "When the shop replies, paste it in.",
			needProof:
				"When the repaired item or the parts arrive, record them with a photo.",
		},
		history: {
			receiptRecorded: "Repair result recorded",
			receiptCorrected: "Repair record undone",
		},
		replyKinds: {
			agreement: "Promised a repair",
			refund_notice: "Repair or parts on the way",
		},
		replyOptions: {
			agreement: "Promised a repair or parts",
			refund_notice: "Repair or parts on the way (not received yet)",
			denied: "Refused · need to ask again",
		},
		tabs: { reply: "Shop reply", settlement: "Photos · Repair check" },
		stages: {
			negotiatingSub: "Agree how to repair",
			recoveredLabel: "Repair checked",
			recoveredSub: "Item or parts arrived",
			partial: "Partly received",
		},
		settlement: {
			eyebrow: "Check the repair result",
			title:
				"Do not take the shop's word for it: check the repaired item or the parts yourself",
			proofLabel: "Photo of the repaired item or the parts",
			dateLabel: "Date you actually received it",
			confirmLabel:
				"I received and checked the repaired item or the parts myself, not just an email.",
			submit: "Record the repair result",
			ledgerTitle: "Checked · {n}",
			toastDone: "The repair result is recorded.",
			toastFail: "Could not record it.",
		},
	},
	progress: {
		goodsLabel: "Replacements received",
		count: "{n}",
		ofTotal: "/ {n}",
		requested: "Requested",
		received: "Received",
		left: "Still to come",
		repairLabel: "Repair result",
		repairPending: "Not checked yet",
		repairDone: "Received and checked",
		itemPrice: "Item price",
	},
	notices: {
		noAnswer: "Is the shop not answering, or not keeping its promise?",
		noAnswerAction: "See other ways to settle this",
		toastDisputed: "Here are the ways to settle this outside the shop.",
		completed: "This one is finished. Open it again to change a record.",
		reopen: "Open again",
		toastReopened: "Opened again.",
		toastFail: "Could not change it. Please try again in a moment.",
	},
	method: {
		label: "How you and the shop agreed to settle this",
		locked:
			"Something is already recorded as received, so this cannot change. Undo the record first.",
		toastSaved: "Changed how this is settled.",
		toastFail: "Could not change it.",
	},
	noRef: {
		noteLabel: "Where you checked it (10 characters or more)",
		notePlaceholder:
			"e.g. Checked the amount and date in my card app's refund list",
		confirm:
			"This entry has no number, and I have not recorded the same deposit before.",
	},
	ledger: {
		goods: "Replacements: {n}",
		repair: "Repair result checked",
		undo: "Undo this record",
		undone: "Undone",
		reasonLabel: "Why you are undoing it",
		reasonPlaceholder: "e.g. I entered the wrong amount",
		confirmUndo: "Undo",
		cancel: "Cancel",
		toastUndone: "The record is undone.",
		toastUndoFail: "Could not undo the record.",
	},
	receipt: {
		quantityLabel: "Quantity received ({n} still to come)",
		allDone: "Everything is recorded.",
		locked: "This one is finished or stopped, so nothing new can be recorded.",
	},
	summary: {
		goodsLine: "Replacements received: {n}",
		repairLine: "Repair result checked",
		goodsOf: "{got} / {total}",
	},
};

export const kindsJa: Shape = {
	exchange: {
		states: { partial: "一部受け取り", recovered: "受け取り確認" },
		nextSteps: {
			completed: "完了した件です。交換品を受け取った記録を確認できます。",
			recovered:
				"交換品をすべて受け取りました。内容を見直して完了にしてください。",
			remaining: "まだ届いていない交換品があります。届いたら記録してください。",
			awaiting: "ショップから返信が来たら貼り付けてください。",
			needProof: "交換品が届いたら、写真と一緒に記録してください。",
		},
		history: {
			receiptRecorded: "交換品の受け取りを記録",
			receiptCorrected: "受け取り記録を取り消し",
		},
		replyKinds: { agreement: "交換の約束", refund_notice: "交換品の発送案内" },
		replyOptions: {
			agreement: "交換の約束（送ってもらえる）",
			refund_notice: "交換品の発送案内（まだ到着前）",
			denied: "交換の拒否 · 再度の問い合わせが必要",
		},
		tabs: { reply: "ショップの返信", settlement: "写真 · 交換品の確認" },
		stages: {
			negotiatingSub: "交換方法の確認",
			recoveredLabel: "受け取り確認",
			recoveredSub: "交換品が到着",
			partial: "一部受け取り",
		},
		settlement: {
			eyebrow: "交換品の到着確認",
			title:
				"ショップの言葉だけを信じず、実際に受け取った交換品を直接確認します",
			proofLabel: "受け取った交換品の写真",
			dateLabel: "実際に受け取った日付",
			confirmLabel:
				"発送案内のメールではなく、交換品を自分で受け取って確認しました。",
			submit: "受け取りを記録する",
			ledgerTitle: "受け取りの記録 {n}件",
			toastDone: "受け取った交換品を記録しました。",
			toastFail: "記録できませんでした。",
		},
	},
	repair: {
		states: { partial: "一部受け取り", recovered: "修理確認" },
		nextSteps: {
			completed: "完了した件です。修理結果の記録を確認できます。",
			recovered: "修理結果を確認しました。内容を見直して完了にしてください。",
			remaining: "修理された品物や部品が届いたら記録してください。",
			awaiting: "ショップから返信が来たら貼り付けてください。",
			needProof:
				"修理された品物や部品が届いたら、写真と一緒に記録してください。",
		},
		history: {
			receiptRecorded: "修理結果の確認を記録",
			receiptCorrected: "修理記録を取り消し",
		},
		replyKinds: { agreement: "修理の約束", refund_notice: "修理 · 発送の案内" },
		replyOptions: {
			agreement: "修理・部品の約束（対応してもらえる）",
			refund_notice: "修理 · 発送の案内（まだ受け取り前）",
			denied: "修理の拒否 · 再度の問い合わせが必要",
		},
		tabs: { reply: "ショップの返信", settlement: "写真 · 修理の確認" },
		stages: {
			negotiatingSub: "修理方法の確認",
			recoveredLabel: "修理確認",
			recoveredSub: "修理品 · 部品が到着",
			partial: "一部受け取り",
		},
		settlement: {
			eyebrow: "修理結果の確認",
			title: "ショップの言葉だけを信じず、修理された品物や部品を直接確認します",
			proofLabel: "修理された品物 · 受け取った部品の写真",
			dateLabel: "実際に受け取った日付",
			confirmLabel:
				"案内のメールではなく、修理された品物や部品を自分で受け取って確認しました。",
			submit: "修理結果を記録する",
			ledgerTitle: "確認した記録 {n}件",
			toastDone: "修理結果を記録しました。",
			toastFail: "記録できませんでした。",
		},
	},
	progress: {
		goodsLabel: "受け取った交換品",
		count: "{n}個",
		ofTotal: "/ {n}個",
		requested: "依頼した数量",
		received: "受け取った数量",
		left: "残りの数量",
		repairLabel: "修理結果",
		repairPending: "まだ未確認",
		repairDone: "受け取って確認済み",
		itemPrice: "商品の金額",
	},
	notices: {
		noAnswer: "ショップから返事がない、または約束が守られませんか？",
		noAnswerAction: "ほかの解決方法を見る",
		toastDisputed: "ショップの外で解決する方法をまとめました。",
		completed: "完了した件です。記録を直すには、もう一度開いてください。",
		reopen: "もう一度開く",
		toastReopened: "もう一度開きました。",
		toastFail: "変更できませんでした。しばらくしてからもう一度お試しください。",
	},
	method: {
		label: "ショップと決めた解決方法",
		locked:
			"受け取りの記録があるため変更できません。変更するには、先に記録を取り消してください。",
		toastSaved: "解決方法を変更しました。",
		toastFail: "解決方法を変更できませんでした。",
	},
	noRef: {
		noteLabel: "どこで確認したかのメモ（10文字以上）",
		notePlaceholder: "例：カードアプリの取消明細で金額と日付を確認",
		confirm: "番号のない明細で、同じ入金をすでに記録していません。",
	},
	ledger: {
		goods: "交換品 {n}個",
		repair: "修理結果を確認",
		undo: "記録を取り消す",
		undone: "取り消した記録",
		reasonLabel: "取り消す理由",
		reasonPlaceholder: "例：金額を間違えて入力しました",
		confirmUndo: "取り消す",
		cancel: "キャンセル",
		toastUndone: "記録を取り消しました。",
		toastUndoFail: "記録を取り消せませんでした。",
	},
	receipt: {
		quantityLabel: "受け取った数量（残り{n}個）",
		allDone: "受け取るものはすべて記録しました。",
		locked: "完了または中止した件のため、新しく記録できません。",
	},
	summary: {
		goodsLine: "交換品を{n}個受け取り",
		repairLine: "修理結果を確認",
		goodsOf: "{got} / {total}個",
	},
};

export const kindsZh: Shape = {
	exchange: {
		states: { partial: "部分收到", recovered: "已收到" },
		nextSteps: {
			completed: "这一单已结束。可以查看收到换货的记录。",
			recovered: "换货已全部收到。请核对内容后结束。",
			remaining: "还有换货没有收到。到了以后请记录。",
			awaiting: "商城回复后请粘贴进来。",
			needProof: "收到换货后，请连同照片一起记录。",
		},
		history: {
			receiptRecorded: "已记录收到换货",
			receiptCorrected: "已撤销收货记录",
		},
		replyKinds: { agreement: "承诺换货", refund_notice: "换货发货通知" },
		replyOptions: {
			agreement: "承诺换货（答应寄出）",
			refund_notice: "换货已发货（尚未收到）",
			denied: "拒绝换货 · 需要再次联系",
		},
		tabs: { reply: "商城回复", settlement: "照片 · 换货核对" },
		stages: {
			negotiatingSub: "确认换货方式",
			recoveredLabel: "已收到",
			recoveredSub: "换货已到",
			partial: "部分收到",
		},
		settlement: {
			eyebrow: "核对换货是否真的收到",
			title: "不只听商城怎么说，亲自核对实际收到的换货",
			proofLabel: "收到的换货照片",
			dateLabel: "实际收到的日期",
			confirmLabel: "我是亲自收到并核对了换货，而不是只看了发货通知邮件。",
			submit: "记录为已收到",
			ledgerTitle: "收货记录 {n}条",
			toastDone: "已记录收到的换货。",
			toastFail: "没能记录。",
		},
	},
	repair: {
		states: { partial: "部分收到", recovered: "维修已确认" },
		nextSteps: {
			completed: "这一单已结束。可以查看维修结果的记录。",
			recovered: "维修结果已确认。请核对内容后结束。",
			remaining: "收到修好的物品或配件后请记录。",
			awaiting: "商城回复后请粘贴进来。",
			needProof: "收到修好的物品或配件后，请连同照片一起记录。",
		},
		history: {
			receiptRecorded: "已记录维修结果",
			receiptCorrected: "已撤销维修记录",
		},
		replyKinds: { agreement: "承诺维修", refund_notice: "维修 · 发货通知" },
		replyOptions: {
			agreement: "承诺维修或寄配件",
			refund_notice: "维修 · 发货通知（尚未收到）",
			denied: "拒绝维修 · 需要再次联系",
		},
		tabs: { reply: "商城回复", settlement: "照片 · 维修核对" },
		stages: {
			negotiatingSub: "确认维修方式",
			recoveredLabel: "维修已确认",
			recoveredSub: "物品 · 配件已到",
			partial: "部分收到",
		},
		settlement: {
			eyebrow: "核对维修结果",
			title: "不只听商城怎么说，亲自核对修好的物品或配件",
			proofLabel: "修好的物品 · 收到的配件照片",
			dateLabel: "实际收到的日期",
			confirmLabel:
				"我是亲自收到并核对了修好的物品或配件，而不是只看了通知邮件。",
			submit: "记录维修结果",
			ledgerTitle: "核对记录 {n}条",
			toastDone: "已记录维修结果。",
			toastFail: "没能记录。",
		},
	},
	progress: {
		goodsLabel: "已收到的换货",
		count: "{n}件",
		ofTotal: "/ {n}件",
		requested: "申请数量",
		received: "已收到数量",
		left: "剩余数量",
		repairLabel: "维修结果",
		repairPending: "尚未确认",
		repairDone: "已收到并确认",
		itemPrice: "商品金额",
	},
	notices: {
		noAnswer: "商城不回复，或者没有兑现承诺吗？",
		noAnswerAction: "查看其他解决办法",
		toastDisputed: "已整理出在商城之外解决的办法。",
		completed: "这一单已结束。要修改记录，请重新打开。",
		reopen: "重新打开",
		toastReopened: "已重新打开。",
		toastFail: "没能更改。请稍后再试。",
	},
	method: {
		label: "和商城商定的解决方式",
		locked: "已有收到的记录，所以不能更改。要更改，请先撤销记录。",
		toastSaved: "已更改解决方式。",
		toastFail: "没能更改解决方式。",
	},
	noRef: {
		noteLabel: "在哪里核对的（至少10个字）",
		notePlaceholder: "如：在银行卡 App 的退款明细里核对了金额和日期",
		confirm: "这笔明细没有编号，而且我之前没有记录过同一笔到账。",
	},
	ledger: {
		goods: "换货 {n}件",
		repair: "已确认维修结果",
		undo: "撤销这条记录",
		undone: "已撤销的记录",
		reasonLabel: "撤销的原因",
		reasonPlaceholder: "如：金额填错了",
		confirmUndo: "撤销",
		cancel: "取消",
		toastUndone: "已撤销记录。",
		toastUndoFail: "没能撤销记录。",
	},
	receipt: {
		quantityLabel: "收到的数量（还剩{n}件）",
		allDone: "该收到的都已记录。",
		locked: "这一单已结束或已停止，不能再新增记录。",
	},
	summary: {
		goodsLine: "收到换货 {n}件",
		repairLine: "已确认维修结果",
		goodsOf: "{got} / {total}件",
	},
};
