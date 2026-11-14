import 'package:flutter/material.dart';

import '../../core/attachments/evidence_picker.dart';
import '../../core/attachments/evidence_rules.dart';
import '../../core/theme/relo_theme.dart';
import '../state/relo_store.dart';
import 'relo_icons.dart';

/// @module shared/widgets/evidence_source_sheet
/// @purpose 영수증 · 사진을 붙이는 한 가지 길. 아래에서 올라오는 시트에서
///          "사진 찍기 · 사진첩에서 고르기 · 파일에서 고르기"를 고르면 기기의 화면이 열리고,
///          고른 파일은 손본 뒤(종류 확인 · 촬영 위치 지우기 · 10MB 확인) 돌려준다.
///          올릴 수 없는 파일이면 까닭을 아래 알림 한 줄로 말하고 null을 돌려준다.
///          신청 4단계 · 신청 1단계 "영수증으로 채우기" · 상세의 기록 탭이 함께 쓴다.

/// 시트 맨 아래에 붙이는 덧붙임 줄 (예: "샘플 영수증으로 해 보기")
typedef EvidenceSheetExtra = ({String label, VoidCallback onTap});

Future<PickedEvidence?> pickEvidenceWithSheet(
  BuildContext context, {
  EvidenceSheetExtra? extra,
}) async {
  final store = ReloScope.of(context);
  final s = store.strings;
  final p = ReloPalette.of(context);
  final messenger = ScaffoldMessenger.of(context);

  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  if (!store.evidencePicker.isSupported && extra == null) {
    say(s.evUnavailable);
    return null;
  }

  final sources = store.evidencePicker.isSupported
      ? [
          (source: EvidenceSource.camera, icon: ReloIcons.camera, label: s.evCamera),
          (source: EvidenceSource.photo, icon: ReloIcons.image, label: s.evPhoto),
          (source: EvidenceSource.file, icon: ReloIcons.folder, label: s.evFile),
        ]
      : const <({EvidenceSource source, IconData icon, String label})>[];

  final choice = await showModalBottomSheet<EvidenceSource>(
    context: context,
    backgroundColor: p.canvas,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                s.evSheetTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                store.evidencePicker.isSupported ? s.evNote : s.evUnavailable,
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.4),
              ),
            ),
            for (final item in sources)
              ListTile(
                leading: Icon(item.icon, color: p.muted),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, item.source),
              ),
            if (extra != null)
              ListTile(
                leading: Icon(ReloIcons.receipt, color: p.subtle),
                title: Text(
                  extra.label,
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  extra.onTap();
                },
              ),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return null;

  try {
    return await store.evidencePicker.pick(choice);
  } on EvidenceException catch (e) {
    say(s.evProblem(e.problem));
    return null;
  } catch (_) {
    say(s.evUnreadable);
    return null;
  }
}
