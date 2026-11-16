import '../../core/i18n/relo_i18n.dart';
import '../../core/utils/money_format.dart';
import 'claim_rules.dart';
import 'domain_models.dart';

/// @module shared/models/claim_words
/// @purpose 환불 · 교환 · 수리 건을 가리키는 말을 네 언어로. 교환과 수리는 돈 이야기가 나오는
///          자리에 자기 말을 쓴다. 막힌 건을 푸는 말(번호 없는 입금, 기록 되돌리기, 답 없는
///          쇼핑몰, 분쟁 해결 안내)도 여기에 둔다. 웹의 문구(i18n/screens)와 같은 뜻이다.
extension ClaimWords on ReloStrings {
  String _w(String ko, String en, String ja, String zh) => switch (locale) {
        ReloLocale.ko => ko,
        ReloLocale.en => en,
        ReloLocale.ja => ja,
        ReloLocale.zh => zh,
      };

  // ── 상태 한마디 (목록 줄 · 상세 맨 위) ───────────────────────────────
  String cwPartial(String kind) => kind == 'refund'
      ? _w('일부만 입금됨', 'Partly refunded', '一部のみ入金', '部分到账')
      : _w('일부만 받음', 'Partly received', '一部のみ受け取り', '部分收到');
  String cwReceived(String kind) => switch (kind) {
        'exchange' =>
          _w('교환품 받음', 'Replacement received', '交換品を受け取り', '已收到换货'),
        'repair' => _w('수리 확인', 'Repair checked', '修理を確認', '维修已确认'),
        _ => csReceived,
      };
  String get cwDisputed => _w(
      '쇼핑몰에서 해결 안 됨', 'Not settled with the shop', 'ショップで未解決', '商城未解决');
  String get cwWaived => _w('그만둔 건', 'Stopped', '中止した件', '已停止');

  /// 목록 줄 오른쪽에 돈 대신 적는 말: "1개 / 3개", "아직 확인 전". 환불이면 null.
  String? cwArrived(ClaimView c) => switch (c.kind) {
        'exchange' =>
          '${cwCount(c.summary.goods)} / ${cwCount(c.summary.requestedQty)}',
        'repair' => c.summary.repair ? cwRepairDone : cwRepairPending,
        _ => null,
      };

  // ── 지금 할 일 한 줄 ─────────────────────────────────────────────────
  /// [code]는 [nextStepCode]가 준 이름. 교환 · 수리는 돈 대신 받을 것을 말한다.
  String cwNextStep(String kind, String code) {
    if (kind == 'exchange') {
      switch (code) {
        case 'completed':
          return _w('마무리된 건이에요. 교환품을 받은 기록을 확인할 수 있어요.', 'This one is finished. You can look over what was received.', '完了した件です。交換品を受け取った記録を確認できます。', '这一单已结束。可以查看收到换货的记录。');
        case 'recovered':
          return _w('교환품을 모두 받았어요. 내용을 살펴보고 마무리해 주세요.', 'Every replacement has arrived. Look it over and finish up.', '交換品をすべて受け取りました。内容を見直して完了にしてください。', '换货已全部收到。请核对内容后结束。');
        case 'remaining':
          return _w('아직 받지 못한 교환품이 있어요. 도착하면 기록해 주세요.', 'Some replacements have not arrived yet. Record them when they do.', 'まだ届いていない交換品があります。届いたら記録してください。', '还有换货没有收到。到了以后请记录。');
        case 'needProof':
          return _w('교환품을 받으면 사진과 함께 기록해 주세요.', 'When the replacement arrives, record it with a photo.', '交換品が届いたら、写真と一緒に記録してください。', '收到换货后，请连同照片一起记录。');
      }
    }
    if (kind == 'repair') {
      switch (code) {
        case 'completed':
          return _w('마무리된 건이에요. 수리 결과 기록을 확인할 수 있어요.', 'This one is finished. You can look over the repair record.', '完了した件です。修理結果の記録を確認できます。', '这一单已结束。可以查看维修结果的记录。');
        case 'recovered':
          return _w('수리 결과를 확인했어요. 내용을 살펴보고 마무리해 주세요.', 'The repair is checked. Look it over and finish up.', '修理結果を確認しました。内容を見直して完了にしてください。', '维修结果已确认。请核对内容后结束。');
        case 'needProof':
          return _w('수리된 물건이나 부품을 받으면 사진과 함께 기록해 주세요.', 'When the repaired item or the parts arrive, record them with a photo.', '修理された品物や部品が届いたら、写真と一緒に記録してください。', '收到修好的物品或配件后，请连同照片一起记录。');
      }
    }
    return switch (code) {
      'trashed' => _w('휴지통에 있어요. 꺼내면 이어서 진행할 수 있어요.', 'This is in the trash. Restore it to carry on.', 'ごみ箱にあります。元に戻すと続きから進められます。', '已在回收站。恢复后可以继续。'),
      'waived' => _w('더 진행하지 않기로 한 건이에요. 언제든 다시 진행할 수 있어요.', 'You chose to stop this one. You can continue any time.', 'ここでやめることにした件です。いつでももう一度進められます。', '这一单您已决定不再继续。随时可以重新继续。'),
      'disputed' => _w('쇼핑몰에서 해결이 안 됐어요. 아래 방법을 차례로 해 보세요.', 'This could not be settled with the shop. Try the ways below, in order.', 'ショップでは解決できませんでした。下の方法を順に試してください。', '在商城没能解决。请依次尝试下面的办法。'),
      'completed' => _w('마무리된 건이에요. 입금 기록을 확인할 수 있어요.', 'This one is finished. You can look over the deposit record.', '完了した件です。入金の記録を確認できます。', '这一单已结束。可以查看到账记录。'),
      'recovered' => _w('입금을 확인했어요. 내용을 살펴보고 마무리해 주세요.', 'The money has come in. Look it over and finish up.', '入金を確認しました。内容を見直して完了にしてください。', '钱已到账。请核对内容后结束。'),
      'remaining' => _w('남은 금액과 쇼핑몰이 정한 기한을 확인해 주세요.', "Check what is still owed and the shop's deadline.", '残りの金額とショップの期限を確認してください。', '请确认剩余金额和商城给的期限。'),
      'awaiting' => _w('쇼핑몰 답장이 오면 답장 탭에 붙여 넣으세요.', 'When the store replies, paste it in the Reply tab.', 'ショップから返信が来たら「返信」タブに貼り付けてください。', '收到商家回复后，粘贴到“回复”标签中。'),
      'needFiles' => _w('주문 내역이나 불량 사진을 올려 주세요.', 'Upload your order record or photos of the problem.', '注文の記録や不良の写真をアップロードしてください。', '请上传订单记录或问题照片。'),
      'needMessage' => _w('판매자에게 보낼 메시지를 만들어 쇼핑몰에 보내세요.', 'Draft your message and send it to the store.', 'メッセージを作成してショップに送りましょう。', '撰写消息并发送给商家。'),
      'needAgreed' => _w('쇼핑몰이 약속한 금액이 정해지면 답장 탭에 적어 주세요.', 'Once the store promises an amount, enter it in the Reply tab.', 'ショップが約束した金額が決まったら「返信」タブに入力してください。', '商家承诺金额确定后，请在“回复”标签中填写。'),
      _ => _w('카드 취소나 통장 입금을 확인하고 입금 탭에 기록하세요.', 'Check your card or bank account, then record the money you received in the Deposit tab.', 'カードの取消や口座への入金を確認し、「入金」タブに記録してください。', '确认卡退款或银行到账后，在“到账”标签中记录。'),
    };
  }

  // ── 상세 맨 위 ───────────────────────────────────────────────────────
  String cwKind(String kind) => switch (kind) {
        'exchange' => wKindExchange,
        'repair' => wKindRepair,
        _ => wKindRefund,
      };
  String cwTabReceive(String kind) => switch (kind) {
        'exchange' => _w('교환품', 'Replacement', '交換品', '换货'),
        'repair' => _w('수리', 'Repair', '修理', '维修'),
        _ => dTabDeposit,
      };
  String get cwRequestedQty => _w('요청 수량', 'Requested', '依頼した数量', '申请数量');
  String get cwReceivedQty => _w('받은 수량', 'Received', '受け取った数量', '已收到数量');
  String cwCount(int n) => _w('$n개', '$n', '$n個', '$n件');
  String get cwRepairResult => _w('수리 결과', 'Repair result', '修理結果', '维修结果');
  String get cwRepairPending =>
      _w('아직 확인 전', 'Not checked yet', 'まだ未確認', '尚未确认');
  String get cwRepairDone =>
      _w('받아서 확인함', 'Received and checked', '受け取って確認済み', '已收到并确认');
  String get cwItemPrice => _w('상품 금액', 'Item price', '商品の金額', '商品金额');
  String get cwFinish => _w('마무리하기', 'Finish', '完了にする', '结束');

  // ── 막혔을 때의 한 줄 ────────────────────────────────────────────────
  String get cwNoAnswer => _w('쇼핑몰이 답하지 않거나 약속을 지키지 않나요?', 'Is the shop not answering, or not keeping its promise?', 'ショップから返事がない、または約束が守られませんか？', '商城不回复，或者没有兑现承诺吗？');
  String get cwNoAnswerAction => _w('다른 해결 방법 보기', 'See other ways to settle this', 'ほかの解決方法を見る', '查看其他解决办法');
  String get cwToastDisputed => _w('쇼핑몰 밖에서 해결하는 방법을 정리했어요.', 'Here are the ways to settle this outside the shop.', 'ショップの外で解決する方法をまとめました。', '已整理出在商城之外解决的办法。');
  String get cwCompletedNote => _w('마무리한 건이에요. 기록을 고치려면 다시 열어 주세요.', 'This one is finished. Open it again to change a record.', '完了した件です。記録を直すには、もう一度開いてください。', '这一单已结束。要修改记录，请重新打开。');
  String get cwReopen => _w('다시 열기', 'Open again', 'もう一度開く', '重新打开');
  String get cwToastReopened => _w('다시 열었어요.', 'Opened again.', 'もう一度開きました。', '已重新打开。');
  String get cwFailed => _w('하지 못했어요. 잠시 뒤 다시 해 주세요.', 'That did not work. Please try again in a moment.', 'できませんでした。しばらくしてからもう一度お試しください。', '没能完成。请稍后再试。');

  // ── 해결 방법 바꾸기 (답장 탭) ───────────────────────────────────────
  String get cwMethodLabel => _w('쇼핑몰과 정한 해결 방법', 'How you and the shop agreed to settle this', 'ショップと決めた解決方法', '和商城商定的解决方式');
  String get cwMethodLocked => _w('받은 기록이 있어서 바꿀 수 없어요. 바꾸려면 기록을 먼저 되돌려 주세요.', 'Something is already recorded as received, so this cannot change. Undo the record first.', '受け取りの記録があるため変更できません。変更するには、先に記録を取り消してください。', '已有收到的记录，所以不能更改。要更改，请先撤销记录。');
  String get cwToastMethod => _w('해결 방법을 바꿨어요.', 'Changed how this is settled.', '解決方法を変更しました。', '已更改解决方式。');

  /// 답장 종류. 교환 · 수리는 "환불" 대신 보내 주는 것을 말한다.
  String cwReplyKind(String claimKind, String reply) => switch (reply) {
        'agreement' => switch (claimKind) {
            'exchange' => _w('교환 약속', 'Promised a replacement', '交換の約束', '承诺换货'),
            'repair' => _w('수리 약속', 'Promised a repair', '修理の約束', '承诺维修'),
            _ => _w('환불 약속', 'Promised a refund', '返金の約束', '承诺退款'),
          },
        'refund_notice' => switch (claimKind) {
            'exchange' => _w('교환품 발송 알림', 'Replacement on its way', '交換品の発送案内', '换货发货通知'),
            'repair' => _w('수리 · 발송 알림', 'Repair or parts on the way', '修理 · 発送の案内', '维修 · 发货通知'),
            _ => _w('환불 처리 알림', 'Refund on its way', '返金処理の案内', '退款处理通知'),
          },
        'evidence' => _w('자료 추가 요청', 'Asked for more proof', '資料の追加依頼', '要求补充材料'),
        'denied' => _w('거절', 'Refused', '拒否', '拒绝'),
        _ => _w('기타', 'Other', 'その他', '其他'),
      };

  // ── 받은 것 기록 ─────────────────────────────────────────────────────
  String cwReceiveTitle(String kind) => switch (kind) {
        'exchange' => _w('받은 교환품 기록', 'Record replacements received', '受け取った交換品を記録', '记录收到的换货'),
        'repair' => _w('수리 결과 기록', 'Record the repair result', '修理結果を記録', '记录维修结果'),
        _ => dDepositTitle,
      };
  String get cwRefField => _w('카드 취소 · 입금 번호 (없으면 비워 두세요)', 'Card refund or deposit number (leave empty if there is none)', 'カード取消・入金の番号（なければ空欄のまま）', '银行卡退款或到账编号（没有就留空）');
  String get cwNoRefNote => _w('어디에서 확인했는지 메모 (10자 이상)', 'Where you checked it (10 characters or more)', 'どこで確認したかのメモ（10文字以上）', '在哪里核对的（至少10个字）');
  String get cwNoRefHint => _w('예: 카드 앱 취소 내역에서 금액과 날짜를 확인함', "e.g. Checked the amount and date in my card app's refund list", '例：カードアプリの取消明細で金額と日付を確認', '如：在银行卡 App 的退款明细里核对了金额和日期');
  String get cwNoRefCheck => _w('번호가 없는 내역이고, 같은 입금을 앞에서 적지 않았어요.', 'This entry has no number, and I have not recorded the same deposit before.', '番号のない明細で、同じ入金をすでに記録していません。', '这笔明细没有编号，而且我之前没有记录过同一笔到账。');
  String get cwErrNote => _w('어디에서 확인했는지 10자 이상 적어 주세요.', 'Say where you checked it, in 10 characters or more.', 'どこで確認したかを10文字以上で書いてください。', '请用至少10个字写明在哪里核对的。');
  String get cwErrNoRefCheck => _w('번호가 없는 내역이 맞는지 확인하고 체크해 주세요.', 'Tick the box to confirm this entry has no number.', '番号のない明細であることを確認して、チェックを入れてください。', '请确认这笔明细没有编号，并勾选。');
  String cwQtyField(int left) => _w('받은 수량 (남은 $left개)', 'Quantity received ($left still to come)', '受け取った数量（残り$left個）', '收到的数量（还剩$left件）');
  String get cwErrQty => _w('받은 수량을 1개 이상, 남은 수량 이하로 적어 주세요.', 'Enter a quantity from 1 up to what is still to come.', '受け取った数量を、1以上・残りの数量以下で入力してください。', '收到的数量请填写1到剩余数量之间的数字。');
  String cwRecord(String kind) => switch (kind) {
        'exchange' => _w('받았다고 기록하기', 'Record as received', '受け取りを記録する', '记录为已收到'),
        'repair' => _w('수리 결과 기록하기', 'Record the repair result', '修理結果を記録する', '记录维修结果'),
        _ => dRecord,
      };
  String cwCaption(String kind) => switch (kind) {
        'exchange' => _w('발송 안내가 아니라, 직접 받아서 확인한 교환품만 기록해 주세요.', 'Record only replacements you received and checked yourself, not a shipping notice.', '発送の案内ではなく、自分で受け取って確認した交換品だけを記録してください。', '请只记录亲自收到并核对的换货，而不是发货通知。'),
        'repair' => _w('안내 메일이 아니라, 직접 받아서 확인한 수리 결과만 기록해 주세요.', 'Record the repair only after you received and checked it yourself, not from an email.', '案内のメールではなく、自分で受け取って確認した修理結果だけを記録してください。', '请只在亲自收到并核对后记录维修结果，而不是根据通知邮件。'),
        _ => dCardCaption,
      };
  String cwRecorded(String kind) => switch (kind) {
        'exchange' => _w('받은 교환품을 기록했어요.', 'The replacement is recorded.', '受け取った交換品を記録しました。', '已记录收到的换货。'),
        'repair' => _w('수리 결과를 기록했어요.', 'The repair result is recorded.', '修理結果を記録しました。', '已记录维修结果。'),
        _ => dBannerSub,
      };
  String cwBannerTitle(String kind) => switch (kind) {
        'exchange' => _w('교환품을 받았어요', 'The replacement is here', '交換品が届きました', '换货到了'),
        'repair' => _w('수리 결과를 확인했어요', 'The repair is checked', '修理結果を確認しました', '维修结果已确认'),
        _ => dBannerTitle,
      };
  String get cwAllDone => _w('받을 것을 모두 기록했어요.', 'Everything is recorded.', '受け取るものはすべて記録しました。', '该收到的都已记录。');
  String get cwLocked => _w('마무리했거나 멈춘 건이라 새로 기록할 수 없어요.', 'This one is finished or stopped, so nothing new can be recorded.', '完了または中止した件のため、新しく記録できません。', '这一单已结束或已停止，不能再新增记录。');
  String get cwNeedFile => _w('먼저 아래에서 확인 자료(사진 · 캡처)를 올려 주세요.', 'First add a photo or screenshot below to use as proof.', '先に、下で確認の資料（写真・スクリーンショット）を追加してください。', '请先在下面添加用作凭证的照片或截图。');

  // ── 받은 기록 목록 · 되돌리기 ────────────────────────────────────────
  String cwLedgerCount(String kind, int n) => switch (kind) {
        'exchange' => _w('받은 기록 $n건', 'Received · $n', '受け取りの記録 $n件', '收货记录 $n条'),
        'repair' => _w('확인한 기록 $n건', 'Checked · $n', '確認した記録 $n件', '核对记录 $n条'),
        _ => dLedgerCount(n),
      };
  String cwGoods(int n) => _w('교환품 $n개', 'Replacements: $n', '交換品 $n個', '换货 $n件');
  String get cwRepairEntry => _w('수리 결과 확인', 'Repair result checked', '修理結果を確認', '已确认维修结果');
  String get cwUndo => _w('기록 되돌리기', 'Undo this record', '記録を取り消す', '撤销这条记录');
  String get cwUndone => _w('되돌린 기록', 'Undone', '取り消した記録', '已撤销的记录');
  String get cwUndoTitle => _w('이 기록을 되돌릴까요?', 'Undo this record?', 'この記録を取り消しますか？', '要撤销这条记录吗？');
  String get cwUndoReason => _w('되돌리는 이유', 'Why you are undoing it', '取り消す理由', '撤销的原因');
  String get cwUndoHint => _w('예: 금액을 잘못 적었어요', 'e.g. I entered the wrong amount', '例：金額を間違えて入力しました', '如：金额填错了');
  String get cwUndoConfirm => _w('되돌리기', 'Undo', '取り消す', '撤销');
  String get cwCancel => _w('취소', 'Cancel', 'キャンセル', '取消');
  String get cwErrReason => _w('되돌리는 이유를 3자 이상 적어 주세요.', 'Give a reason of 3 characters or more.', '取り消す理由を3文字以上で書いてください。', '请用至少3个字写明撤销的原因。');
  String get cwToastUndone => _w('기록을 되돌렸어요.', 'The record is undone.', '記録を取り消しました。', '已撤销记录。');

  // ── 분쟁 해결 안내 ───────────────────────────────────────────────────
  String get dgEyebrow => _w('쇼핑몰에서 해결이 안 될 때', 'When the shop will not settle it', 'ショップで解決できないとき', '在商城解决不了时');
  String get dgTitle => _w('다른 길로 해결할 수 있어요', 'There are other ways to settle this', 'ほかの方法で解決できます', '还有其他办法可以解决');
  String get dgSub => _w('위에서부터 차례로 해 보세요. 신청은 직접 하고, ReLo는 준비를 도와요.', 'Try them in order, from the top. You file each one yourself; ReLo helps you get ready.', '上から順に試してみてください。申請はご自身で行い、ReLoは準備をお手伝いします。', '请从上到下依次尝试。申请需要您自己提交，ReLo 帮您做好准备。');
  String get dgStep1Title => _w('쇼핑몰에 분쟁 신청하기', 'Open a dispute with the marketplace', 'ショップに紛争を申し立てる', '向商城提出纠纷申请');
  String get dgStep1Body => _w('판매자가 아니라 쇼핑몰이 자료를 보고 판단해요. 주문 화면의 분쟁 · 환불 요청에서 신청하고, 남은 기간도 주문 화면에서 확인해 주세요.', 'The marketplace, not the seller, looks at what you send and decides. Start it from the order page (dispute or refund request), and check there how much time is left.', '販売者ではなく、ショップ(モール)が資料を見て判断します。注文画面の紛争・返金リクエストから申し立て、残りの期間も注文画面で確認してください。', '由商城（平台）而不是卖家查看资料并作出判断。请在订单页面的纠纷 · 退款申请中提交，剩余期限也请在订单页面确认。');
  String get dgStep2Title => _w('결제한 곳에 이의 제기하기', 'Dispute the payment', '支払い先に異議を申し立てる', '向付款方提出异议');
  String get dgStep2Body => _w('카드로 결제했다면 카드사에 차지백을, PayPal로 결제했다면 PayPal에 분쟁을 신청해요. 물건이 오지 않았거나 설명과 다를 때 결제를 되돌려 달라고 하는 절차예요.', 'If you paid by card, ask your card company for a chargeback. If you paid with PayPal, open a dispute with PayPal. Both ask for the payment to be reversed when the item never came or is not as described.', 'カードで支払った場合はカード会社にチャージバックを、PayPalで支払った場合はPayPalに異議を申し立てます。商品が届かない、説明と違うときに支払いの取り消しを求める手続きです。', '用银行卡付款的，向发卡机构申请拒付；用 PayPal 付款的，向 PayPal 提出争议。商品没有送到或与描述不符时，可以用这种方式要求撤销付款。');
  String get dgCardWindow => _w('카드 (VISA · Mastercard · AMEX)', 'Card (VISA · Mastercard · AMEX)', 'カード (VISA · Mastercard · AMEX)', '银行卡 (VISA · Mastercard · AMEX)');
  String get dgLongWindow => _w('유니온페이 카드 · PayPal', 'UnionPay card · PayPal', '銀聯カード · PayPal', '银联卡 · PayPal');
  String dgUntil(String date, int n) => _w('$date까지 · $n일 남음', 'Until $date · days left: $n', '$dateまで · 残り$n日', '截至 $date · 还剩 $n 天');
  String dgUntilToday(String date) => _w('$date까지 · 오늘이 마지막 날', 'Until $date · today is the last day', '$dateまで · 今日が最終日', '截至 $date · 今天是最后一天');
  String dgPassed(String date) => _w('$date에 지났을 수 있어요', 'May have passed on $date', '$dateに過ぎている可能性があります', '可能已在 $date 过期');
  String get dgDeadlineNote => _w('주문일부터 세어 가장 이르게 잡은 날짜예요. 세는 날이 카드사와 결제 방법마다 달라서, 신청하기 전에 꼭 확인해 주세요.', 'These are the earliest dates, counted from the order date. The starting day differs by card company and payment method, so check before you file.', '注文日から数えた、いちばん早い日付です。数え始める日はカード会社や支払い方法によって違うため、申請の前に必ず確認してください。', '这是从下单日起算的最早日期。起算日因发卡机构和付款方式而不同，申请前请务必确认。');
  String get dgStep3Title => _w('한국소비자원에 상담 신청하기', 'Ask the Korea Consumer Agency for help', '韓国消費者院に相談を申し込む', '向韩国消费者院申请咨询');
  String get dgStep3Body => _w('국제거래 소비자포털에서 무료로 상담을 신청할 수 있어요. 강제로 돌려받게 할 수는 없지만, 해외 쇼핑몰과의 사이에서 해결을 도와줘요.', 'You can ask for free counselling on its cross-border consumer portal. It cannot force a refund, but it helps settle things with overseas shops.', '国際取引消費者ポータルで、無料で相談を申し込めます。返金を強制することはできませんが、海外ショップとの解決を手伝ってくれます。', '可以在国际交易消费者门户免费申请咨询。它不能强制退款，但会帮助您与海外商城解决问题。');
  String get dgPortalCopy => _w('포털 주소 복사하기', 'Copy the portal address', 'ポータルのアドレスをコピー', '复制门户网址');
  String get dgToastPortal => _w('주소를 복사했어요. 인터넷 주소창에 붙여 넣어 주세요.', 'Address copied. Paste it into your browser.', 'アドレスをコピーしました。ブラウザに貼り付けてください。', '已复制网址。请粘贴到浏览器中。');
  String get dgSummaryCopy => _w('신청할 때 붙여 넣을 요약 복사하기', 'Copy a summary to paste when you file', '申請のときに貼り付ける要約をコピー', '复制申请时可粘贴的摘要');
  String get dgToastSummary => _w('요약을 복사했어요. 보관한 영수증 · 사진도 함께 내 주세요.', 'Summary copied. Send your saved receipts and photos with it.', '要約をコピーしました。保管した領収書や写真も一緒に提出してください。', '已复制摘要。请把保存的收据和照片一起提交。');
  String get dgOutcomeHint => _w('해결됐거나 쇼핑몰과 다시 이야기하게 됐다면 다시 진행으로 바꿔 주세요.', 'If it is settled, or you are talking with the shop again, switch this back to in progress.', '解決した、またはショップともう一度話すことになったら、進行中に戻してください。', '如果已经解决，或者又和商城重新沟通了，请改回进行中。');
  String get dgResolved => _w('다시 진행하기', 'Continue this one', 'もう一度進める', '重新继续');
  String get dgGiveUp => _w('더 진행하지 않기', 'Stop here', 'ここでやめる', '到此为止');
  String get dgToastReopened => _w('다시 진행으로 바꿨어요.', 'Switched back to in progress.', '進行中に戻しました。', '已改回进行中。');
  String get dgToastWaived => _w('더 진행하지 않는 것으로 적었어요. 언제든 다시 진행할 수 있어요.', 'Marked as stopped. You can continue any time.', 'ここでやめると記録しました。いつでももう一度進められます。', '已记录为不再继续。随时可以重新继续。');
  String get dgWaivedTitle => _w('더 진행하지 않기로 한 건이에요', 'You chose to stop this one', 'ここでやめることにした件です', '这一单您已决定不再继续');
  String get dgWaivedBody => _w('마음이 바뀌면 언제든 다시 진행할 수 있어요.', 'If you change your mind, you can continue any time.', '気が変わったら、いつでももう一度進められます。', '如果改变主意，随时可以重新继续。');

  /// 분쟁 신청 · 이의 제기 · 상담 신청서에 붙여 넣을 글
  String disputeSummary(ClaimView c) {
    String money(int minor) => MoneyFormat.formatMinor(minor, c.currency);
    String brief(String text) {
      final one = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      return one.length > 220 ? '${one.substring(0, 217)}...' : one;
    }

    String day(String at) => at.length >= 10 ? at.substring(0, 10) : at;
    final isRefund = c.kind == 'refund';
    final item = c.items.isEmpty ? null : c.items.first;
    final lines = <String>[
      _w('[요청 요약]', '[Request summary]', '[リクエストの要約]', '[申请摘要]'),
      '${_w('쇼핑몰', 'Shop', 'ショップ', '商城')}: ${c.vendor}',
      '${_w('주문번호', 'Order no.', '注文番号', '订单号')}: ${c.orderRef}',
      '${_w('주문일', 'Order date', '注文日', '下单日期')}: ${c.orderedOn}',
      '${_w('상품', 'Item', '商品', '商品')}: ${c.title}${item == null ? '' : ' (${_w('문제 수량 ${item.claimQty} / 주문 수량 ${item.orderedQty}', '${item.claimQty} with a problem / ${item.orderedQty} ordered', '問題のある数量 ${item.claimQty} / 注文数量 ${item.orderedQty}', '有问题的数量 ${item.claimQty} / 订购数量 ${item.orderedQty}')})'}',
      '${_w('요청', 'Request', 'リクエスト', '申请')}: ${cwKind(c.kind)} · ${isRefund ? '' : '$cwItemPrice '}${money(c.claimed)}',
      '${_w('문제', 'Problem', '問題', '问题')}: ${brief(c.issue)}',
      if (c.issueEnglish.trim().isNotEmpty)
        '${_w('문제 (영어)', 'Problem (English)', '問題 (英語)', '问题（英文）')}: ${brief(c.issueEnglish)}',
    ];

    final happened = <({String at, String text})>[
      for (final d in c.drafts)
        if (d.submittedAt != null)
          (at: day(d.submittedAt!), text: _w('쇼핑몰에 메시지 보냄', 'Message sent to the shop', 'ショップにメッセージを送信', '已向商城发送消息')),
      for (final r in c.replies)
        (
          at: day(r.recordedAt),
          text: '${_w('쇼핑몰 답장', 'Reply from the shop', 'ショップからの返信', '商城回复')} (${cwReplyKind(c.kind, r.kind)})${brief(r.summaryKo.isNotEmpty ? r.summaryKo : r.body).isEmpty ? '' : ': ${brief(r.summaryKo.isNotEmpty ? r.summaryKo : r.body)}'}',
        ),
      // 되돌린 기록은 요약에 넣지 않는다
      for (final row in receivedRows(c.ledger))
        if (!row.undone)
          (
            at: day(row.entry.receivedOn),
            text: switch (row.entry.kind) {
              'goods' => _w('교환품 ${row.entry.quantity}개 받음', 'Replacements received: ${row.entry.quantity}', '交換品を${row.entry.quantity}個受け取り', '收到换货 ${row.entry.quantity}件'),
              'repair' => cwRepairEntry,
              _ => '${_w('입금 확인', 'Money received', '入金を確認', '确认到账')} ${money(row.entry.amount)}',
            },
          ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    lines
      ..add('')
      ..add(_w('진행 기록', 'What has happened', 'これまでの記録', '进展记录'));
    if (happened.isEmpty) {
      lines.add(_w('- 아직 기록이 없어요', '- Nothing recorded yet', '- まだ記録がありません', '- 还没有记录'));
    }
    for (final e in happened) {
      lines.add('- ${e.at} · ${e.text}');
    }

    final none = _w('없음', 'None', 'なし', '无');
    lines.add('');
    if (isRefund) {
      lines
        ..add('${_w('쇼핑몰이 약속한 금액', 'Amount the shop promised', 'ショップが約束した金額', '商城承诺的金额')}: ${c.agreed != null ? money(c.agreed!) : none}')
        ..add('${_w('지금까지 받은 돈', 'Received so far', 'これまでに受け取った金額', '目前已收到的金额')}: ${money(c.summary.cash)}');
    } else {
      lines.add(c.kind == 'exchange'
          ? '$cwReceivedQty: ${cwArrived(c)}'
          : '$cwRepairResult: ${cwArrived(c)}');
    }
    lines.add('${_w('보관한 자료', 'Saved files', '保管した資料', '保存的资料')}: ${c.files.isEmpty ? none : c.files.map((f) => f.name).join(', ')}');
    return lines.join('\n');
  }
}
