import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ReloStore();
  runApp(ReloFlutterApp(store: store));
}

/// @module main
/// @layer Application Root (Feature-First Architecture + 20-Point Legal Compliance)
/// @purpose Flutter_localizations 다국어 SDK 통합, 고대비(WCAG AAA) 테마,
///          키보드 네비게이션(Alt+1~5, Tab/Enter), 5탭 기능별 화면 라우팅을 총괄합니다.
class ReloFlutterApp extends StatelessWidget {
  final ReloStore store;

  const ReloFlutterApp({super.key, required this.store});

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
            home: const _ReloMainNavigation(),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
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
