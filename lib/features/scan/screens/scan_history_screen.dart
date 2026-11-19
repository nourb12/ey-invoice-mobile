import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_draft.dart';
import '../l10n/scan_texts.dart';
import 'scan_preview_screen.dart';
import 'scan_tracking_sheet.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  String query = '';
  int filter = 0;
  int days = 0;
  ScanDocumentType? documentType;

  Future<void> _deleteDraft(BuildContext context, ScanDraft draft) async {
    final texts = AppTexts.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(texts.t('history.deleteTitle')),
            content: Text(
              texts
                  .t('history.deleteBody')
                  .replaceFirst(
                    '{title}',
                    ScanTexts.of(context).draftTitle(draft),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(texts.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(texts.t('common.delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    final controller = context.read<ScanController>();
    try {
      await controller.deleteDraft(draft.id, keepImage: true);
      if (!context.mounted) return;
      var restored = false;
      final notification = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texts.t('history.deleted')),
          action: SnackBarAction(
            label: texts.t('history.undo'),
            onPressed: () {
              restored = true;
              controller
                  .upsertDraft(draft.copyWith(pendingSubmission: false))
                  .catchError((Object _) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(texts.t('common.error'))),
                      );
                    }
                  });
            },
          ),
        ),
      );
      await notification.closed;
      if (!restored) await controller.purgeDraftImage(draft);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(texts.t('common.error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<ScanController>();
    final texts = AppTexts.of(context);
    final scanTexts = ScanTexts.of(context);
    final cutoff = days == 0
        ? null
        : DateTime.now().subtract(Duration(days: days));
    final drafts = controller.drafts.where((draft) {
      final matches =
          '${draft.title} ${draft.invoiceNumber} ${draft.amountLabel}'
              .toLowerCase()
              .contains(query.toLowerCase().trim());
      final sent = draft.status == ScanDraftStatus.validated;
      return matches &&
          (filter == 0 || (filter == 2 ? sent : !sent)) &&
          (documentType == null || draft.documentType == documentType) &&
          (cutoff == null || !draft.createdAt.isBefore(cutoff));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts.t('history.title'), style: textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: texts.t('history.search'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(
                    texts.t(
                      ['history.all', 'history.unsent', 'history.sent'][i],
                    ),
                  ),
                  selected: filter == i,
                  onSelected: (_) => setState(() => filter = i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 500
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<int>(
                      initialValue: days,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: texts.t('history.period'),
                      ),
                      items: [
                        for (final count in [0, 7, 30, 90])
                          DropdownMenuItem(
                            value: count,
                            child: Text(
                              count == 0
                                  ? texts.t('history.allDates')
                                  : texts
                                        .t('history.days')
                                        .replaceFirst('{count}', '$count'),
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => days = value ?? 0),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<ScanDocumentType>(
                      initialValue: documentType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: texts.t('history.type'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(texts.t('history.allTypes')),
                        ),
                        for (final type in ScanDocumentType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(scanTexts.documentTypeLabel(type)),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => documentType = value),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (controller.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                texts
                    .t('history.queued')
                    .replaceFirst('{count}', '${controller.pendingCount}'),
              ),
            ),
          Text(
            texts.t('history.subtitle'),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          if (drafts.isEmpty)
            EySurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EyEyebrow(label: texts.t('history.emptyTitle')),
                  const SizedBox(height: 12),
                  Text(
                    texts.t('history.emptyBody'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            ...drafts.map(
              (draft) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EySurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ScanTexts.of(context).draftTitle(draft),
                              style: textTheme.titleMedium,
                            ),
                          ),
                          EyStatusChip(
                            label: ScanTexts.of(
                              context,
                            ).draftStatusLabel(draft.status),
                            tone: draft.status == ScanDraftStatus.validated
                                ? EyStatusTone.ok
                                : draft.status == ScanDraftStatus.reviewed
                                ? EyStatusTone.info
                                : EyStatusTone.warn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (draft.pendingSubmission)
                        Text(texts.t('history.pendingSend')),
                      Text(
                        [
                          draft.invoiceNumber,
                          draft.invoiceDate,
                          ScanTexts.of(context).draftAmount(draft),
                        ].where((item) => item.isNotEmpty).join(' • '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          EyStatusChip(
                            label:
                                '${(draft.confidence * 100).round()}% ${texts.t('history.readQuality')}',
                            tone: EyStatusTone.neutral,
                          ),
                          Text(
                            ScanTexts.of(context).draftDate(draft.updatedAt),
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: EySecondaryButton(
                              label: texts.t(
                                draft.status == ScanDraftStatus.validated
                                    ? 'tracking.title'
                                    : 'common.edit',
                              ),
                              icon: draft.status == ScanDraftStatus.validated
                                  ? Icons.track_changes
                                  : Icons.edit_note_rounded,
                              onPressed: controller.isBusy
                                  ? null
                                  : () {
                                      if (draft.status ==
                                          ScanDraftStatus.validated) {
                                        if (draft.backendTransactionId !=
                                            null) {
                                          ScanTrackingSheet.open(
                                            context,
                                            draft,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                texts.t('tracking.recorded'),
                                              ),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ScanPreviewScreen(
                                            initialDraft: draft,
                                            isNewDraft: false,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: EySecondaryButton(
                              label: texts.t('common.delete'),
                              icon: Icons.delete_outline_rounded,
                              onPressed: controller.isBusy
                                  ? null
                                  : () => _deleteDraft(context, draft),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
