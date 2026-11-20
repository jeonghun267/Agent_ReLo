import 'package:flutter/material.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/input_rules.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/relo_mascot.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/auth/auth_screen
/// @layer Feature Module — Authentication & Fair-Consent Signup
/// @purpose [법적 안전장치 #6 양식 동의항목 확인, #7 불필요한 개인정보 미수집, #9 다크패턴 방지, #17 만 14세 나이 확인]
///          회원가입 시 모든 체크박스는 기본 미체크(Unchecked) 상태로 시작하며,
///          만 14세 이상 연령 확인(또는 만 14세 미만 법정대리인 동의 절차)을 검증합니다.
///          화면 구성은 DESIGN.md 7절 "로그인 · 회원가입": 말랑이 → 큰 글자 하나 →
///          체험 계정으로 시작(이 화면의 상자는 이것 하나) → 입력칸 → 동의 줄 → 주 버튼 하나.
class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  /// 지금 언어의 문구
  ReloStrings get _s => ReloScope.of(context).strings;

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

  /// 칸마다의 오류 (칸 아래 빨간 글자). 키: name, email, password
  final Map<String, String> _fieldErrors = {};

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) setState(() => _fieldErrors.remove(key));
  }

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
    // 보내기 전에 칸부터 본다. 고칠 것은 그 칸 아래에 알린다.
    final errors = <String, String>{};
    if (_isSignup && _nameCtrl.text.trim().isEmpty) {
      errors['name'] = _s.auErrName;
    }
    if (!InputRules.email(_emailCtrl.text)) {
      errors['email'] = _s.auErrEmail;
    }
    if (_passwordCtrl.text.length < 8) {
      errors['password'] = _s.auErrPassword;
    }
    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    if (_isSignup && !_canSubmitSignup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.auErrConsent),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: ReloMascot(size: 64, hopOnTap: true),
          ),
          const SizedBox(height: 14),
          Text(
            _isSignup ? _s.auTitleSignup : _s.auTitleLogin,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          // [항목 #7] 불필요한 개인정보 미수집 안내
          Text(
            _s.auNoCollect,
            style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
          ),
          const SizedBox(height: 22),

          // 체험 계정으로 바로 시작 (이 화면의 상자는 이것 하나)
          Semantics(
            button: true,
            child: Material(
              color: palette.raised,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _busy ? null : () => _quickDemoLogin(store),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      ReloIconTile(
                        icon: ReloIcons.bolt,
                        color: palette.inset,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _s.auDemo,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _s.auDemoSub,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.subtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(ReloIcons.chevronRight,
                          size: 22, color: palette.subtle),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isSignup) ...[
            ReloTextField(
              label: _s.auName,
              controller: _nameCtrl,
              hint: _s.auNameHint,
              fillColor: palette.raised,
              errorText: _fieldErrors['name'],
              onChanged: (_) => _clearFieldError('name'),
            ),
            const SizedBox(height: 14),
          ],
          ReloTextField(
            label: _s.auEmail,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            fillColor: palette.raised,
            errorText: _fieldErrors['email'],
            onChanged: (_) => _clearFieldError('email'),
          ),
          const SizedBox(height: 14),
          ReloTextField(
            label: _s.auPassword,
            controller: _passwordCtrl,
            obscureText: true,
            hint: _s.auPasswordHint,
            fillColor: palette.raised,
            errorText: _fieldErrors['password'],
            onChanged: (_) => _clearFieldError('password'),
          ),

          // [항목 #6, #9, #17] 회원가입 시 명시적 동의 항목 & 만 14세 연령 확인
          if (_isSignup) ...[
            const SizedBox(height: 24),
            Text(
              _s.cmConsent,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _s.auOptionalNote,
              style: TextStyle(fontSize: 12, color: palette.subtle),
            ),
            const SizedBox(height: 4),
            ReloConsentRow(
              value: _agreePrivacyRequired,
              onChanged: (v) => setState(() => _agreePrivacyRequired = v),
              isRequired: true,
              title: _s.auC1,
              subtitle: _s.auC1Sub,
              onViewDetail: () => store.openLegalDocument('privacy'),
            ),
            ReloConsentRow(
              value: _agreeTermsRequired,
              onChanged: (v) => setState(() => _agreeTermsRequired = v),
              isRequired: true,
              title: _s.auC2,
              subtitle: _s.auC2Sub,
              onViewDetail: () => store.openLegalDocument('terms'),
            ),
            // [항목 #17 아동 나이 확인 절차]
            ReloConsentRow(
              value: _isOver14Required && !_isUnder14Mode,
              onChanged: (v) => setState(() {
                _isOver14Required = v;
                if (v) _isUnder14Mode = false;
              }),
              isRequired: true,
              title: _s.auC3,
              subtitle: _s.auC3Sub,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                // 체크 칸 너비만큼 들여 글자 줄을 맞춘다
                padding: const EdgeInsets.only(left: 30),
                child: ReloTextAction(
                  label: _isUnder14Mode
                      ? _s.auBackToAdult
                      : _s.auUnder14,
                  onTap: () => setState(() {
                    _isUnder14Mode = !_isUnder14Mode;
                    if (_isUnder14Mode) _isOver14Required = false;
                  }),
                ),
              ),
            ),
            if (_isUnder14Mode) ...[
              const SizedBox(height: 8),
              ReloTextField(
                label: _s.auGuardian,
                controller: _guardianNameCtrl,
                hint: _s.auGuardianHint,
                fillColor: palette.raised,
                // 다 채워야 가입 버튼이 켜진다
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              ReloConsentRow(
                value: _guardianVerified,
                onChanged: (v) => setState(() => _guardianVerified = v),
                isRequired: true,
                title: _s.auGuardianConsent,
              ),
            ],
            ReloConsentRow(
              value: _agreeAiOptional,
              onChanged: (v) => setState(() => _agreeAiOptional = v),
              isRequired: false,
              title: _s.auC4,
              subtitle: _s.auC4Sub,
            ),
            // "마감일 알림 · 안내 이메일 수신 동의"가 여기 있었다. 그런 메일은 보내지 않고
            // (마감 알림은 기기의 알림이다), 체크해도 서버에 전해지지 않아서 뺐다.
          ],

          const SizedBox(height: 22),
          ReloButton(
            text: _busy ? _s.auBusy : (_isSignup ? _s.auSignup : _s.auLogin),
            busy: _busy,
            onPressed: _busy || (_isSignup && !_canSubmitSignup)
                ? null
                : () => _submit(store),
          ),
          const SizedBox(height: 6),
          Center(
            child: ReloTextAction(
              label: _isSignup ? _s.auToLogin : _s.auToSignup,
              onTap: () => setState(() {
                _isSignup = !_isSignup;
                _fieldErrors.clear();
              }),
            ),
          ),
        ],
      ),
    );
  }
}
