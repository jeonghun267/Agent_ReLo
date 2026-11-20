import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// @module shared/widgets/relo_icons
/// @purpose 앱의 아이콘은 모두 여기서 가져온다 (DESIGN.md 3절 "아이콘").
///          한 가지 선 아이콘(Lucide)만 쓰고, 속을 채운 아이콘이나 다른 모음의 아이콘과 섞지 않는다.
///          화면에서는 `Icons.*`를 직접 쓰지 않고, 무엇을 뜻하는지로 지은 이 이름을 쓴다.
///          같은 뜻이면 어느 화면에서든 같은 그림이 나온다 (지우기는 늘 [trash], 환불 건은 늘 [package]).
abstract final class ReloIcons {
  // ── 이동 ──
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData forward = LucideIcons.arrowRight;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData menu = LucideIcons.menu;
  static const IconData close = LucideIcons.x;

  // ── 하단 탭 (켜진 칸도 같은 그림, 색만 진해진다) ──
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData receipt = LucideIcons.receiptText;
  static const IconData person = LucideIcons.user;

  // ── 하는 일 ──
  static const IconData send = LucideIcons.arrowUp;
  static const IconData add = LucideIcons.plus;
  static const IconData search = LucideIcons.search;
  static const IconData history = LucideIcons.history;
  static const IconData copy = LucideIcons.copy;
  static const IconData trash = LucideIcons.trash2;
  static const IconData check = LucideIcons.check;
  static const IconData translate = LucideIcons.languages;
  static const IconData compare = LucideIcons.arrowLeftRight;
  static const IconData newChat = LucideIcons.messageSquarePlus;
  static const IconData write = LucideIcons.squarePen;

  /// AI에게 맡기기 (에이전트)
  static const IconData agent = LucideIcons.bot;

  // ── 물건 · 상태 ──
  static const IconData package = LucideIcons.package;
  static const IconData document = LucideIcons.fileText;
  static const IconData image = LucideIcons.image;
  static const IconData truck = LucideIcons.truck;
  static const IconData mail = LucideIcons.mail;
  static const IconData chats = LucideIcons.messagesSquare;
  static const IconData clock = LucideIcons.clock;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData lock = LucideIcons.lock;
  static const IconData bolt = LucideIcons.zap;
  static const IconData block = LucideIcons.ban;
  static const IconData cookie = LucideIcons.cookie;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData camera = LucideIcons.camera;
  static const IconData folder = LucideIcons.folderOpen;
}
