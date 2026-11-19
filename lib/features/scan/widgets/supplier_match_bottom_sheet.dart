import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../l10n/scan_texts.dart';
import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';

class SupplierMatchBottomSheet extends StatefulWidget {
  const SupplierMatchBottomSheet({
    super.key,
    required this.controller,
    required this.draft,
  });

  final ScanController controller;
  final ScanDraft draft;

  @override
  State<SupplierMatchBottomSheet> createState() =>
      _SupplierMatchBottomSheetState();
}

class _SupplierMatchBottomSheetState extends State<SupplierMatchBottomSheet> {
  late final TextEditingController _nameController;
  late ScanDraft _draft;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _nameController = TextEditingController(
      text: _draft.supplierResolution.displayName.isNotEmpty
          ? _draft.supplierResolution.displayName
          : _draft.supplierName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _search({bool createIfMissing = false}) async {
    setState(() => _isLoading = true);
    try {
      final changedName =
          _nameController.text.trim().toLowerCase() !=
          _draft.supplierResolution.displayName.trim().toLowerCase();
      final updated = await widget.controller.resolveSupplier(
        _draft,
        supplierName: _nameController.text.trim(),
        supplierTaxId: changedName ? '' : null,
        supplierAddress: changedName ? '' : null,
        supplierIban: changedName ? '' : null,
        createIfMissing: createIfMissing,
      );
      if (!mounted) return;
      if (widget.controller.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ScanTexts.of(context).controllerError(
                widget.controller.errorKey,
                widget.controller.errorStatusCode,
              ),
            ),
          ),
        );
        widget.controller.clearError();
        return;
      }
      setState(() => _draft = updated);
      if (_draft.supplierResolution.isResolved) {
        Navigator.of(context).pop(_draft);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ScanTexts.of(context).requestError(null))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectCandidate(ScanSupplierCandidate candidate) {
    final updated = _draft
        .copyWith(updatedAt: DateTime.now())
        .withResolvedSupplier(
          ScanSupplierResolution(
            status: ScanSupplierStatus.confirmed,
            supplierId: candidate.id,
            displayName: candidate.name,
            taxId: candidate.taxId,
            address: candidate.address,
            iban: candidate.iban,
            candidates: const <ScanSupplierCandidate>[],
          ),
        );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final texts = ScanTexts.of(context);
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final resolution = _draft.supplierResolution;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texts.t('supplier.sheet.title'),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texts.t('supplier.sheet.subtitle'),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              EyTextField(
                label: texts.t('supplier.sheet.searchLabel'),
                controller: _nameController,
                hint: texts.t('supplier.sheet.searchHint'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: EyPrimaryButton(
                      label: texts.t('supplier.sheet.searchAction'),
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _search,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EySecondaryButton(
                      label: texts.t('supplier.sheet.createAction'),
                      onPressed: _isLoading
                          ? null
                          : () => _search(createIfMissing: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                Text(
                  texts.t('supplier.sheet.matching'),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else if (resolution.candidates.isEmpty)
                Text(
                  resolution.status == ScanSupplierStatus.notFound
                      ? texts.t('supplier.sheet.noResult')
                      : texts.supplierStatusNote(resolution.status),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else ...[
                Text(
                  texts.t('supplier.sheet.candidates'),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resolution.candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final candidate = resolution.candidates[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  candidate.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              EyStatusChip(
                                label: '${candidate.score}%',
                                tone: candidate.exact
                                    ? EyStatusTone.ok
                                    : EyStatusTone.warn,
                              ),
                            ],
                          ),
                          if ((candidate.taxId ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              candidate.taxId!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                          if ((candidate.address ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              candidate.address!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: EySecondaryButton(
                              label: texts.t('supplier.sheet.use'),
                              onPressed: () => _selectCandidate(candidate),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(texts.t('supplier.sheet.close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
