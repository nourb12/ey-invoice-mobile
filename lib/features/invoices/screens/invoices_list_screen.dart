import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/invoices_controller.dart';
import '../models/invoice.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<InvoicesController>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final texts = AppTexts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = context.ey;
        return AlertDialog(
          title: Text(texts.t('invoice.deleteTitle')),
          content: Text(
            texts
                .t('invoice.deleteBody')
                .replaceFirst('{number}', invoice.invoiceNumber),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(texts.t('common.cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(texts.t('common.delete')),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await context.read<InvoicesController>().deleteInvoice(
        invoice.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? texts.t('invoice.deleted')
                  : texts.t('invoice.deleteError'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<InvoicesController>();
    final texts = AppTexts.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texts.t('invoice.listTitle'),
                      style: textTheme.headlineMedium,
                    ),
                    Text(
                      texts.t('invoice.listSubtitle'),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              EyIconAction(
                icon: Icons.refresh_rounded,
                onTap: controller.isLoading ? null : () => controller.refresh(),
                tooltip: texts.t('invoice.refresh'),
              ),
              const SizedBox(width: 8),
              EyIconAction(
                icon: Icons.add_rounded,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InvoiceFormScreen(),
                    ),
                  );
                  if (mounted) {
                    controller.refresh();
                  }
                },
                tooltip: texts.t('invoice.new'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: texts.t('invoice.total'),
                  value: controller.totalCount.toString(),
                  tone: EyStatusTone.neutral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: texts.t('invoice.paid'),
                  value: controller.paidCount.toString(),
                  tone: EyStatusTone.ok,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: texts.t('invoice.pending'),
                  value: controller.pendingCount.toString(),
                  tone: EyStatusTone.warn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recherche
          EyTextField(
            label: texts.t('invoice.search'),
            controller: _searchController,
            hint: texts.t('invoice.searchHint'),
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: (value) {
              controller.setSearchQuery(value);
            },
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    },
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Contenu
          if (controller.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.ey),
                ),
              ),
            )
          else if (controller.errorKey != null)
            EySurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: colors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          texts.t('invoice.connectionError'),
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texts.t(controller.errorKey!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  EySecondaryButton(
                    label: texts.t('invoice.retry'),
                    icon: Icons.refresh_rounded,
                    onPressed: () => controller.refresh(),
                  ),
                ],
              ),
            )
          else if (controller.filteredInvoices.isEmpty)
            EySurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EyEyebrow(label: texts.t('invoice.emptyTitle')),
                  const SizedBox(height: 12),
                  Text(
                    controller.searchQuery.isNotEmpty
                        ? texts
                              .t('invoice.emptySearch')
                              .replaceFirst('{query}', controller.searchQuery)
                        : texts.t('invoice.empty'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            ...controller.filteredInvoices.map((invoice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EySurfaceCard(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InvoiceDetailScreen(invoice: invoice),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.invoiceNumber,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                              EyStatusChip(
                                label: texts.t(
                                  'invoice.status.${invoice.status}',
                                ),
                                tone: _getStatusTone(invoice.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            invoice.clientName,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invoice.formattedAmount} • ${DateFormat('dd/MM/yyyy').format(invoice.issueDate)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: EySecondaryButton(
                                  label: texts.t('common.edit'),
                                  icon: Icons.edit_outlined,
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            InvoiceFormScreen(invoice: invoice),
                                      ),
                                    );
                                    if (mounted) {
                                      controller.refresh();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: EySecondaryButton(
                                  label: texts.t('common.delete'),
                                  icon: Icons.delete_outline_rounded,
                                  onPressed: () => _deleteInvoice(invoice),
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
            }),
        ],
      ),
    );
  }

  EyStatusTone _getStatusTone(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return EyStatusTone.ok;
      case 'PENDING':
        return EyStatusTone.warn;
      case 'OVERDUE':
        return EyStatusTone.error;
      case 'CANCELLED':
        return EyStatusTone.neutral;
      default:
        return EyStatusTone.info;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final EyStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;

    return EySurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyStatusChip(label: label, tone: tone),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
