import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/motion_tokens.dart';
import 'core/theme/relo_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/claims/claim_detail_screen.dart';
import 'features/claims/my_claims_screen.dart';
import 'features/compliance/legal_center_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/wizard/wizard_screen.dart';
import 'shared/state/relo_store.dart';
import 'shared/widgets/relo_app_shell.dart';
import 'shared/widgets/relo_intro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ReloStore();
  runApp(ReloFlutterApp(store: store));
}

/// @module main
/// @layer Application Root
/// @purpose 다국어(KO/EN/JA/ZH), 다크·라이트·고대비 테마, 키보드 이동(Alt+1~5),
///          탭 화면 라우팅과 시작 연출을 맡는다.
///          탭 번호: 0 홈 · 1 신청 · 2 내 환불(상세 포함) · 3 약관·정책 · 4 설정
class ReloFlutterApp extends StatelessWidget {
  final ReloStore store;

  /// 테스트나 스크린샷에서 시작 연출을 건너뛸 때 false
  final bool showIntro;

  const ReloFlutterApp({super.key, required this.store, this.showIntro = true});

  @override
  Widget build(BuildContext context) {
    return ReloScope(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return MaterialApp(
            title: 'ReLo — 해외직구 반품·교환·환불 통장',
            debugShowCheckedModeBanner: false,
            theme: ReloAppTheme.light(),
            darkTheme: ReloAppTheme.dark(highContrast: store.isHighContrast),
            themeMode: store.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(store.locale.code),
            supportedLocales: const [
              Locale('ko'),
              Locale('en'),
              Locale('ja'),
              Locale('zh'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: showIntro
                ? const ReloIntro(child: _ReloMainNavigation())
                : const _ReloMainNavigation(),
          );
        },
      ),
    );
  }
}

class _ReloMainNavigation extends StatelessWidget {
  const _ReloMainNavigation();

  void _openAuthModal(BuildContext context) {
    final palette = ReloPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AuthScreen(
          onSuccess: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);

    Widget activeBody;
    switch (store.activeTabIndex) {
      case 0:
        activeBody = const HomeScreen();
        break;
      case 1:
        activeBody = const WizardScreen();
        break;
      case 2:
        if (store.selectedClaimId != null) {
          activeBody = ClaimDetailScreen(claimId: store.selectedClaimId!);
        } else {
          activeBody = const MyClaimsScreen();
        }
        break;
      case 3:
        activeBody = const LegalCenterScreen();
        break;
      case 4:
        activeBody = const SettingsScreen();
        break;
      default:
        activeBody = const HomeScreen();
    }

    return ReloAppShell(
      onUserTap: () {
        if (store.user == null) {
          _openAuthModal(context);
        } else {
          store.navigateToTab(4);
        }
      },
      // 이전 화면이 사라진 뒤 새 화면이 나타난다 (두 화면이 겹쳐 보이지 않게)
      body: PageTransitionSwitcher(
        duration: ReloMotion.tabSwitch,
        transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
          animation: primary,
          secondaryAnimation: secondary,
          fillColor: Colors.transparent,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey<String>(
            'tab_${store.activeTabIndex}_claim_${store.selectedClaimId ?? "none"}_doc_${store.activeLegalDocId}',
          ),
          child: activeBody,
        ),
      ),
    );
  }
}
