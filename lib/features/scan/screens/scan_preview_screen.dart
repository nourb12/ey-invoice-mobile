import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../l10n/scan_texts.dart';
import '../models/extracted_field.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';
import '../widgets/supplier_match_bottom_sheet.dart';
import 'scan_success_screen.dart';

class ScanPreviewScreen extends StatefulWidget {
  const ScanPreviewScreen({
    super.key,
    required this.initialDraft,
    required this.isNewDraft,
  });

  final ScanDraft initialDraft;
  final bool isNewDraft;

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  late ScanDraft _draft;
  bool _isSaving = false;
  bool _isResolvingSupplier = false;
  bool _autoSupplierAttempted = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _syncControllers(_draft.fields);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeResolveSupplier(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<ExtractedField> fields) {
    for (final field in fields) {
      final controller = _controllers[field.key];
      if (controller == null) {
        _controllers[field.key] = TextEditingController(text: field.value);
      } else if (controller.text != field.value) {
        controller.text = field.value;
      }
    }
  }

  List<ExtractedField> get _updatedFields {
    return _draft.fields.map((field) {
      final value = _controllers[field.key]?.text.trim() ?? '';
      final isMissing = value.isEmpty && field.requiredField;
      return field.copyWith(
        value: value,
        requiresReview: isMissing ? true : false,
      );
    }).toList();
  }

  bool get _requiresSupplierConfirmation {
    return switch (_draft.documentType) {
      ScanDocumentType.facture => true,
      ScanDocumentType.proforma => true,
      ScanDocumentType.avoir => true,
      ScanDocumentType.devis => true,
      ScanDocumentType.bonCommande => true,
      ScanDocumentType.bonLivraison => true,
      ScanDocumentType.paiementEmis => true,
      _ => false,
    };
  }

  bool get _hasBlockingFields {
    final hasRequiredFieldMissing = _updatedFields.any(
      (field) => field.requiredField && field.value.trim().isEmpty,
    );
    if (hasRequiredFieldMissing) {
      return true;
    }
    if (_requiresSupplierConfirmation) {
      return !_draft.supplierResolution.isResolved;
    }
    return false;
  }

  Future<void> _showAddFieldDialog() async {
    final titleController = TextEditingController();
    final valueController = TextEditingController();

    try {
      final field = await showDialog<ExtractedField>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ajouter un champ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Titre du champ',
                  hintText: 'Ex. Chauffeur, Camion, Cachet',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                  hintText: 'Valeur lue sur le papier',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final label = titleController.text.trim();
                final value = valueController.text.trim();
                if (label.isEmpty || value.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  ExtractedField(
                    key: _customFieldKey(label),
                    label: label,
                    value: value,
                    confidence: 100,
                    requiredField: false,
                    requiresReview: false,
                  ),
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );

      if (field == null || !mounted) {
        return;
      }

      setState(() {
        _controllers[field.key] = TextEditingController(text: field.value);
        _draft = _draft.copyWith(
          fields: [..._draft.fields, field],
          status: ScanDraftStatus.reviewed,
          updatedAt: DateTime.now(),
        );
      });
    } finally {
      titleController.dispose();
      valueController.dispose();
    }
  }

  String _customFieldKey(String label) {
    final slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safeSlug = slug.isEmpty ? 'champ' : slug;
    return 'custom_${safeSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _maybeResolveSupplier() async {
    if (_autoSupplierAttempted) {
      return;
    }
    _autoSupplierAttempted = true;

    if (!_requiresSupplierConfirmation) {
      return;
    }

    final name = _currentSupplierName();
    final taxId = _currentSupplierTaxId();
    if (name.isEmpty && taxId.isEmpty) {
      return;
    }

    setState(() => _isResolvingSupplier = true);
    final updated = await context.read<ScanController>().resolveSupplier(
      _buildDraft(_draft.status),
      supplierName: name,
      supplierTaxId: taxId.isEmpty ? null : taxId,
      supplierAddress: _currentSupplierAddress(),
      supplierIban: _currentSupplierIban(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isResolvingSupplier = false;
      _draft = updated;
    });
    _syncControllers(_draft.fields);
  }

  Future<void> _saveDraft(ScanDraftStatus status) async {
    setState(() => _isSaving = true);
    final draft = _buildDraft(status);
    await context.read<ScanController>().upsertDraft(draft);
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Future<void> _submitDraft() async {
    final texts = ScanTexts.of(context);
    if (_hasBlockingFields) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.t('preview.blocking'))));
      return;
    }

    setState(() => _isSaving = true);
    final reviewedDraft = _buildDraft(ScanDraftStatus.reviewed);
    final message = await context.read<ScanController>().submitValidatedDraft(
      reviewedDraft,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    final controller = context.read<ScanController>();
    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      controller.clearError();
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<ScanSuccessAction>(
        builder: (_) => ScanSuccessScreen(
          message: message ?? texts.t('preview.successBody'),
        ),
      ),
    );
  }

  Future<void> _openSupplierBottomSheet() async {
    final draft = _buildDraft(_draft.status);
    final result = await showModalBottomSheet<ScanDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: SupplierMatchBottomSheet(
          controller: context.read<ScanController>(),
          draft: draft,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _draft = result);
    _syncControllers(_draft.fields);
  }

  void _openImageViewer(File imageFile) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5,
                  child: Image.file(imageFile, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ScanDraft _buildDraft(ScanDraftStatus status) {
    final updatedFields = _updatedFields;

    String valueOf(List<String> keys) {
      for (final key in keys) {
        final match = updatedFields.where((field) => field.key == key);
        if (match.isNotEmpty) {
          return match.first.value;
        }
      }
      return '';
    }

    final supplierName = valueOf([
      'supplier_name',
      'merchant_name',
      'issuer_name',
    ]);
    final supplierTaxId = valueOf([
      'supplier_tax_id',
      'merchant_tax_id',
      'issuer_tax_id',
    ]);
    final supplierAddress = valueOf([
      'supplier_address',
      'merchant_address',
      'issuer_address',
    ]);
    final supplierIban = valueOf(['supplier_iban', 'iban']);

    final nextResolution = _draft.supplierResolution.copyWith(
      displayName: supplierName.isNotEmpty
          ? supplierName
          : _draft.supplierResolution.displayName,
      taxId: supplierTaxId.isNotEmpty
          ? supplierTaxId
          : _draft.supplierResolution.taxId,
      address: supplierAddress.isNotEmpty
          ? supplierAddress
          : _draft.supplierResolution.address,
      iban: supplierIban.isNotEmpty
          ? supplierIban
          : _draft.supplierResolution.iban,
    );

    return _draft.copyWith(
      supplierName: supplierName,
      invoiceNumber: valueOf([
        'invoice_number',
        'receipt_number',
        'reference',
        'delivery_note_number',
      ]),
      invoiceDate: valueOf(['issue_date']),
      dueDate: valueOf(['due_date']),
      totalAmount: valueOf(['total_ttc', 'amount']),
      subtotalAmount: valueOf(['total_ht']),
      taxAmount: valueOf(['total_tva']),
      currency: valueOf(['currency']).toUpperCase(),
      confidence: _requiredFieldsScore(updatedFields),
      updatedAt: DateTime.now(),
      status: status,
      fields: updatedFields,
      missingFieldKeys: updatedFields
          .where((field) => field.requiredField && field.value.trim().isEmpty)
          .map((field) => field.key)
          .toList(),
      supplierResolution: nextResolution,
    );
  }

  double _requiredFieldsScore(List<ExtractedField> fields) {
    final requiredFields = fields
        .where((field) => field.requiredField)
        .toList();
    if (requiredFields.isEmpty) {
      return _draft.confidence;
    }
    final validCount = requiredFields
        .where(
          (field) => field.value.trim().isNotEmpty && !field.requiresReview,
        )
        .length;
    return validCount / requiredFields.length;
  }

  EyStatusTone _toneForField(ExtractedField field) {
    final value = _controllers[field.key]?.text.trim() ?? '';
    if (value.isEmpty && field.requiredField) {
      return EyStatusTone.error;
    }
    if (value.isEmpty) {
      return EyStatusTone.warn;
    }
    return field.requiresReview ? EyStatusTone.warn : EyStatusTone.ok;
  }

  String _labelForField(ExtractedField field, ScanTexts texts) {
    final value = _controllers[field.key]?.text.trim() ?? '';
    if (value.isEmpty) {
      return field.requiredField
          ? texts.t('preview.badge.blocking')
          : texts.t('preview.badge.fill');
    }
    if (field.requiresReview) {
      return texts.t('preview.badge.review');
    }
    return texts.t('preview.badge.good');
  }

  Widget _buildFieldEditor(ExtractedField field, ScanTexts texts) {
    final controller = _controllers[field.key]!;

    if (field.key == 'trade_sense') {
      return DropdownButtonFormField<String>(
        initialValue: _dropdownValue(controller.text, const ['achat', 'vente']),
        decoration: InputDecoration(labelText: field.label),
        items: const [
          DropdownMenuItem(value: 'achat', child: Text('Achat')),
          DropdownMenuItem(value: 'vente', child: Text('Vente')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      );
    }

    if (field.key == 'payment_status') {
      return DropdownButtonFormField<String>(
        initialValue: _dropdownValue(controller.text, const [
          'paye',
          'en_attente',
          'impaye',
        ]),
        decoration: InputDecoration(labelText: field.label),
        items: const [
          DropdownMenuItem(value: 'paye', child: Text('Payé')),
          DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
          DropdownMenuItem(value: 'impaye', child: Text('Impayé')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      );
    }

    return EyTextField(
      label: field.label,
      controller: controller,
      hint: field.requiredField
          ? texts.t('preview.required')
          : texts.t('preview.optional'),
      keyboardType: field.key.contains('total') || field.key == 'amount'
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (_) => setState(() {}),
    );
  }

  String? _dropdownValue(String raw, List<String> values) {
    final clean = raw.trim().toLowerCase();
    return values.contains(clean) ? clean : null;
  }

  EyStatusTone _toneForSupplier() {
    return switch (_draft.supplierResolution.status) {
      ScanSupplierStatus.autoMatched => EyStatusTone.ok,
      ScanSupplierStatus.created => EyStatusTone.ok,
      ScanSupplierStatus.confirmed => EyStatusTone.ok,
      ScanSupplierStatus.needsChoice => EyStatusTone.warn,
      ScanSupplierStatus.notFound => EyStatusTone.error,
      ScanSupplierStatus.unresolved => EyStatusTone.warn,
    };
  }

  String _currentSupplierName() {
    return _controllers['supplier_name']?.text.trim() ??
        _controllers['merchant_name']?.text.trim() ??
        _controllers['issuer_name']?.text.trim() ??
        _draft.supplierResolution.displayName;
  }

  String _currentSupplierTaxId() {
    return _controllers['supplier_tax_id']?.text.trim() ??
        _controllers['merchant_tax_id']?.text.trim() ??
        _controllers['issuer_tax_id']?.text.trim() ??
        _draft.supplierResolution.taxId ??
        '';
  }

  String? _currentSupplierAddress() {
    final value =
        _controllers['supplier_address']?.text.trim() ??
        _controllers['merchant_address']?.text.trim() ??
        _controllers['issuer_address']?.text.trim();
    return (value ?? '').isEmpty ? _draft.supplierResolution.address : value;
  }

  String? _currentSupplierIban() {
    final value =
        _controllers['supplier_iban']?.text.trim() ??
        _controllers['iban']?.text.trim();
    return (value ?? '').isEmpty ? _draft.supplierResolution.iban : value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final texts = ScanTexts.of(context);
    final imageFile = File(_draft.imagePath);
    final imageExists = imageFile.existsSync();

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        safeArea: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  EyIconAction(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                    tooltip: 'Retour',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isNewDraft
                              ? texts.t('preview.title.new')
                              : texts.t('preview.title.edit'),
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          texts.documentTypeLabel(_draft.documentType),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final score = _requiredFieldsScore(_updatedFields);
                      return EyStatusChip(
                        label:
                            '${(score * 100).round()}${texts.t('preview.confidence')}',
                        tone: score >= 0.7
                            ? EyStatusTone.ok
                            : EyStatusTone.warn,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    if (imageExists)
                      GestureDetector(
                        onTap: () => _openImageViewer(imageFile),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Image.file(
                                imageFile,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.62),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_out_map_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Agrandir',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (imageExists) const SizedBox(height: 16),
                    EySurfaceCard(
                      child: DropdownButtonFormField<ScanDocumentType>(
                        initialValue: _draft.documentType,
                        decoration: const InputDecoration(
                          labelText: 'Type de document',
                        ),
                        items: ScanDocumentType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(texts.documentTypeLabel(type)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _draft = _draft.copyWith(
                              documentType: value,
                              updatedAt: DateTime.now(),
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    EySurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            texts.t('preview.supplierTitle'),
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _draft
                                              .supplierResolution
                                              .displayName
                                              .isEmpty
                                          ? '—'
                                          : _draft
                                                .supplierResolution
                                                .displayName,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _draft
                                                  .supplierResolution
                                                  .taxId
                                                  ?.isNotEmpty ==
                                              true
                                          ? _draft.supplierResolution.taxId!
                                          : texts.supplierStatusNote(
                                              _draft.supplierResolution.status,
                                            ),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              EyStatusChip(
                                label: texts.supplierStatusLabel(
                                  _draft.supplierResolution.status,
                                ),
                                tone: _toneForSupplier(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          EyPrimaryButton(
                            label: _draft.supplierResolution.isResolved
                                ? texts.t('preview.supplierRefresh')
                                : texts.t('preview.supplierAction'),
                            isLoading: _isResolvingSupplier,
                            onPressed: _isResolvingSupplier
                                ? null
                                : _openSupplierBottomSheet,
                          ),
                          if (_requiresSupplierConfirmation &&
                              !_draft.supplierResolution.isResolved) ...[
                            const SizedBox(height: 10),
                            Text(
                              texts.t('preview.supplierRequired'),
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    EySurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            texts.t('preview.detectedFields'),
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            texts.t('preview.ruleSummary'),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _showAddFieldDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Ajouter un champ manquant'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._updatedFields.map(
                            (field) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          field.label,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      EyStatusChip(
                                        label: _labelForField(field, texts),
                                        tone: _toneForField(field),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFieldEditor(field, texts),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    EySurfaceCard(
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            texts.t('preview.rawText'),
                            style: textTheme.titleMedium,
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _draft.rawText.isEmpty
                                    ? texts.t('preview.rawTextEmpty')
                                    : _draft.rawText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: EySecondaryButton(
                      label: texts.t('preview.saveDraft'),
                      onPressed: _isSaving
                          ? null
                          : () => _saveDraft(ScanDraftStatus.reviewed),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EyPrimaryButton(
                      label: texts.t('preview.submit'),
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _submitDraft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
