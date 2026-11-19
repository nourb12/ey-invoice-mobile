import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../l10n/scan_texts.dart';
import '../models/scan_draft.dart';
import '../../../core/l10n/app_texts.dart';
import 'scan_preview_screen.dart';
import 'scan_success_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Future<void> _startScan(BuildContext context, ImageSource source) async {
    final controller = context.read<ScanController>();
    final draft = await controller.createDraftFromSource(source);

    if (!context.mounted) {
      return;
    }

    if (controller.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ScanTexts.of(context).controllerError(
              controller.errorKey,
              controller.errorStatusCode,
            ),
          ),
        ),
      );
      controller.clearError();
    }

    if (draft != null) {
      final result = await Navigator.of(context).push<ScanSuccessAction?>(
        MaterialPageRoute<ScanSuccessAction?>(
          builder: (_) =>
              ScanPreviewScreen(initialDraft: draft, isNewDraft: true),
        ),
      );

      if (!context.mounted || result != ScanSuccessAction.scanAnother) {
        return;
      }

      await _startScan(context, source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<ScanController>();
    final latestDraft = controller.latestDraft;
    final texts = ScanTexts.of(context);
    final sheetMaxHeight = MediaQuery.of(context).size.height * 0.72;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.t('screen.title'), style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          const SizedBox(height: 18),
          EySurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.t('screen.sourceTitle'),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  texts.t('screen.documentType'),
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                // Modernized selector: tappable card opening bottom sheet with icons
                InkWell(
                  onTap: controller.isBusy
                      ? null
                      : () async {
                          final chosen =
                              await showModalBottomSheet<ScanDocumentType>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (_) => SafeArea(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: sheetMaxHeight,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            texts.t('screen.documentType'),
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            texts.t('screen.documentTypeHint'),
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colors.textSecondary,
                                                  height: 1.4,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: ListView.separated(
                                              itemCount: ScanDocumentType
                                                  .values
                                                  .length,
                                              separatorBuilder: (_, _) =>
                                                  const SizedBox(height: 6),
                                              itemBuilder: (_, index) {
                                                final type = ScanDocumentType
                                                    .values[index];
                                                final isSelected =
                                                    type ==
                                                    controller
                                                        .selectedDocumentType;

                                                return Material(
                                                  color: isSelected
                                                      ? colors.eySoft
                                                      : colors.bgCard,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 6,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: BorderSide(
                                                        color: isSelected
                                                            ? colors.ey
                                                            : colors.border1,
                                                      ),
                                                    ),
                                                    leading: Icon(
                                                      Icons
                                                          .description_outlined,
                                                      color: isSelected
                                                          ? colors.eyText
                                                          : colors
                                                                .textSecondary,
                                                    ),
                                                    title: Text(
                                                      texts.documentTypeLabel(
                                                        type,
                                                      ),
                                                      style: textTheme.bodyLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    subtitle: Text(
                                                      texts.documentTypeShort(
                                                        type,
                                                      ),
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colors
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                    trailing: isSelected
                                                        ? Icon(
                                                            Icons.check_circle,
                                                            color: colors.ey,
                                                          )
                                                        : const Icon(
                                                            Icons.chevron_right,
                                                          ),
                                                    onTap: () => Navigator.of(
                                                      context,
                                                    ).pop(type),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                          if (chosen != null) {
                            controller.selectDocumentType(chosen);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texts.documentTypeLabel(
                              controller.selectedDocumentType,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texts.documentTypeDescription(
                    controller.selectedDocumentType,
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final type in [
                      ScanDocumentType.facture,
                      ScanDocumentType.avoir,
                      ScanDocumentType.devis,
                    ])
                      ChoiceChip(
                        label: Text(texts.documentTypeLabel(type)),
                        selected: controller.selectedDocumentType == type,
                        onSelected: controller.isBusy
                            ? null
                            : (_) => controller.selectDocumentType(type),
                      ),
                  ],
                ),
                EyPrimaryButton(
                  label: texts.t('screen.camera'),
                  isLoading: controller.isBusy,
                  onPressed: controller.supportsOcr
                      ? () => _startScan(context, ImageSource.camera)
                      : null,
                ),
                const SizedBox(height: 12),
                EySecondaryButton(
                  label: texts.t('screen.gallery'),
                  onPressed: controller.supportsOcr
                      ? () => _startScan(context, ImageSource.gallery)
                      : null,
                ),
                const SizedBox(height: 12),
                EySecondaryButton(
                  label: AppTexts.of(context).t('scan.importPdf'),
                  onPressed: controller.isBusy
                      ? null
                      : () async {
                          final draft = await controller.importPdf();
                          if (!context.mounted) return;
                          if (draft != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ScanPreviewScreen(
                                  initialDraft: draft,
                                  isNewDraft: true,
                                ),
                              ),
                            );
                          } else if (controller.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ScanTexts.of(context).controllerError(
                                    controller.errorKey,
                                    controller.errorStatusCode,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          EySurfaceCard(
            child: ExpansionTile(
              initiallyExpanded: controller.drafts.isEmpty,
              tilePadding: EdgeInsets.zero,
              title: Text(
                texts.t('screen.flowTitle'),
                style: textTheme.titleMedium,
              ),
              children: [
                _FlowItem(
                  step: '1',
                  title: texts.t('screen.flow1Title'),
                  description: texts.t('screen.flow1Text'),
                ),
                const SizedBox(height: 12),
                _FlowItem(
                  step: '2',
                  title: texts.t('screen.flow2Title'),
                  description: texts.t('screen.flow2Text'),
                ),
                const SizedBox(height: 12),
                _FlowLegendItem(
                  step: '3',
                  title: texts.t('screen.flow3Title'),
                  items: [
                    _FlowLegendLine(
                      color: colors.ok,
                      label: texts.t('screen.flow3Good'),
                    ),
                    _FlowLegendLine(
                      color: colors.warn,
                      label: texts.t('screen.flow3Review'),
                    ),
                    _FlowLegendLine(
                      color: colors.error,
                      label: texts.t('screen.flow3Required'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FlowItem(
                  step: '4',
                  title: texts.t('screen.flow4Title'),
                  description: texts.t('screen.flow4Text'),
                ),
              ],
            ),
          ),
          if (latestDraft != null) ...[
            const SizedBox(height: 16),
            EySurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.t('screen.latestDraft'),
                          style: textTheme.titleMedium,
                        ),
                      ),
                      EyStatusChip(
                        label: texts.draftStatusLabel(latestDraft.status),
                        tone: latestDraft.status == ScanDraftStatus.validated
                            ? EyStatusTone.ok
                            : latestDraft.status == ScanDraftStatus.reviewed
                            ? EyStatusTone.info
                            : EyStatusTone.warn,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    texts.draftTitle(latestDraft),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    texts.draftAmount(latestDraft),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EySecondaryButton(
                    label: texts.t('screen.openDraft'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ScanPreviewScreen(
                            initialDraft: latestDraft,
                            isNewDraft: false,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.ey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            step,
            style: textTheme.labelMedium?.copyWith(
              color: colors.eyText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowLegendItem extends StatelessWidget {
  const _FlowLegendItem({
    required this.step,
    required this.title,
    required this.items,
  });

  final String step;
  final String title;
  final List<_FlowLegendLine> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.ey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            step,
            style: textTheme.labelMedium?.copyWith(
              color: colors.eyText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
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
      ],
    );
  }
}

class _FlowLegendLine {
  const _FlowLegendLine({required this.color, required this.label});

  final Color color;
  final String label;
}
