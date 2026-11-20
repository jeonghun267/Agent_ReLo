// Plain-text bodies of the account emails. Pure: values in, {to, subject, text} out.

export function verifyEmailMessage({to, name, link, hours}) {
  return {
    to,
    subject: '[ReLo] 이메일 주소를 인증해 주세요',
    text: [
      `${name}님, ReLo에 가입해 주셔서 고마워요.`,
      '',
      '아래 링크를 열면 이메일 인증이 끝나요.',
      link,
      '',
      `이 링크는 ${hours}시간 동안 한 번만 쓸 수 있어요.`,
      '직접 가입하지 않았다면 이 메일은 무시해도 돼요.',
    ].join('\n'),
  };
}

// The agent started by itself and has been waiting for the person's answer. The email says only
// that an answer is awaited and where to give it: nothing from the claim (no store, no item, no
// amount) is put into it, so nothing new about the order leaves through the mail service.
const AGENT_WAITING = {
  ko: {
    subject: '[ReLo] AI가 물어볼 것이 있어요',
    lines: (name, link) => [
      `${name}님, 신청하신 건 하나에서 AI가 한 가지를 하기 전에 허락을 기다리고 있어요.`,
      '',
      '아래 링크에서 무엇을 하려는지 보고, 허락할지 하지 않을지 골라 주세요.',
      link,
      '',
      '답하기 전에는 아무것도 바뀌지 않고, AI는 쇼핑몰에 아무것도 보내지 않아요.',
      '이 메일은 [스스로 시작하기]를 켜 두셔서 보냈어요. 메일만 그만 받으려면 설정에서 알림 메일을 끄세요.',
    ],
  },
  en: {
    subject: '[ReLo] The AI has a question for you',
    lines: (name, link) => [
      `${name}, on one of your requests the AI is waiting for your OK before it does one thing.`,
      '',
      'Open the link below to see what it wants to do, then allow it or not.',
      link,
      '',
      'Until you answer, nothing changes, and the AI sends nothing to the store.',
      'You are getting this email because "Let the AI start on its own" is on. To stop only these emails, turn notice emails off in Settings.',
    ],
  },
  ja: {
    subject: '[ReLo] AIから確認したいことがあります',
    lines: (name, link) => [
      `${name}さん、申請された件のひとつで、AIがあることをする前に許可を待っています。`,
      '',
      '下のリンクで内容を確認して、許可するかどうかを選んでください。',
      link,
      '',
      '答えるまで何も変わらず、AIがショップに何かを送ることもありません。',
      'このメールは「AIが自分で始める」がオンのためお送りしました。メールだけを止めるには、設定でお知らせメールをオフにしてください。',
    ],
  },
  zh: {
    subject: '[ReLo] AI 有事想问你',
    lines: (name, link) => [
      `${name}，在你的一项申请中，AI 在做一件事之前正在等你同意。`,
      '',
      '请打开下面的链接查看它想做什么，然后选择允许或不允许。',
      link,
      '',
      '在你回答之前，什么都不会改变，AI 也不会向店铺发送任何内容。',
      '因为你打开了“让 AI 自己开始”，所以收到这封邮件。只想停止这类邮件时，请在设置中关闭提醒邮件。',
    ],
  },
};

export function agentWaitingMessage({to, name, link, locale}) {
  const words = AGENT_WAITING[locale] ?? AGENT_WAITING.ko;
  return {to, subject: words.subject, text: words.lines(name, link).join('\n')};
}

export function resetPasswordMessage({to, name, link, minutes}) {
  return {
    to,
    subject: '[ReLo] 비밀번호 재설정 링크',
    text: [
      `${name}님, 비밀번호 재설정을 요청하셨어요.`,
      '',
      '아래 링크를 열어 새 비밀번호를 정하세요.',
      link,
      '',
      `이 링크는 ${minutes}분 동안 한 번만 쓸 수 있어요. 비밀번호를 바꾸면 모든 기기에서 로그아웃돼요.`,
      '직접 요청하지 않았다면 이 메일은 무시하세요. 비밀번호는 바뀌지 않아요.',
    ].join('\n'),
  };
}
