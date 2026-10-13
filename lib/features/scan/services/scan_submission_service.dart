import '../models/scan_draft.dart';
import 'scan_api_service.dart';

class ScanSubmissionService {
  const ScanSubmissionService({required ScanApiService apiService})
    : _apiService = apiService;

  final ScanApiService _apiService;

  Future<ValidateScanResult> submit(ScanDraft draft) {
    final supplier = draft.supplierResolution;
    return _apiService.validateScan(
      scannedDocumentId: draft.scannedDocumentId,
      documentType: draft.documentType,
      fields: draft.fields,
      supplierId: supplier.supplierId,
      supplierName: supplier.displayName.isEmpty ? draft.supplierName : supplier.displayName,
      supplierTaxId: supplier.taxId,
      supplierAddress: supplier.address,
      supplierIban: supplier.iban,
    );
  }
}
