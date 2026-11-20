import 'relo_i18n.dart';

/// @module core/i18n/relo_i18n_agent
/// @layer Core Localization (KO / EN / JA / ZH)
/// @purpose "AI에게 맡기기"(에이전트) · "스스로 시작하기" · 신청의 "AI가 채우기"에 쓰는 문구.
///          사전(`relo_i18n.dart`)이 길어서 이 묶음만 따로 두고, 사전에서 다시 내보낸다
///          (화면은 전과 같이 `store.strings.ag...`로 쓴다). 말은 웹의 같은 화면과 맞춘다.
extension ReloAgentStrings on ReloStrings {
  String _a(String ko, String en, String ja, String zh) => switch (locale) {
        ReloLocale.ko => ko,
        ReloLocale.en => en,
        ReloLocale.ja => ja,
        ReloLocale.zh => zh,
      };

  // ── 상세: AI에게 맡기기 ──────────────────────────────────────────────
  String get agTitle => _a('AI에게 맡기기', 'Hand it to the AI', 'AIに任せる', '交给 AI');
  String get agAgain =>
      _a('다시 맡기기', 'Hand it over again', 'もう一度任せる', '再交给 AI 一次');
  String get agGoalLabel => _a('목표', 'Goal', '目標', '目标');

  /// 목표 한 줄. 환불은 받을 돈([amount])을 적고, 교환 · 수리는 받을 것을 적는다.
  String agGoal(String kind, String amount) => switch (kind) {
        'exchange' =>
          _a('교환품 받기', 'Get a replacement', '交換品を受け取る', '收到换货'),
        'repair' => _a('수리 받기', 'Get it repaired', '修理してもらう', '完成维修'),
        _ => _a(
            '$amount 환불 받기',
            'Get a refund of $amount',
            '$amount の返金を受ける',
            '拿到 $amount 的退款',
          ),
      };

  String get agIdle => _a(
        '이 목표까지 지금 할 수 있는 일을 AI가 이 건의 상태를 보고 골라서 해요. 자료 읽기 · 답장 풀기 · 글 쓰기는 바로 하고, 내용을 고치거나 저장하는 일은 먼저 물어봐요. 쇼핑몰에 보내는 일은 하지 않아요.',
        'The AI looks at where this case stands and does what it can toward this goal. It reads files, explains replies and writes the message right away, and asks you first before it changes or saves anything. It never sends anything to the shop.',
        'この目標に向けて今できることを、AIがこの件の状態を見て選び、実行します。ファイルを読む・返信を読み解く・文章を書くはすぐに行い、内容の修正や保存は先に確認します。ショップへの送信はしません。',
        '为了这个目标，AI 会根据这件事的状态选择现在能做的事并执行。读取文件、解读回复、撰写留言会直接做；修改或保存内容之前会先问你。不会向商城发送任何内容。',
      );
  String agRunning(int n) => _a(
        'AI가 무엇을 할지 고르면서 최대 $n단계까지 하고 있어요. 조금 걸릴 수 있어요…',
        'The AI is choosing and doing what it can, up to $n steps. This can take a little while…',
        'AIが何をするかを選びながら、最大$nステップまで進めています。少し時間がかかることがあります…',
        'AI 正在选择并执行，最多 $n 步。可能需要一点时间…',
      );
  String get agAutoRunning => _a(
        '일이 생겨서 AI가 스스로 살펴보고 있어요. 조금 걸릴 수 있어요…',
        'Something happened on this case, so the AI is looking into it on its own. This can take a little while…',
        '動きがあったので、AIが自分で確認しています。少し時間がかかることがあります…',
        '有了新情况，AI 正在自己查看。可能需要一点时间…',
      );
  String get agResultTitle =>
      _a('AI가 한 일', 'What the AI did', 'AIがしたこと', 'AI 做了什么');

  String agTool(String tool) => switch (tool) {
        'read_evidence' => _a(
            '올린 자료 읽기',
            'Read an uploaded file',
            'アップロードしたファイルを読む',
            '读取上传的文件',
          ),
        'analyze_reply' => _a(
            '쇼핑몰 답장 풀기',
            'Explain the shop\'s reply',
            'ショップの返信を読み解く',
            '解读商城回复',
          ),
        'write_draft' =>
          _a('보낼 글 쓰기', 'Write the message', '送る文章を書く', '撰写留言'),
        'fix_order_facts' => _a(
            '주문 정보를 자료대로 고치기',
            'Correct the order details to match the file',
            '注文情報をファイルに合わせて直す',
            '按文件修改订单信息',
          ),
        'save_draft' => _a(
            '쓴 글을 이 건에 저장하기',
            'Save the message to this case',
            '書いた文章をこの件に保存する',
            '把写好的留言保存到这件事',
          ),
        _ => tool,
      };

  String get agApprovalTitle =>
      _a('허락이 필요해요', 'Your OK is needed', '許可が必要です', '需要你的同意');
  String get agApprovalIntro => _a(
        'AI가 이 일을 하려고 해요. 허락하면 그때 해요.',
        'The AI wants to do this. It happens only if you allow it.',
        'AIがこれを実行しようとしています。許可したときだけ実行します。',
        'AI 想做这件事。只有你同意后才会执行。',
      );
  String agChangeLine(String field, String from, String to) =>
      '${agField(field)}: $from → $to';
  String agFixNote(String file) => _a(
        '자료 “$file”에서 읽은 값이에요. 맞는지 자료와 견줘 보세요.',
        'These values were read from “$file”. Check them against the file.',
        'ファイル「$file」から読んだ値です。ファイルと照らして確認してください。',
        '这些是从文件“$file”读到的值，请对照文件确认。',
      );
  String get agDraftNote => _a(
        '아래 글이 새 버전으로 저장돼요. 쇼핑몰에 보내는 일은 직접 해야 해요.',
        'The message below will be saved as a new version. Sending it to the shop is still up to you.',
        '下の文章が新しい版として保存されます。ショップへの送信は自分で行います。',
        '下面的留言会保存为新版本。向商城发送仍需你自己来做。',
      );
  String get agApprove => _a('허락하기', 'Allow', '許可する', '同意');
  String get agDecline => _a('하지 않기', 'Don\'t', 'しない', '不做');

  String get agDecidedApproved => _a(
        '허락해서 했어요.',
        'You allowed it, so it was done.',
        '許可したので実行しました。',
        '你同意了，已执行。',
      );
  String get agDecidedDeclined => _a(
        '허락하지 않아서 그대로 뒀어요.',
        'You did not allow it, so nothing was changed.',
        '許可しなかったので、何も変えていません。',
        '你没有同意，所以没有改动。',
      );
  String get agDecidedFailed => _a(
        '허락했지만 하지 못했어요.',
        'You allowed it, but it could not be done.',
        '許可しましたが、実行できませんでした。',
        '你同意了，但没能执行。',
      );

  String agLast(String date, String steps) => _a(
        '지난번($date)에 한 일: $steps',
        'Last time ($date): $steps',
        '前回（$date）にしたこと：$steps',
        '上一次（$date）做的事：$steps',
      );
  String get agLastSaid => _a(
        '그때 AI가 한 말:',
        'What the AI said then:',
        'そのときAIが伝えたこと：',
        '当时 AI 说的话：',
      );
  String get agLastApproved => _a('허락함', 'allowed', '許可', '已同意');
  String get agLastDeclined =>
      _a('허락하지 않음', 'not allowed', '許可せず', '未同意');
  String get agWhy =>
      _a('고른 까닭:', 'Why it chose this:', '選んだ理由：', '选择的理由：');

  String agField(String field) => switch (field) {
        'vendor' => _a('쇼핑몰', 'Shop', 'ショップ', '商城'),
        'orderRef' => _a('주문번호', 'Order number', '注文番号', '订单号'),
        'orderedOn' => _a('주문일', 'Order date', '注文日', '下单日期'),
        'currency' => _a('통화', 'Currency', '通貨', '货币'),
        'total' => _a('합계', 'Total', '合計', '合计'),
        _ => field,
      };

  String get agMismatchTitle => _a(
        '저장된 내용과 달라요. 어느 쪽이 맞는지 확인해 주세요.',
        'This differs from what is saved. Please check which one is right.',
        '保存されている内容と違います。どちらが正しいか確認してください。',
        '与已保存的内容不一致，请确认哪一个是对的。',
      );
  String agMismatchLine(String field, String saved, String read) => _a(
        '${agField(field)}: 저장된 값 $saved · 자료에서 읽은 값 $read',
        '${agField(field)}: saved $saved · read from the file $read',
        '${agField(field)}：保存された値 $saved · ファイルから読んだ値 $read',
        '${agField(field)}：已保存 $saved · 从文件读到 $read',
      );
  String get agNoMismatch => _a(
        '저장된 주문번호 · 주문일 · 통화와 같아요.',
        'Same as the saved order number, date and currency.',
        '保存された注文番号・注文日・通貨と同じです。',
        '与已保存的订单号、下单日期和货币一致。',
      );
  String get agReplyKind => _a(
        'AI가 본 답장 종류:',
        'Kind of reply, as the AI read it:',
        'AIが読み取った返信の種類：',
        'AI 判断的回复类型：',
      );
  String agMentioned(String amount) => _a(
        '답장에 적힌 금액: $amount',
        'Amount stated in the reply: $amount',
        '返信に書かれた金額：$amount',
        '回复中提到的金额：$amount',
      );
  String agDeadline(String date) => _a(
        '답장에 적힌 기한: $date',
        'Deadline stated in the reply: $date',
        '返信に書かれた期限：$date',
        '回复中提到的期限：$date',
      );
  String get agUseDraft => _a(
        '이 글을 메시지 칸에 넣기',
        'Put this in the message box',
        'この文章をメッセージ欄に入れる',
        '把这段文字放进留言框',
      );
  String get agDraftUsed => _a(
        '메시지 칸에 넣었어요. 읽어 보고 저장해 주세요.',
        'It is in the message box. Read it and save it.',
        'メッセージ欄に入れました。読んでから保存してください。',
        '已放进留言框，请阅读后保存。',
      );
  String get agStepFailed => _a(
        '이 단계는 하지 못했어요.',
        'This step could not be done.',
        'このステップは実行できませんでした。',
        '这一步没能完成。',
      );

  String agEnded(String endedBy, int n) => switch (endedBy) {
        'max_steps' => _a(
            '정해 둔 $n단계까지 살펴봤어요. 다음은 직접 판단해 주세요.',
            'It looked through the $n steps it is allowed. The next call is yours.',
            '決められた$nステップまで確認しました。この先は自分で判断してください。',
            '已查看规定的 $n 步，接下来请自己判断。',
          ),
        'repeat' => _a(
            'AI가 같은 일을 다시 고르려고 해서 멈췄어요.',
            'The AI was about to choose the same thing again, so it was stopped.',
            'AIが同じことをもう一度選ぼうとしたため、止めました。',
            'AI 想再次选择同一件事，所以停下了。',
          ),
        'invalid_choice' => _a(
            'AI가 할 수 없는 일을 골라서 멈췄어요.',
            'The AI chose something it cannot do, so it was stopped.',
            'AIができないことを選んだため、止めました。',
            'AI 选择了做不了的事，所以停下了。',
          ),
        'rate_limited' => _a(
            '한 시간에 쓸 수 있는 횟수를 다 써서 멈췄어요.',
            'It stopped because the hourly limit was used up.',
            '1時間に使える回数を使い切ったため、止まりました。',
            '一小时内可用的次数已用完，所以停下了。',
          ),
        'plan_failed' => _a(
            'AI가 다음 일을 고르지 못해서 멈췄어요.',
            'It stopped because the AI could not choose a next step.',
            'AIが次にすることを選べなかったため、止まりました。',
            'AI 没能选出下一步，所以停下了。',
          ),
        _ => _a(
            'AI가 여기까지 하고 멈췄어요.',
            'The AI stopped here.',
            'AIはここまで実行して止まりました。',
            'AI 做到这里就停下了。',
          ),
      };
  String get agNextTitle => _a(
        '다음에 내가 할 일',
        'What you do next',
        '次に自分ですること',
        '接下来我要做的事',
      );
  String agNote(int n) => _a(
        'AI가 고르고 만든 내용이에요. 틀릴 수 있으니 직접 확인해 주세요. AI는 허락받은 것만 저장했고, 쇼핑몰에는 아무것도 보내지 않았어요. (AI 호출 $n번)',
        'The AI chose and made all of this, and it can be wrong, so check it yourself. The AI saved only what you allowed and sent nothing to the shop. ($n AI calls)',
        'AIが選び、作った内容です。間違っていることがあるので、自分で確認してください。AIは許可されたものだけを保存し、ショップには何も送信していません。（AI呼び出し $n回）',
        '以上内容由 AI 选择并生成，可能有误，请自己确认。AI 只保存了你同意的内容，没有向商城发送任何内容。（AI 调用 $n 次）',
      );
  String get agFailed => _a(
        'AI가 하지 못했어요. 잠시 뒤 다시 해 주세요.',
        'The AI could not do it. Please try again shortly.',
        'AIが実行できませんでした。少ししてからもう一度お試しください。',
        'AI 没能完成，请稍后再试。',
      );
  String get agDecisionFailed => _a(
        '답을 전하지 못했어요. 다시 눌러 주세요.',
        'Your answer did not get through. Please press again.',
        '返事を伝えられませんでした。もう一度押してください。',
        '没能传达你的回答，请再按一次。',
      );

  /// 버튼 없이 시작한 실행이 무엇 때문에 시작했는지. 사람이 누른 실행은 빈 글.
  String agStartedBy(String startedBy) => switch (startedBy) {
        'filed' => _a(
            '신청이 접수돼서 AI가 스스로 시작했어요.',
            'You filed the request, so the AI started on its own.',
            '申請が登録されたので、AIが自分で始めました。',
            '申请已登记，AI 自己开始了。',
          ),
        'file' => _a(
            '자료가 올라와서 AI가 스스로 시작했어요.',
            'A file was added, so the AI started on its own.',
            '資料が追加されたので、AIが自分で始めました。',
            '添加了资料，AI 自己开始了。',
          ),
        'reply' => _a(
            '쇼핑몰 답장이 저장돼서 AI가 스스로 시작했어요.',
            'A reply from the shop was saved, so the AI started on its own.',
            'ショップの返信が保存されたので、AIが自分で始めました。',
            '保存了店铺的回复，AI 自己开始了。',
          ),
        _ => '',
      };

  // ── 상세 · 목록의 한 줄 ──────────────────────────────────────────────
  String get agAsks => _a(
        'AI가 물어볼 것이 있어요',
        'The AI has a question for you',
        'AIから確認したいことがあります',
        'AI 有事要问你',
      );
  String get agRowWorking => _a(
        'AI가 살펴보고 있어요…',
        'The AI is looking into it…',
        'AIが確認しています…',
        'AI 正在查看…',
      );

  // ── 스스로 시작하기 ─────────────────────────────────────────────────
  String get agAutoOffNote => _a(
        '켜 두면 신청하거나, 자료를 올리거나, 답장을 저장했을 때 AI가 스스로 시작해요. 그때 이 건의 내용과 올려 둔 자료가 Google의 AI로 보내져요. 고치거나 저장하는 일은 그때도 먼저 물어봐요. 허락을 기다리는데 한동안 답이 없으면, 인증해 둔 이메일로 한 번 알려 드려요.',
        'Turn this on and the AI starts on its own when you file a request, add a file or save a reply. The details of this case and the files you added are then sent to Google\'s AI. It still asks you first before it changes or saves anything. If it is left waiting for your OK for a while, it emails you once at your verified address.',
        'オンにすると、申請したとき・資料を追加したとき・返信を保存したときにAIが自分で始めます。そのとき、この件の内容と追加した資料がGoogleのAIに送られます。内容を直したり保存したりする前には、そのときも必ず確認します。許可を待ったまましばらくお返事がないときは、確認済みのメールアドレスに一度だけお知らせします。',
        '打开后，在你提交申请、添加资料或保存回复时，AI 会自己开始。那时这件事的内容和你添加的资料会发送给 Google 的 AI。修改或保存内容之前，仍然会先问你。如果等你同意等了一段时间仍没有回答，会向你已验证的邮箱发一封提醒邮件。',
      );
  String get agAutoOnNote => _a(
        '스스로 시작하기가 켜져 있어요. 신청하거나, 자료를 올리거나, 답장을 저장하면 AI가 알아서 살펴보고, 허락이 필요한 일은 여기서 기다려요.',
        'Starting on its own is on. When you file a request, add a file or save a reply, the AI looks into it by itself, and anything that needs your OK waits here.',
        '「自分で始める」がオンです。申請・資料の追加・返信の保存があるとAIが自分で確認し、許可が必要なことはここで待ちます。',
        '“自己开始”已打开。提交申请、添加资料或保存回复后，AI 会自己查看，需要你同意的事会在这里等你。',
      );
  String get agAutoTurnOn => _a(
        '스스로 시작하기 켜기',
        'Let it start on its own',
        '自分で始めるをオンにする',
        '打开“自己开始”',
      );
  String get agAutoTurnOff => _a('끄기', 'Turn off', 'オフにする', '关闭');
  String get agAutoToastOn => _a(
        '켰어요. 이제 일이 생기면 AI가 스스로 시작해요.',
        'On. The AI now starts on its own when something happens.',
        'オンにしました。動きがあるとAIが自分で始めます。',
        '已打开。有新情况时 AI 会自己开始。',
      );
  String get agAutoToastOff => _a(
        '껐어요. 이제 버튼을 눌러야 시작해요.',
        'Off. It now starts only when you press the button.',
        'オフにしました。ボタンを押したときだけ始めます。',
        '已关闭。现在只有按下按钮才会开始。',
      );
  String get agAutoToastFail => _a(
        '바꾸지 못했어요. 다시 눌러 주세요.',
        'Could not change it. Please press again.',
        '変更できませんでした。もう一度押してください。',
        '没能更改，请再按一次。',
      );
  String get agAutoHeldBack => _a(
        '이번 시간에 쓸 수 있는 AI 횟수가 얼마 남지 않아서 스스로 시작하지 않았어요. 필요하면 아래 버튼으로 직접 맡겨 주세요.',
        'Only a few AI uses are left for this hour, so the AI did not start on its own. If you need it, hand it over yourself with the button below.',
        'この1時間に使えるAIの回数が残りわずかなため、自分では始めませんでした。必要なときは下のボタンで任せてください。',
        '这一小时可用的 AI 次数所剩不多，所以 AI 没有自己开始。需要的话，请用下面的按钮交给它。',
      );

  /// 설정의 켜고 끄는 줄
  // 답장 상자: 저장한 답장(직접 읽고 저장한 것)과, AI가 요약 · 번역했다는 표시
  String get dSavedReply => _a('저장한 답장', 'Saved reply', '保存した返信', '已保存的回复');
  String get dAiMadeNote => _a(
        'AI가 요약하고 옮긴 내용이에요. 틀릴 수 있으니 원문과 견주어 보세요.',
        'Summarized and translated by AI. It can be wrong, so check it against the original.',
        'AIが要約・翻訳した内容です。間違っていることがあるので、原文と見比べてください。',
        '这是 AI 总结和翻译的内容，可能有误，请对照原文确认。',
      );

  // 신청을 마쳤는데 서버가 받지 못한 파일이 있을 때
  String wFilesNotSaved(int n) => _a(
        '신청은 저장했지만 파일 $n개는 올리지 못했어요. 이 건을 열어 다시 올려 주세요.',
        'Your request is saved, but $n file(s) could not be uploaded. Open the request and add them again.',
        '申請は保存しましたが、ファイル$n件を追加できませんでした。この件を開いて、もう一度追加してください。',
        '申请已保存，但有 $n 个文件没能上传。请打开这项申请重新添加。',
      );

  String get stAgentAuto => _a(
        'AI가 스스로 시작하기',
        'Let the AI start on its own',
        'AIが自分で始める',
        '让 AI 自己开始',
      );
  String get stAgentAutoSub => _a(
        '신청하거나, 자료를 올리거나, 답장을 저장하면 AI가 버튼 없이 시작해요. 그때 그 건의 내용과 자료가 Google의 AI로 보내져요. 고치거나 저장하는 일은 먼저 물어봐요. 한동안 답이 없으면 인증해 둔 이메일로 한 번 알려 드려요',
        'The AI starts without a button when you file a request, add a file or save a reply. The details and files of that case are then sent to Google\'s AI. It asks you first before it changes or saves anything. If it is left waiting for a while, it emails you once at your verified address',
        '申請・資料の追加・返信の保存があると、AIがボタンなしで始めます。そのとき、その件の内容と資料がGoogleのAIに送られます。直したり保存したりする前に必ず確認します。しばらくお返事がないときは、確認済みのメールアドレスに一度だけお知らせします',
        '提交申请、添加资料或保存回复后，AI 会不用按钮自己开始。那时该事项的内容和资料会发送给 Google 的 AI。修改或保存之前会先问你。等了一段时间仍没有回答时，会向你已验证的邮箱发一封提醒邮件',
      );

  /// AI 동의를 묻는 아래 시트에서 그만둘 때
  String get agNotNow => _a('다음에 하기', 'Not now', '今はしない', '以后再说');

  // ── 신청 1단계: AI가 채우기 ──────────────────────────────────────────
  String get wIntakeTitle => _a(
        'AI가 채워 주기',
        'Let the AI fill it in',
        'AIに入力してもらう',
        '让 AI 来填',
      );
  String get wIntakeBody => _a(
        '주문서나 영수증을 고르고 무슨 일인지 한 줄만 적어 보세요. 나머지 칸은 AI가 채우고, 확인만 하면 돼요.',
        'Choose your order confirmation or receipt and say what happened in one line. The AI fills in the rest and you only check it.',
        '注文書や領収書を選んで、何があったかを一行だけ書いてください。残りの欄はAIが入力し、あなたは確認するだけです。',
        '选择订单或小票，再用一句话写下发生了什么。其余的由 AI 填写，你只需要确认。',
      );
  String get wIntakeLineLabel =>
      _a('무슨 일인가요?', 'What happened?', '何がありましたか？', '发生了什么？');
  String get wIntakeLineHint => _a(
        '예: 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.',
        'e.g. One of the two does not power on. I would like a refund.',
        '例：2個のうち1個の電源が入りません。返金してほしいです。',
        '例如：两个中有一个不通电，想要退款。',
      );
  String get wIntakeFile => _a(
        '주문서 · 영수증 고르기',
        'Choose order or receipt',
        '注文書・領収書を選ぶ',
        '选择订单或小票',
      );
  String get wIntakeFileChange => _a(
        '다른 파일로 바꾸기',
        'Choose another file',
        '別のファイルに変える',
        '换一个文件',
      );
  String get wIntakeRun => _a('AI가 채우기', 'Fill it in', 'AIが入力する', '让 AI 填写');
  String get wIntakeReading => _a(
        '주문서를 읽고, 적은 내용과 맞춰 보는 중…',
        'Reading your order and matching it with what you wrote…',
        '注文書を読み取り、書いた内容と照らし合わせています…',
        '正在读取订单，并和你写的内容对照…',
      );
  String get wIntakeNeedInput => _a(
        '주문서를 고르거나 무슨 일인지 적어 주세요.',
        'Choose your order or say what happened.',
        '注文書を選ぶか、何があったかを書いてください。',
        '请选择订单，或写下发生了什么。',
      );
  String get wIntakeFileAttached => _a(
        '파일을 붙였어요. [AI가 채우기]를 누르면 AI가 읽어요.',
        'File attached. Press [Fill it in] and the AI reads it.',
        'ファイルを添付しました。［AIが入力する］を押すとAIが読み取ります。',
        '文件已添加。按下［让 AI 填写］后 AI 才会读取。',
      );
  String get wIntakePartly => _a(
        '읽은 만큼 채웠어요. 나머지 칸을 채워 주세요.',
        'Filled in what could be read. Please complete the rest.',
        '読み取れた分だけ入力しました。残りの欄を入力してください。',
        '已按读到的内容填写，请补全其余内容。',
      );
  String get wIntakeLineOnly => _a(
        '적은 내용으로 해결 방법과 문제 설명을 채웠어요. 주문 정보는 직접 적어 주세요.',
        'Filled in the remedy and the problem from what you wrote. Please enter the order details yourself.',
        '書いた内容から解決方法と問題の説明を入力しました。注文情報は自分で入力してください。',
        '已根据你写的内容填写解决方式和问题说明。订单信息请自己填写。',
      );
  String get wIntakeAiNote => _a(
        'AI가 채운 값이에요. 맞는지 확인해 주세요.',
        'These values were filled in by the AI. Please check them.',
        'AIが入力した値です。正しいか確認してください。',
        '这些是 AI 填写的，请确认是否正确。',
      );
  String get wIntakeUnderstood => _a(
        'AI가 이렇게 이해했어요:',
        'How the AI read it:',
        'AIはこう理解しました：',
        'AI 是这样理解的：',
      );
  String get wIntakeReviewNote => _a(
        'AI가 주문서와 적은 내용으로 채웠어요. 틀린 곳이 있으면 이전으로 가서 고쳐 주세요.',
        'The AI filled this in from your order and what you wrote. If something is wrong, go back and fix it.',
        'AIが注文書と書いた内容から入力しました。違うところがあれば前に戻って直してください。',
        'AI 根据订单和你写的内容填写了这些。如有不对，请返回上一步修改。',
      );
  String get wSumKind => _a('해결 방법', 'Remedy', '解決方法', '解决方式');
  String get wSumIssue =>
      _a('적은 문제', 'The problem you described', '入力した問題', '你写的问题');
}
