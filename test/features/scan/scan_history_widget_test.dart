import 'package:ey_invoice_mobile/core/theme/ey_theme_tokens.dart';
import 'package:ey_invoice_mobile/features/scan/controllers/scan_controller.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_draft.dart';
import 'package:ey_invoice_mobile/features/scan/models/scan_supplier_match.dart';
import 'package:ey_invoice_mobile/features/scan/screens/scan_history_screen.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_api_service.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_draft_store.dart';
import 'package:ey_invoice_mobile/features/scan/services/scan_submission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MemoryStore extends ScanDraftStore {
  @override
  Future<void> saveDrafts(List<ScanDraft> drafts) async {}
}

ScanDraft _draft(String name, ScanDraftStatus status) => ScanDraft(
  id: name,
  scannedDocumentId: name,
  documentType: ScanDocumentType.facture,
  imagePath: '',
  serverImageUrl: '',
  rawText: '',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  supplierName: name,
  invoiceNumber: 'INV-2026-123456789',
  invoiceDate: '2026-11-06',
  dueDate: '',
  totalAmount: '1200.000',
  subtotalAmount: '',
  taxAmount: '',
  currency: 'TND',
  confidence: .9,
  status: status,
  fields: [],
  missingFieldKeys: [],
  supplierResolution: ScanSupplierResolution.initial(displayName: name),
);

void main() {
  for (final language in ['fr', 'en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'history $language dark=$dark handles filters at 360px and large text',
        (tester) async {
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = ScanApiService(accessTokenProvider: () => null);
          final controller = ScanController(
            draftStore: _MemoryStore(),
            apiService: api,
            submissionService: ScanSubmissionService(apiService: api),
          );
          addTearDown(controller.dispose);
          await controller.upsertDraft(
            _draft('Supplier-draft', ScanDraftStatus.reviewed),
          );
          await controller.upsertDraft(
            _draft('Supplier-sent', ScanDraftStatus.validated),
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
                home: const Scaffold(body: ScanHistoryScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(ChoiceChip).at(2));
          await tester.pumpAndSettle();
          expect(find.text('Supplier-draft'), findsNothing);
          expect(find.text('Supplier-sent'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Supplier-sent'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
