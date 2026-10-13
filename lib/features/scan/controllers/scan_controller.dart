import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/extracted_field.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';
import '../services/scan_api_service.dart';
import '../services/scan_draft_store.dart';
import '../services/scan_submission_service.dart';

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
  String? _errorMessage;
  ScanDocumentType _selectedDocumentType = ScanDocumentType.facture;

  List<ScanDraft> get drafts {
    final copy = List<ScanDraft>.from(_drafts);
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  bool get isBusy => _isBusy;
  bool get isReady => _isReady;
  bool get supportsOcr => true;
  String? get errorMessage => _errorMessage;
  ScanDocumentType get selectedDocumentType => _selectedDocumentType;

  ScanDraft? get latestDraft {
    final items = drafts;
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
      _errorMessage = 'Impossible de charger les brouillons.';
    } finally {
      _setBusy(false);
    }
  }

  Future<ScanDraft?> createDraftFromSource(ImageSource source) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          throw const ScanFlowException(
            'Autorise la caméra pour lancer le scan.',
          );
        }
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: source == ImageSource.gallery ? 1600 : 2200,
        imageQuality: source == ImageSource.gallery ? 75 : 92,
      );

      if (pickedFile == null) {
        return null;
      }

      final storedPath = await _draftStore.persistImportedImage(pickedFile);
      final uploadResult = await _apiService.uploadScan(
        file: File(storedPath),
        documentType: _selectedDocumentType,
      );
      return _buildDraftFromUpload(storedPath, uploadResult);
    } on ScanApiException catch (error) {
      _errorMessage = error.message;
      return null;
    } on ScanFlowException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Le scan a échoué. Réessaie avec une image plus nette.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> submitValidatedDraft(ScanDraft draft) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      final response = await _submissionService.submit(draft);

      final updatedDraft = draft.copyWith(
        updatedAt: DateTime.now(),
        status: ScanDraftStatus.validated,
        backendTransactionId: response.transactionId,
      );
      await upsertDraft(updatedDraft);
      return response.message;
    } on ScanApiException catch (error) {
      _errorMessage = error.message;
      return null;
    } finally {
      _setBusy(false);
    }
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
    _errorMessage = null;
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

      final updatedDraft = draft.copyWith(
        updatedAt: DateTime.now(),
        supplierName: nextResolution.displayName,
        supplierResolution: nextResolution,
      );
      await upsertDraft(updatedDraft);
      return updatedDraft;
    } on ScanApiException catch (error) {
      _errorMessage = error.message;
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
    notifyListeners();
  }

  Future<void> deleteDraft(String id) async {
    final index = _drafts.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final draft = _drafts.removeAt(index);
    await _draftStore.deleteImage(draft.imagePath);
    await _draftStore.saveDrafts(_drafts);
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
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
    final updated = <ExtractedField>[...fields];

    void ensureRequired({required String key, required String label}) {
      if (updated.any((field) => field.key == key)) {
        return;
      }

      updated.insert(
        0,
        ExtractedField(
          key: key,
          label: label,
          value: '',
          confidence: 0,
          requiredField: true,
          requiresReview: true,
        ),
      );
    }

    ensureRequired(key: 'trade_sense', label: 'Achat / Vente');
    ensureRequired(key: 'payment_status', label: 'Statut paiement');

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
          label: 'Qualité image',
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
    notifyListeners();
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
        : (fallbackTaxId?.trim().isNotEmpty ?? false)
        ? fallbackTaxId!.trim()
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
  const ScanFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}
