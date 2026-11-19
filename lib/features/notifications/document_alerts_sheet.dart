import 'package:flutter/material.dart';
import '../../core/l10n/app_texts.dart';
import '../scan/l10n/scan_texts.dart';
import '../scan/screens/scan_tracking_sheet.dart';
import 'document_alerts_controller.dart';

class DocumentAlertsSheet extends StatelessWidget {
  const DocumentAlertsSheet({super.key, required this.controller});
  final DocumentAlertsController controller;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final texts = AppTexts.of(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        texts.t('alerts.title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: texts.t('alerts.readAll'),
                      icon: const Icon(Icons.done_all),
                      onPressed: () async {
                        try {
                          await controller.markAllRead();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(texts.t('common.error'))),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      tooltip: texts.t('invoice.refresh'),
                      onPressed: controller.busy ? null : controller.refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: texts.t('common.close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (controller.busy) const LinearProgressIndicator(),
              if (controller.failed)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(texts.t('alerts.error')),
                ),
              Expanded(
                child: controller.items.isEmpty
                    ? Center(child: Text(texts.t('alerts.empty')))
                    : ListView.builder(
                        itemCount: controller.items.length,
                        itemBuilder: (context, index) {
                          final item = controller.items[index];
                          return ListTile(
                            leading: Icon(
                              item.kind == 'correction'
                                  ? Icons.priority_high_rounded
                                  : Icons.description_outlined,
                            ),
                            title: Text(
                              texts.t('alerts.${item.kind}'),
                              style: TextStyle(
                                fontWeight: controller.isUnread(item)
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              ScanTexts.of(context).draftDate(item.updatedAt),
                            ),
                            trailing: controller.isUnread(item)
                                ? const Icon(Icons.circle, size: 8)
                                : null,
                            onTap: () async {
                              try {
                                await controller.markRead(item);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(texts.t('common.error')),
                                    ),
                                  );
                                }
                              }
                              if (!context.mounted) return;
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => ScanTrackingSheet(
                                  transactionId: item.transactionId,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
