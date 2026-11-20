import 'package:flutter/material.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../state/relo_store.dart';
import 'relo_primitives.dart';

/// @module shared/widgets/ai_consent_sheet
/// @purpose AI에 무언가를 보내기 전에 계정의 AI 동의가 있는지 본다. 없으면 무엇이 어디로
///          가는지(해외의 Google AI)를 아래 시트로 알리고, 동의했을 때만 true를 돌려준다.
///          "AI에게 맡기기" · "스스로 시작하기 켜기" · 신청의 "AI가 채우기"가 같이 쓴다.
///          안내 글은 홈 · 도우미의 동의 카드와 같은 문장이다.
Future<bool> ensureAiConsent(BuildContext context) async {
  final store = ReloScope.of(context);
  if (store.user == null) return false;
  if (store.user!.aiConsentAt != null) return true;

  final s = store.strings;
  final p = ReloPalette.of(context);
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.canvas,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.assistantConsentTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.assistantConsentBody,
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              ReloButton(
                text: s.assistantConsentButton,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: 4),
              Center(
                child: ReloMutedAction(
                  label: s.agNotNow,
                  onTap: () => Navigator.pop(sheetContext, false),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (agreed != true) return false;
  await store.toggleAiConsent();
  return store.user?.aiConsentAt != null;
}
