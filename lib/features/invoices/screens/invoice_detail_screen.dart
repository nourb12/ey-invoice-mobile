import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../models/invoice.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    EyIconAction(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                      tooltip: 'Retour',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de la facture',
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            invoice.invoiceNumber,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    EyIconAction(
                      icon: Icons.edit_outlined,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => InvoiceFormScreen(invoice: invoice),
                          ),
                        );
                      },
                      tooltip: 'Modifier',
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carte principale
                      EySurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const EyBrandMark(size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    invoice.invoiceNumber,
                                    style: textTheme.headlineSmall,
                                  ),
                                ),
                                EyStatusChip(
                                  label: invoice.statusLabel,
                                  tone: _getStatusTone(invoice.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _DetailRow(
                              label: 'Client',
                              value: invoice.clientName,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Montant',
                              value: invoice.formattedAmount,
                              icon: Icons.euro_rounded,
                              valueStyle: textTheme.headlineSmall?.copyWith(
                                color: colors.ey,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Date d\'émission',
                              value: DateFormat('dd MMMM yyyy', 'fr_FR')
                                  .format(invoice.issueDate),
                              icon: Icons.calendar_today_rounded,
                            ),
                            if (invoice.dueDate != null) ...[
                              const SizedBox(height: 12),
                              _DetailRow(
                                label: 'Date d\'échéance',
                                value: DateFormat('dd MMMM yyyy', 'fr_FR')
                                    .format(invoice.dueDate!),
                                icon: Icons.event_rounded,
                              ),
                            ],
                            if (invoice.description != null &&
                                invoice.description!.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Divider(),
                              const SizedBox(height: 18),
                              Text(
                                'Description',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                invoice.description!,
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informations système
                      EySurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: colors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Informations système',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ID: ${invoice.id}\nDevise: ${invoice.currency}\nStatut: ${invoice.status}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueStyle,
  });

  final String label;
  final String value;
  final IconData icon;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
