import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/extracted_field.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';
import '../services/scan_api_service.dart';
import '../services/scan_draft_store.dart';
import '../services/scan_submission_service.dart';
import '../services/scan_field_rules.dart';

class ScanController extends ChangeNotifier {
  ScanController({
    required ScanDraftStore draftStore,
    required ScanApiService apiService,
    required ScanSubmissionService submissionService,
  }) : _draftStore = draftStore,
       _apiService = apiService,
       _submissionService = submissionService;

  final ScanDraftStore _draftStore;
  final ScanApiService _apiService;
  final ScanSubmissionService _submissionService;
  final ImagePicker _picker = ImagePicker();

  final List<ScanDraft> _drafts = <ScanDraft>[];

  bool _isBusy = false;
  bool _isReady = false;
  Timer? _retryTimer;
  int _retrySeconds = 5;
  int _openReviews = 0;
  int? _errorStatusCode;
  String? _errorKey;
  ScanDocumentType _selectedDocumentType = ScanDocumentType.facture;

  List<ScanDraft> get drafts {
    final copy = List<ScanDraft>.from(_drafts);
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  bool get isBusy => _isBusy;
  bool get isReady => _isReady;
  bool get supportsOcr => true;
  Future<Map<String, dynamic>> getExpense(String id) =>
      _apiService.getExpense(id);
  /// ScanTexts key of the last error, translated by ScanTexts.controllerError.
  String? get errorKey => _errorKey;
  bool get hasError => _errorKey != null;
  int? get errorStatusCode => _errorStatusCode;
  int get pendingCount => _drafts
      .where(
        (d) => d.pendingSubmission && d.status != ScanDraftStatus.validated,
      )
      .length;
  ScanDocumentType get selectedDocumentType => _selectedDocumentType;

  ScanDraft? get latestDraft {
    final items = drafts
        .where((draft) => draft.status != ScanDraftStatus.validated)
        .toList();
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  int get reviewedCount =>
      _drafts.where((draft) => draft.status == ScanDraftStatus.reviewed).length;

  int get validatedCount => _drafts
      .where((draft) => draft.status == ScanDraftStatus.validated)
      .length;

  int get extractedCount => _drafts
      .where((draft) => draft.status == ScanDraftStatus.extracted)
      .length;

  void selectDocumentType(ScanDocumentType type) {
    if (_selectedDocumentType == type) {
      return;
    }
    _selectedDocumentType = type;
    notifyListeners();
  }

  Future<void> loadDrafts() async {
    _setBusy(true);
    try {
      final loaded = await _draftStore.loadDrafts();
      _drafts
        ..clear()
        ..addAll(loaded);
      _isReady = true;
    } catch (_) {
      _errorKey = 'error.draftsLoad';
    } finally {
      _setBusy(false);
      _scheduleRetry();
    }
  }

  Future<ScanDraft?> createDraftFromSource(ImageSource source) async {
    if (_isBusy) return null;
    _setBusy(true);
    _errorKey = null;

    try {
      if (source == ImageSource.camera && Platform.isAndroid) {
        final scanner = DocumentScanner(
          options: DocumentScannerOptions(
            documentFormat: DocumentFormat.pdf,
            mode: ScannerMode.full,
            pageLimit: 10,
          ),
        );
        String? scannedPath;
        try {
          final result = await scanner.scanDocument();
          scannedPath = result.pdf?.uri;
        } on PlatformException catch (error) {
          if (error.message == 'Operation cancelled') return null;
          // Unsupported devices keep the existing camera flow.
        } catch (_) {
          // Unsupported devices keep the existing camera flow.
        } finally {
          try {
            await scanner.close();
          } catch (_) {
            // A device without the native scanner still has the camera fallback.
          }
        }
        if (scannedPath != null) {
          final uri = Uri.tryParse(scannedPath);
          return await _importFile(
            XFile(uri?.scheme == 'file' ? uri!.toFilePath() : scannedPath),
          );
        }
      }
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          throw const ScanFlowException('error.camera');
        }
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 92,
      );

      if (pickedFile == null) {
        return null;
      }

      return await _importFile(pickedFile);
    } on ScanApiException catch (error) {
      _errorKey = 'error.retry';
      _errorStatusCode = error.statusCode;
      return null;
    } on ScanFlowException catch (error) {
      _errorKey = error.messageKey;
      return null;
    } catch (_) {
      _errorKey = 'error.scanFailed';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<ScanDraft> _importFile(XFile file) async {
    final storedPath = await _draftStore.persistImportedImage(file);
    final result = await _apiService.uploadScan(
      file: File(storedPath),
      documentType: _selectedDocumentType,
    );
    final draft = _buildDraftFromUpload(storedPath, result);
    await upsertDraft(draft);
    return draft;
  }

  Future<ScanDraft?> importPdf() async {
    if (_isBusy) return null;
    _setBusy(true);
    _errorKey = null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return null;
      return await _importFile(XFile(path));
    } catch (_) {
      _errorKey = 'error.importFailed';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> submitValidatedDraft(ScanDraft draft) async {
    if (_disposed || _isBusy || draft.status == ScanDraftStatus.validated) {
      return null;
    }
    _setBusy(true);
    _errorKey = null;
    _errorStatusCode = null;

    try {
      await upsertDraft(draft.copyWith(pendingSubmission: true));
      final response = await _submissionService.submit(draft);

      final updatedDraft = draft.copyWith(
        updatedAt: DateTime.now(),
        status: ScanDraftStatus.validated,
        backendTransactionId: response.transactionId,
        pendingSubmission: false,
      );
      await upsertDraft(updatedDraft);
      return response.message;
    } on ScanApiException catch (error) {
      _errorKey = 'error.retry';
      _errorStatusCode = error.statusCode;
      final code = error.statusCode;
      if (code != null &&
          code >= 400 &&
          code < 500 &&
          code != 409 &&
          code != 429) {
        await upsertDraft(draft.copyWith(pendingSubmission: false));
      }
      return null;
    } catch (_) {
      _errorKey = 'error.submitFailed';
      return null;
    } finally {
      _setBusy(false);
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed || _openReviews > 0 || _retryTimer?.isActive == true) return;
    if (pendingCount == 0) {
      _retrySeconds = 5;
      return;
    }
    _retryTimer = Timer(Duration(seconds: _retrySeconds), () async {
      if (_disposed) return;
      if (_isBusy) {
        _scheduleRetry();
        return;
      }
      final queued = drafts
          .where(
            (d) => d.pendingSubmission && d.status != ScanDraftStatus.validated,
          )
          .toList();
      if (queued.isEmpty) return;
      _retrySeconds = (_retrySeconds * 2).clamp(5, 240);
      await submitValidatedDraft(queued.first);
    });
  }

  void beginReview() {
    _openReviews++;
    _retryTimer?.cancel();
  }

  void endReview() {
    if (_openReviews > 0) _openReviews--;
    _scheduleRetry();
  }

  Future<ScanDraft> resolveSupplier(
    ScanDraft draft, {
    String? supplierName,
    String? supplierTaxId,
    String? supplierAddress,
    String? supplierIban,
    String? selectedSupplierId,
    bool createIfMissing = false,
  }) async {
    _setBusy(true);
    _errorKey = null;
    try {
      final resolution = draft.supplierResolution;
      final result = await _apiService.matchOrCreateSupplier(
        name: supplierName ?? resolution.displayName,
        taxId: supplierTaxId ?? resolution.taxId,
        address: supplierAddress ?? resolution.address,
        iban: supplierIban ?? resolution.iban,
        selectedSupplierId: selectedSupplierId,
        createIfMissing: createIfMissing,
      );

      final nextResolution = _mergeSupplierResolution(
        current: resolution,
        result: result,
        fallbackName: supplierName ?? resolution.displayName,
        fallbackTaxId: supplierTaxId ?? resolution.taxId,
        fallbackAddress: supplierAddress ?? resolution.address,
        fallbackIban: supplierIban ?? resolution.iban,
      );

      final updatedDraft = draft
          .copyWith(
            updatedAt: DateTime.now(),
            supplierName: nextResolution.displayName,
            supplierResolution: nextResolution,
          )
          .withResolvedSupplier(nextResolution);
      await upsertDraft(updatedDraft);
      return updatedDraft;
    } on ScanApiException catch (error) {
      _errorKey = 'error.retry';
      _errorStatusCode = error.statusCode;
      return draft;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> upsertDraft(ScanDraft draft) async {
    final index = _drafts.indexWhere((item) => item.id == draft.id);
    if (index == -1) {
      _drafts.add(draft);
    } else {
      _drafts[index] = draft;
    }

    await _draftStore.saveDrafts(_drafts);
    if (!_disposed) notifyListeners();
  }

  Future<void> deleteDraft(String id, {bool keepImage = false}) async {
    final index = _drafts.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final draft = _drafts.removeAt(index);
    try {
      await _draftStore.saveDrafts(_drafts);
    } catch (_) {
      _drafts.add(draft);
      rethrow;
    }
    if (!_disposed) notifyListeners();
    if (!keepImage) await _draftStore.deleteImage(draft.imagePath);
  }

  Future<void> purgeDraftImage(ScanDraft draft) =>
      _draftStore.deleteImage(draft.imagePath);

  void clearError() {
    if (_errorKey == null) {
      return;
    }
    _errorKey = null;
    notifyListeners();
  }

  ScanDraft _buildDraftFromUpload(String imagePath, ScanUploadResult result) {
    final normalizedFields = _ensureClassificationFields(
      result.fields,
      result.documentType,
      result.imageQuality,
    );

    final supplierName = _valueOf(result.fields, [
      'supplier_name',
      'merchant_name',
      'issuer_name',
    ]);
    final invoiceNumber = _valueOf(result.fields, [
      'document_number',
      'invoice_number',
      'receipt_number',
      'reference',
      'delivery_note_number',
      'order_reference',
    ]);
    final invoiceDate = _valueOf(result.fields, ['issue_date']);
    final dueDate = _valueOf(result.fields, ['due_date']);
    final totalAmount = _valueOf(result.fields, [
      'total_to_pay',
      'total_ttc',
      'amount',
    ]);
    final subtotalAmount = _valueOf(result.fields, [
      'net_ht',
      'total_ht',
      'brut_ht',
    ]);
    final taxAmount = _valueOf(result.fields, ['total_tva']);
    final currency = _valueOf(result.fields, ['currency']);
    final supplierTaxId = _valueOf(result.fields, [
      'supplier_tax_id',
      'merchant_tax_id',
      'issuer_tax_id',
    ]);
    final supplierAddress = _valueOf(result.fields, [
      'supplier_address',
      'merchant_address',
      'issuer_address',
    ]);
    final supplierIban = _valueOf(result.fields, ['supplier_iban', 'iban']);

    final now = DateTime.now();
    return ScanDraft(
      id: '${result.scannedDocumentId}_${now.millisecondsSinceEpoch}',
      scannedDocumentId: result.scannedDocumentId,
      documentType: result.documentType,
      imagePath: imagePath,
      serverImageUrl: result.imageUrl,
      rawText: result.rawText,
      createdAt: now,
      updatedAt: now,
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      totalAmount: totalAmount,
      subtotalAmount: subtotalAmount,
      taxAmount: taxAmount,
      currency: currency,
      confidence: result.overallConfidence / 100,
      status: ScanDraftStatus.extracted,
      fields: normalizedFields,
      missingFieldKeys: result.missingFields,
      supplierResolution: ScanSupplierResolution.initial(
        displayName: supplierName,
        taxId: supplierTaxId,
        address: supplierAddress,
        iban: supplierIban,
      ),
    );
  }

  List<ExtractedField> _ensureClassificationFields(
    List<ExtractedField> fields,
    ScanDocumentType documentType,
    Map<String, dynamic> imageQuality,
  ) {
    final updated = ScanFieldRules.normalize(documentType, fields);

    final warnings = (imageQuality['warnings'] as List?)
        ?.map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final qualityScore = (imageQuality['score'] as num?)?.toInt();
    if ((warnings?.isNotEmpty ?? false) &&
        !updated.any((field) => field.key == 'image_quality_warning')) {
      updated.insert(
        0,
        ExtractedField(
          key: 'image_quality_warning',
          label: 'image_quality_warning',
          value: warnings!.join(' · '),
          confidence: qualityScore ?? 0,
          requiredField: false,
          requiresReview: true,
        ),
      );
    }

    return updated;
  }

  String _valueOf(List<ExtractedField> fields, List<String> keys) {
    for (final key in keys) {
      final match = fields.where((field) => field.key == key);
      if (match.isNotEmpty) {
        return match.first.value;
      }
    }
    return '';
  }

  void _setBusy(bool value) {
    _isBusy = value;
    if (value) _errorStatusCode = null;
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    super.dispose();
  }

  ScanSupplierResolution _mergeSupplierResolution({
    required ScanSupplierResolution current,
    required SupplierMatchResult result,
    required String? fallbackName,
    required String? fallbackTaxId,
    required String? fallbackAddress,
    required String? fallbackIban,
  }) {
    final displayName = (result.displayName?.trim().isNotEmpty ?? false)
        ? result.displayName!.trim()
        : (fallbackName?.trim().isNotEmpty ?? false)
        ? fallbackName!.trim()
        : current.displayName;
    final taxId = (result.taxId?.trim().isNotEmpty ?? false)
        ? result.taxId!.trim()
        : fallbackTaxId != null
        ? fallbackTaxId.trim()
        : current.taxId;

    final status = result.created
        ? ScanSupplierStatus.created
        : result.autoSelected
        ? ScanSupplierStatus.autoMatched
        : result.candidates.isNotEmpty
        ? ScanSupplierStatus.needsChoice
        : result.matched
        ? ScanSupplierStatus.confirmed
        : ScanSupplierStatus.notFound;

    return ScanSupplierResolution(
      status: status,
      displayName: displayName,
      supplierId: result.supplierId,
      taxId: taxId,
      address: fallbackAddress ?? current.address,
      iban: fallbackIban ?? current.iban,
      note: null,
      candidates: result.candidates,
    );
  }
}

class ScanFlowException implements Exception {
  const ScanFlowException(this.messageKey);

  /// ScanTexts key describing the failure.
  final String messageKey;

  @override
  String toString() => messageKey;
}
