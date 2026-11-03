import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_orb_emblem.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/auth/auth_screen
/// @layer Feature Module — Authentication & Fair-Consent Signup
/// @purpose [법적 안전장치 #6 양식 동의항목 확인, #7 불필요한 개인정보 미수집, #9 다크패턴 방지, #17 만 14세 나이 확인]
///          회원가입 시 모든 체크박스는 기본 미체크(Unchecked) 상태로 시작하며,
///          만 14세 이상 연령 확인(또는 만 14세 미만 법정대리인 동의 절차)을 검증합니다.
class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignup = false;
  bool _busy = false;
  final _nameCtrl = TextEditingController(text: '김직구');
  final _emailCtrl = TextEditingController(text: 'demo@relo.local');
  final _passwordCtrl = TextEditingController(text: 'relo-demo-2026');

  // [항목 #6, #9, #17] 회원가입 양식 필수/선택 동의 상태 (기본 미체크 원칙)
  bool _agreePrivacyRequired = false;
  bool _agreeTermsRequired = false;
  bool _isOver14Required = false;
  bool _isUnder14Mode = false;
  bool _guardianVerified = false;
  final _guardianNameCtrl = TextEditingController();
  bool _agreeAiOptional = false;
  bool _agreeEmailOptional = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _guardianNameCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmitSignup {
    if (!_agreePrivacyRequired || !_agreeTermsRequired) return false;
    if (_isUnder14Mode) {
      return _guardianVerified && _guardianNameCtrl.text.trim().isNotEmpty;
    }
    return _isOver14Required;
  }

  Future<void> _submit(ReloStore store) async {
    if (_isSignup && !_canSubmitSignup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관 동의 및 연령 확인 항목을 체크해 주세요.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    String message;
    if (_isSignup) {
      message = await store.signup(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        aiConsented: _agreeAiOptional,
        marketingEmailConsented: _agreeEmailOptional,
      );
    } else {
      message = await store.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    widget.onSuccess?.call();
  }

  Future<void> _quickDemoLogin(ReloStore store) async {
    setState(() => _busy = true);
    final demo = store.config.demoAccount;
    final msg = await store.login(
      demo?.email ?? 'demo@relo.local',
      demo?.password ?? 'relo-demo-2026',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ReloCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ReloOrbEmblem(size: 64)),
            const SizedBox(height: 14),
            Text(
              _isSignup ? '내 전용 환불 보관함 만들기' : '내 환불 보관함 열기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: palette.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '주민등록번호·집 주소·카드 전체 번호 등 불필요한 개인정보는 절대 수집하지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: palette.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // 1클릭 체험 계정 즉시 시작 배너
            GestureDetector(
              onTap: _busy ? null : () => _quickDemoLogin(store),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.brandLine),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: palette.brandHover,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '비밀번호 입력 없이 체험 계정으로 바로 시작',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            'Amazon · AliExpress · Mercari 샘플 환불 건이 준비되어 있어요',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.brandHover,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isSignup) ...[
              ReloTextField(
                label: '이름 또는 닉네임 (실명 강제 없음)',
                controller: _nameCtrl,
                hint: '김직구',
              ),
              const SizedBox(height: 12),
            ],
            ReloTextField(
              label: '이메일 주소',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              hint: 'you@example.com',
            ),
            const SizedBox(height: 12),
            ReloTextField(
              label: '비밀번호',
              controller: _passwordCtrl,
              obscureText: true,
              hint: '8자 이상 비밀번호',
            ),

            // [항목 #6, #9, #17] 회원가입 시 명시적 동의 항목 & 만 14세 연령 확인
            if (_isSignup) ...[
              const SizedBox(height: 16),
              Text(
                '약관 및 개인정보 수집 동의 (선택 항목 미동의 시에도 가입 가능)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              ReloConsentCheckbox(
                value: _agreePrivacyRequired,
                onChanged: (v) => setState(() => _agreePrivacyRequired = v),
                isRequired: true,
                title: '개인정보 수집 및 이용 동의',
                subtitle: '수집항목: 이메일, 닉네임, 암호화 비밀번호 (탈퇴 시 즉시 파기)',
                onViewDetail: () => store.openLegalDocument('privacy'),
              ),
              ReloConsentCheckbox(
                value: _agreeTermsRequired,
                onChanged: (v) => setState(() => _agreeTermsRequired = v),
                isRequired: true,
                title: '서비스 이용약관 동의',
                subtitle: '직구 환불 기록 및 외국어 초안 작성 도구 이용 기준',
                onViewDetail: () => store.openLegalDocument('terms'),
              ),
              // [항목 #17 아동 나이 확인 절차]
              ReloConsentCheckbox(
                value: _isOver14Required && !_isUnder14Mode,
                onChanged: (v) => setState(() {
                  _isOver14Required = v;
                  if (v) _isUnder14Mode = false;
                }),
                isRequired: true,
                title: '만 14세 이상 본인입니다 (연령 확인)',
                subtitle: '개인정보보호법 제22조의2에 따른 필수 연령 확인 절차',
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _isUnder14Mode = !_isUnder14Mode;
                  if (_isUnder14Mode) _isOver14Required = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    _isUnder14Mode
                        ? '▲ 만 14세 이상 일반 가입으로 돌아가기'
                        : '▶ 만 14세 미만 아동인가요? 법정대리인(부모) 동의 절차 열기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.brandHover,
                    ),
                  ),
                ),
              ),
              if (_isUnder14Mode) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.sunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '만 14세 미만 아동 법정대리인(부모) 동의 확인',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ReloTextField(
                        label: '법정대리인(보호자) 성명 및 연락 이메일',
                        controller: _guardianNameCtrl,
                        hint: '예: 홍길동 (parent@example.com)',
                      ),
                      const SizedBox(height: 8),
                      ReloConsentCheckbox(
                        value: _guardianVerified,
                        onChanged: (v) =>
                            setState(() => _guardianVerified = v),
                        isRequired: true,
                        title: '법정대리인 본인이 아동의 개인정보 수집·이용에 동의합니다.',
                      ),
                    ],
                  ),
                ),
              ],
              ReloConsentCheckbox(
                value: _agreeAiOptional,
                onChanged: (v) => setState(() => _agreeAiOptional = v),
                isRequired: false,
                title: 'AI 영수증 자동 읽기 및 외국어 번역 도우미 사용 동의',
                subtitle: '미동의 시에도 직접 입력 및 기본 템플릿을 100% 이용할 수 있어요.',
              ),
              ReloConsentCheckbox(
                value: _agreeEmailOptional,
                onChanged: (v) => setState(() => _agreeEmailOptional = v),
                isRequired: false,
                title: '환불 마감일 알림 및 안내 이메일 수신 동의',
                subtitle: '언제든 메일 하단 또는 설정에서 원클릭으로 수신거부할 수 있어요.',
              ),
            ],

            const SizedBox(height: 16),
            ReloButton(
              text: _busy
                  ? '처리 중...'
                  : (_isSignup ? '동의하고 내 전용 보관함 만들기' : '로그인하기'),
              onPressed: _busy || (_isSignup && !_canSubmitSignup)
                  ? null
                  : () => _submit(store),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _isSignup = !_isSignup),
              child: Text(
                _isSignup
                    ? '이미 보관함이 있으신가요? 로그인하기'
                    : '처음 오셨나요? 약관 확인 후 새 보관함 만들기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
