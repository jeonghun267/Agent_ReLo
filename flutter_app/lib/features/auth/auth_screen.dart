import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
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
            _isSignup ? '내 환불 보관함 만들기' : '내 환불 보관함 열기',
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
            '주민등록번호·집 주소·카드 전체 번호는 받지 않아요.',
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
                              '체험 계정으로 바로 시작',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '비밀번호 없이 샘플 환불 건으로 둘러봐요',
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
              label: '이름 또는 닉네임 (실명이 아니어도 돼요)',
              controller: _nameCtrl,
              hint: '김직구',
              fillColor: palette.raised,
            ),
            const SizedBox(height: 14),
          ],
          ReloTextField(
            label: '이메일 주소',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            fillColor: palette.raised,
          ),
          const SizedBox(height: 14),
          ReloTextField(
            label: '비밀번호',
            controller: _passwordCtrl,
            obscureText: true,
            hint: '8자 이상 비밀번호',
            fillColor: palette.raised,
          ),

          // [항목 #6, #9, #17] 회원가입 시 명시적 동의 항목 & 만 14세 연령 확인
          if (_isSignup) ...[
            const SizedBox(height: 24),
            Text(
              '동의',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '선택 항목은 동의하지 않아도 가입할 수 있어요.',
              style: TextStyle(fontSize: 12, color: palette.subtle),
            ),
            const SizedBox(height: 4),
            ReloConsentRow(
              value: _agreePrivacyRequired,
              onChanged: (v) => setState(() => _agreePrivacyRequired = v),
              isRequired: true,
              title: '개인정보 수집 및 이용 동의',
              subtitle: '수집항목: 이메일, 닉네임, 암호화 비밀번호 (탈퇴 시 즉시 파기)',
              onViewDetail: () => store.openLegalDocument('privacy'),
            ),
            ReloConsentRow(
              value: _agreeTermsRequired,
              onChanged: (v) => setState(() => _agreeTermsRequired = v),
              isRequired: true,
              title: '서비스 이용약관 동의',
              subtitle: '직구 환불 기록 및 외국어 초안 작성 도구 이용 기준',
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
              title: '만 14세 이상 본인입니다 (연령 확인)',
              subtitle: '개인정보보호법 제22조의2에 따른 필수 연령 확인 절차',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                // 체크 칸 너비만큼 들여 글자 줄을 맞춘다
                padding: const EdgeInsets.only(left: 30),
                child: ReloTextAction(
                  label: _isUnder14Mode
                      ? '만 14세 이상 일반 가입으로 돌아가기'
                      : '만 14세 미만이면 보호자 동의로 가입하기',
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
                label: '법정대리인(보호자) 성명 및 연락 이메일',
                controller: _guardianNameCtrl,
                hint: '예: 홍길동 (parent@example.com)',
                fillColor: palette.raised,
                // 다 채워야 가입 버튼이 켜진다
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              ReloConsentRow(
                value: _guardianVerified,
                onChanged: (v) => setState(() => _guardianVerified = v),
                isRequired: true,
                title: '법정대리인 본인이 아동의 개인정보 수집·이용에 동의합니다.',
              ),
            ],
            ReloConsentRow(
              value: _agreeAiOptional,
              onChanged: (v) => setState(() => _agreeAiOptional = v),
              isRequired: false,
              title: 'AI 영수증 자동 읽기 및 외국어 번역 도우미 사용 동의',
              subtitle: '미동의 시에도 직접 입력 및 기본 템플릿을 100% 이용할 수 있어요.',
            ),
            ReloConsentRow(
              value: _agreeEmailOptional,
              onChanged: (v) => setState(() => _agreeEmailOptional = v),
              isRequired: false,
              title: '환불 마감일 알림 및 안내 이메일 수신 동의',
              subtitle: '언제든 메일 하단 또는 설정에서 원클릭으로 수신거부할 수 있어요.',
            ),
          ],

          const SizedBox(height: 22),
          ReloButton(
            text: _busy ? '처리 중…' : (_isSignup ? '동의하고 가입하기' : '로그인하기'),
            onPressed: _busy || (_isSignup && !_canSubmitSignup)
                ? null
                : () => _submit(store),
          ),
          const SizedBox(height: 6),
          Center(
            child: ReloTextAction(
              label: _isSignup ? '이미 보관함이 있어요 · 로그인' : '처음이에요 · 보관함 만들기',
              onTap: () => setState(() => _isSignup = !_isSignup),
            ),
          ),
        ],
      ),
    );
  }
}
