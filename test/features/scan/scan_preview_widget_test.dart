import 'package:ey_invoice_mobile/core/theme/ey_theme_tokens.dart';
import 'package:ey_invoice_mobile/features/scan/controllers/scan_controller.dart';
import 'package:ey_invoice_mobile/features/scan/models/extracted_field.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:ey_invoice_mobile/features/scan/screens/scan_preview_screen.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_api_service.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_draft_store.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_submission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in ['fr', 'en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'preview layout $language dark=$dark at 360px and 130% text',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = ScanApiService(accessTokenProvider: () => null);
          final controller = ScanController(
            draftStore: ScanDraftStore(accountKey: 'test'),
            apiService: api,
            submissionService: ScanSubmissionService(apiService: api),
          );
          addTearDown(controller.dispose);
          final now = DateTime(2026, 11, 6);
          final draft = ScanDraft(
            id: 'test',
            scannedDocumentId: 'server',
            documentType: ScanDocumentType.bonSortie,
            imagePath: 'missing.jpg',
            serverImageUrl: '',
            rawText: '',
            createdAt: now,
            updatedAt: now,
            supplierName: '',
            invoiceNumber: 'B1',
            invoiceDate: '',
            dueDate: '',
            totalAmount: '',
            subtotalAmount: '',
            taxAmount: '',
            currency: 'TND',
            confidence: .8,
            status: ScanDraftStatus.extracted,
            fields: const [
              ExtractedField(
                key: 'document_number',
                label: 'Référence',
                value: 'B1',
                confidence: 40,
                requiredField: true,
                requiresReview: true,
              ),
            ],
            missingFieldKeys: [],
            supplierResolution: ScanSupplierResolution.initial(displayName: ''),
          );
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: controller,
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [
                  Locale('fr'),
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                  extensions: [dark ? EyThemeTokens.dark : EyThemeTokens.light],
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: ScanPreviewScreen(initialDraft: draft, isNewDraft: false),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byType(TextFormField),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.enterText(find.byType(TextFormField).last, 'B-UPDATED');
          await tester.pump(const Duration(milliseconds: 1000));
          await tester.pumpAndSettle();
          expect(controller.drafts.single.invoiceNumber, 'B-UPDATED');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
