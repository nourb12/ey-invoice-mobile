import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/theme_extensions.dart';
import '../../../core/l10n/app_texts.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../l10n/scan_texts.dart';
import '../models/extracted_field.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';
import '../services/document_checks.dart';
import '../services/scan_field_rules.dart';
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
  late final ScanController _scanController;
  bool _isSaving = false;
  bool _isResolvingSupplier = false;
  bool _autoSupplierAttempted = false;
  Timer? _autosave;
  bool _dirty = false;
  bool _allowPop = false;
  bool _syncingControllers = false;
  final Set<String> _confirmedKeys = {};
  late final Set<String> _reviewKeys;

  void _onEdited() {
    if (_syncingControllers) return;
    if (_draft.supplierResolution.isResolved &&
        _draft.fields.any(
          (field) =>
              [
                'supplier_name',
                'merchant_name',
                'issuer_name',
                'supplier_tax_id',
                'merchant_tax_id',
                'issuer_tax_id',
              ].contains(field.key) &&
              _controllers[field.key]?.text.trim() != field.value.trim(),
        )) {
      _draft = _draft.copyWith(
        supplierResolution: ScanSupplierResolution.initial(
          displayName: _currentSupplierName(),
          taxId: _currentSupplierTaxId(),
          address: _currentSupplierAddress(),
          iban: _currentSupplierIban(),
        ),
      );
    }
    _dirty = true;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted || _isSaving) return;
      try {
        await _scanController.upsertDraft(
          _buildDraft(ScanDraftStatus.reviewed),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTexts.of(context).t('preview.saveError')),
            ),
          );
        }
      }
    });
  }

  Future<void> _confirmLeave() async {
    if (_isSaving) return;
    final texts = AppTexts.of(context);
    final choice = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(texts.t('preview.leave')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 0),
            child: Text(texts.t('preview.stay')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 1),
            child: Text(texts.t('preview.discard')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 2),
            child: Text(texts.t('common.save')),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == 0) return;
    _autosave?.cancel();
    if (choice == 2) {
      try {
        await _scanController.upsertDraft(
          _buildDraft(ScanDraftStatus.reviewed),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(texts.t('preview.saveError'))));
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void initState() {
    super.initState();
    _scanController = context.read<ScanController>();
    _scanController.beginReview();
    _draft = widget.initialDraft;
    _reviewKeys = _draft.fields
        .where(
          (f) =>
              f.requiresReview || f.confidence < 70 || f.value.trim().isEmpty,
        )
        .map((f) => f.key)
        .toSet();
    _syncControllers(_draft.fields);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeResolveSupplier(),
    );
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _scanController.endReview();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<ExtractedField> fields) {
    _syncingControllers = true;
    try {
      for (final field in fields) {
        final controller = _controllers[field.key];
        if (controller == null) {
          _controllers[field.key] = TextEditingController(text: field.value);
          _controllers[field.key]!.addListener(_onEdited);
        } else if (controller.text != field.value) {
          controller.text = field.value;
        }
      }
    } finally {
      _syncingControllers = false;
    }
  }

  void _changeDocumentType(ScanDocumentType type) {
    final fields = ScanFieldRules.normalize(type, _updatedFields);
    setState(() {
      _draft = _draft.copyWith(
        documentType: type,
        fields: fields,
        updatedAt: DateTime.now(),
      );
      _reviewKeys.addAll(
        fields
            .where((f) => f.requiresReview || f.value.isEmpty)
            .map((f) => f.key),
      );
      _syncControllers(fields);
    });
    _onEdited();
  }

  List<ExtractedField> get _updatedFields {
    final fields = _draft.fields.map((field) {
      final value = _controllers[field.key]?.text.trim() ?? '';
      final isMissing = value.isEmpty && field.requiredField;
      return field.copyWith(
        value: value,
        requiresReview:
            isMissing ||
            (!_confirmedKeys.contains(field.key) &&
                value == field.value &&
                field.requiresReview),
      );
    }).toList();
    return fields;
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
    final texts = ScanTexts.of(context);

    String? suggestedKey;
    try {
      final field = await showDialog<ExtractedField>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(texts.t('preview.addField')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final key in [
                    'stamp_duty',
                    'fodec',
                    'withholding_tax',
                    'discount',
                    'due_date',
                  ])
                    if (!_controllers.containsKey(key))
                      ActionChip(
                        label: Text(texts.fieldLabel(key, key)),
                        onPressed: () {
                          suggestedKey = key;
                          titleController.text = texts.fieldLabel(key, key);
                        },
                      ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: texts.t('preview.fieldTitle'),
                  hintText: texts.t('preview.fieldTitleHint'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: texts.t('preview.fieldContent'),
                  hintText: texts.t('preview.fieldContentHint'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(texts.t('preview.cancel')),
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
                    key:
                        suggestedKey != null &&
                            label ==
                                texts.fieldLabel(suggestedKey!, suggestedKey!)
                        ? suggestedKey!
                        : _customFieldKey(label),
                    label: label,
                    value: value,
                    confidence: 100,
                    requiredField: false,
                    requiresReview: false,
                  ),
                );
              },
              child: Text(texts.t('preview.add')),
            ),
          ],
        ),
      );

      if (field == null || !mounted) {
        return;
      }

      setState(() {
        _controllers[field.key] = TextEditingController(text: field.value);
        _controllers[field.key]!.addListener(_onEdited);
        _reviewKeys.add(field.key);
        _draft = _draft.copyWith(
          fields: [..._draft.fields, field],
          status: ScanDraftStatus.reviewed,
          updatedAt: DateTime.now(),
        );
      });
      _onEdited();
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
    _autosave?.cancel();
    setState(() => _isSaving = true);
    final draft = _buildDraft(status);
    try {
      await _scanController.upsertDraft(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.of(context).t('preview.saveError'))),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _submitDraft() async {
    if (context.read<ScanController>().isBusy) return;
    _autosave?.cancel();
    final texts = ScanTexts.of(context);
    if (_hasBlockingFields) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts.t('preview.blocking'))));
      return;
    }

    final warnings = DocumentChecks.warnings(_updatedFields);
    final current = _buildDraft(ScanDraftStatus.reviewed);
    if (current.invoiceNumber.isNotEmpty &&
        context.read<ScanController>().drafts.any(
          (other) =>
              other.id != current.id &&
              other.status == ScanDraftStatus.validated &&
              other.invoiceNumber.trim().toLowerCase() ==
                  current.invoiceNumber.trim().toLowerCase() &&
              other.supplierName.trim().isNotEmpty &&
              other.supplierName.trim().toLowerCase() ==
                  current.supplierName.trim().toLowerCase(),
        )) {
      warnings.add('check.duplicate');
    }
    if (warnings.isNotEmpty) {
      final appTexts = AppTexts.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(appTexts.t('check.title')),
          content: Text(warnings.map(appTexts.t).join('\n\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(appTexts.t('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(appTexts.t('common.confirm')),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    setState(() => _isSaving = true);
    final reviewedDraft = _buildDraft(ScanDraftStatus.reviewed);
    await context.read<ScanController>().submitValidatedDraft(reviewedDraft);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    final controller = context.read<ScanController>();
    if (controller.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            texts.controllerError(
              controller.errorKey,
              controller.errorStatusCode,
            ),
          ),
        ),
      );
      controller.clearError();
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<ScanSuccessAction>(
        builder: (_) => ScanSuccessScreen(
          draft: controller.drafts.firstWhere((d) => d.id == reviewedDraft.id),
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
    _onEdited();
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
        'document_number',
        'invoice_number',
        'receipt_number',
        'reference',
        'delivery_note_number',
      ]),
      invoiceDate: valueOf(['issue_date']),
      dueDate: valueOf(['due_date']),
      totalAmount: valueOf(['total_ttc', 'amount']),
      subtotalAmount: valueOf(['net_ht', 'total_ht', 'brut_ht']),
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
      pendingSubmission: false,
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
        isExpanded: true,
        initialValue: _dropdownValue(controller.text, const ['achat', 'vente']),
        decoration: InputDecoration(
          labelText: texts.fieldLabel(field.key, field.label),
        ),
        items: [
          DropdownMenuItem(
            value: 'achat',
            child: Text(texts.t('preview.purchase')),
          ),
          DropdownMenuItem(
            value: 'vente',
            child: Text(texts.t('preview.sale')),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      );
    }

    if (field.key == 'payment_status') {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _dropdownValue(controller.text, const [
          'paye',
          'en_attente',
          'impaye',
        ]),
        decoration: InputDecoration(
          labelText: texts.fieldLabel(field.key, field.label),
        ),
        items: [
          DropdownMenuItem(value: 'paye', child: Text(texts.t('preview.paid'))),
          DropdownMenuItem(
            value: 'en_attente',
            child: Text(texts.t('preview.pending')),
          ),
          DropdownMenuItem(
            value: 'impaye',
            child: Text(texts.t('preview.unpaid')),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      );
    }

    if (field.key == 'issue_date' || field.key == 'due_date') {
      return EyTextField(
        label: texts.fieldLabel(field.key, field.label),
        controller: controller,
        keyboardType: TextInputType.datetime,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        textDirection: TextDirection.ltr,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: texts.fieldLabel(field.key, field.label),
          onPressed: () async {
            final parsed = DateTime.tryParse(controller.text);
            final initial =
                parsed != null && parsed.year >= 1900 && parsed.year <= 2100
                ? parsed
                : DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
            );
            if (date != null && mounted) {
              setState(
                () => controller.text = DateFormat('yyyy-MM-dd').format(date),
              );
            }
          },
        ),
      );
    }

    return EyTextField(
      label: texts.fieldLabel(field.key, field.label),
      controller: controller,
      hint: field.requiredField
          ? texts.t('preview.required')
          : texts.t('preview.optional'),
      keyboardType: field.key.contains('total') || field.key == 'amount'
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      textDirection:
          field.key.contains('total') ||
              field.key.contains('number') ||
              field.key.contains('tax_id') ||
              field.key.contains('iban') ||
              field.key == 'amount'
          ? TextDirection.ltr
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _fieldRow(ExtractedField field, ScanTexts texts) => Padding(
    key: ValueKey(field.key),
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                texts.fieldLabel(field.key, field.label),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            EyStatusChip(
              label: _labelForField(field, texts),
              tone: _toneForField(field),
            ),
            if (field.requiresReview && field.value.trim().isNotEmpty)
              IconButton(
                tooltip: AppTexts.of(context).t('preview.confirmField'),
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () {
                  setState(() => _confirmedKeys.add(field.key));
                  _onEdited();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFieldEditor(field, texts),
      ],
    ),
  );

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
    final imageExists =
        imageFile.existsSync() &&
        !_draft.imagePath.toLowerCase().endsWith('.pdf');

    return PopScope(
      canPop: _allowPop || (!_dirty && !_isSaving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
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
                      tooltip: texts.t('preview.back'),
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
                        ExpansionTile(
                          title: Text(AppTexts.of(context).t('preview.image')),
                          children: [
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
                                    PositionedDirectional(
                                      end: 12,
                                      bottom: 12,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.62,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Padding(
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
                                                texts.t('preview.expand'),
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
                          ],
                        ),
                      if (imageExists) const SizedBox(height: 16),
                      if (_draft.fields.any(
                        (f) => f.key == 'image_quality_warning',
                      )) ...[
                        EySurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppTexts.of(context).t('preview.quality')),
                              TextButton.icon(
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: Text(
                                  AppTexts.of(context).t('preview.retake'),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        final draft = await context
                                            .read<ScanController>()
                                            .createDraftFromSource(
                                              ImageSource.camera,
                                            );
                                        if (!context.mounted || draft == null) {
                                          return;
                                        }
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute<void>(
                                            builder: (_) => ScanPreviewScreen(
                                              initialDraft: draft,
                                              isNewDraft: true,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      EySurfaceCard(
                        child: DropdownButtonFormField<ScanDocumentType>(
                          isExpanded: true,
                          initialValue: _draft.documentType,
                          decoration: InputDecoration(
                            labelText: texts.t('preview.documentType'),
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
                            _changeDocumentType(value);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                _draft
                                                    .supplierResolution
                                                    .status,
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
                            EySecondaryButton(
                              label: _draft.supplierResolution.isResolved
                                  ? texts.t('preview.supplierRefresh')
                                  : texts.t('preview.supplierAction'),
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
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: _showAddFieldDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(texts.t('preview.addMissingField')),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppTexts.of(context).t('preview.reviewFields')} (${_updatedFields.where((f) => _reviewKeys.contains(f.key) && f.key != 'image_quality_warning').length})',
                            ),
                            const SizedBox(height: 12),
                            ..._updatedFields
                                .where(
                                  (f) =>
                                      _reviewKeys.contains(f.key) &&
                                      f.key != 'image_quality_warning',
                                )
                                .map((field) => _fieldRow(field, texts)),
                            ExpansionTile(
                              title: Text(
                                '${AppTexts.of(context).t('preview.goodFields')} (${_updatedFields.where((f) => !_reviewKeys.contains(f.key)).length})',
                              ),
                              children: _updatedFields
                                  .where((f) => !_reviewKeys.contains(f.key))
                                  .map((field) => _fieldRow(field, texts))
                                  .toList(),
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
                                alignment: AlignmentDirectional.centerStart,
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
      ),
    );
  }
}
