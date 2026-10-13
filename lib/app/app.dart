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
        ChangeNotifierProvider<ScanController>(
          create: (context) {
            final apiService = ScanApiService(
              accessTokenProvider: () =>
                  context.read<SessionController>().session?.accessToken,
            );
            return ScanController(
              draftStore: ScanDraftStore(),
              apiService: apiService,
              submissionService: ScanSubmissionService(apiService: apiService),
            )..loadDrafts();
          },
          lazy: false,
        ),
      ],
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
            // Force LTR layout for all languages (including Arabic)
            // This keeps the visual structure consistent - only text changes
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: child!,
              );
            },
            themeMode: themeController.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}
