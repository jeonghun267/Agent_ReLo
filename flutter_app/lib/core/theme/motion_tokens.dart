import 'package:flutter/animation.dart';

/// @module core/theme/motion_tokens
/// @purpose 앱 전체에서 쓰는 움직임 시간과 곡선. 값의 근거는 DESIGN.md 5절.
class ReloMotion {
  ReloMotion._();

  /// 앱 시작 연출 전체 길이 (로고 고리 → 헤더 이동 → 홈 등장)
  static const Duration intro = Duration(milliseconds: 900);

  /// 탭 전환 (FadeThrough)
  static const Duration tabSwitch = Duration(milliseconds: 250);

  /// 신청 단계 전환 (SharedAxis 가로)
  static const Duration wizardStep = Duration(milliseconds: 300);

  /// 목록 카드 → 상세 (OpenContainer)
  static const Duration openContainer = Duration(milliseconds: 350);

  /// 목록 카드 등장
  static const Duration listItem = Duration(milliseconds: 320);
  static const Duration listStagger = Duration(milliseconds: 40);

  /// 버튼 누름
  static const Duration press = Duration(milliseconds: 100);
  static const double pressScale = 0.97;

  /// 숫자 올라가기
  static const Duration ticker = Duration(milliseconds: 600);

  /// 아래 시트
  static const Duration sheet = Duration(milliseconds: 300);

  /// 축하 효과
  static const Duration celebrate = Duration(milliseconds: 1400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;
}
