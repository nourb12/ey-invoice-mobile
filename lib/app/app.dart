import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/l10n/language_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/controllers/session_controller.dart';
import '../features/auth/services/auth_api_service.dart';
import '../features/invoices/controllers/invoices_controller.dart';
import '../features/invoices/services/invoice_api_service.dart';
import '../features/scan/controllers/scan_controller.dart';
import '../features/scan/services/scan_api_service.dart';
import '../features/scan/services/scan_draft_store.dart';
import '../features/scan/services/scan_submission_service.dart';
import 'splash_gate.dart';

class EyInvoiceMobileApp extends StatelessWidget {
  const EyInvoiceMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController()..load(),
          lazy: false,
        ),
        ChangeNotifierProvider<LanguageController>(
          create: (_) => LanguageController()..load(),
          lazy: false,
        ),
        ChangeNotifierProvider<SessionController>(
          create: (_) =>
              SessionController(apiService: AuthApiService())..bootstrap(),
          lazy: false,
        ),
        ChangeNotifierProvider<InvoicesController>(
          create: (context) => InvoicesController(
            apiService: InvoiceApiService(
              accessTokenProvider: () =>
                  context.read<SessionController>().session?.accessToken,
            ),
          ),
          lazy: true,
        ),
      ],
      child: _ScanAccountScope(
        child: Consumer2<ThemeController, LanguageController>(
          builder: (context, themeController, languageController, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'EY Invoice Mobile',
              locale: languageController.locale,
              supportedLocales: LanguageController.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection: LanguageController.textDirectionFor(
                    languageController.languageCode,
                  ),
                  child: child!,
                );
              },
              themeMode: themeController.themeMode,
              theme: AppTheme.light(
                languageCode: languageController.languageCode,
              ),
              darkTheme: AppTheme.dark(
                languageCode: languageController.languageCode,
              ),
              home: const SplashGate(),
            );
          },
        ),
      ),
    );
  }
}

/// Rebuild the signed-in navigation and its drafts when the account changes.
class _ScanAccountScope extends StatelessWidget {
  const _ScanAccountScope({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().session;
    final user = session?.utilisateur;
    final account = user == null
        ? 'signed-out'
        : '${user.entrepriseId}:${user.id}';
    return ChangeNotifierProvider<ScanController>(
      key: ValueKey(account),
      lazy: false,
      create: (context) {
        final sessions = context.read<SessionController>();
        final api = ScanApiService(
          accessTokenProvider: () {
            final current = sessions.session;
            return current?.utilisateur.id == user?.id &&
                    current?.utilisateur.entrepriseId == user?.entrepriseId
                ? current?.accessToken
                : null;
          },
        );
        return ScanController(
          draftStore: ScanDraftStore(accountKey: account),
          apiService: api,
          submissionService: ScanSubmissionService(apiService: api),
        )..loadDrafts();
      },
      child: child,
    );
  }
}
