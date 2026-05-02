import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/invoices_controller.dart';
import '../models/invoice.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({
    super.key,
    this.invoice,
  });

  final Invoice? invoice;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _status = 'PENDING';
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  String _currency = 'EUR';

  bool get isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _clientNameController.text = widget.invoice!.clientName;
      _amountController.text = widget.invoice!.amount.toString();
      _descriptionController.text = widget.invoice!.description ?? '';
      _status = widget.invoice!.status;
      _issueDate = widget.invoice!.issueDate;
      _dueDate = widget.invoice!.dueDate;
      _currency = widget.invoice!.currency ?? 'EUR';
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final initialDate = isIssueDate ? _issueDate : (_dueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final invoice = Invoice(
      id: widget.invoice?.id,
      invoiceNumber: _invoiceNumberController.text.trim(),
      clientName: _clientNameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      status: _status,
      issueDate: _issueDate,
      dueDate: _dueDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      currency: _currency,
    );

    final controller = context.read<InvoicesController>();
    final success = isEditing
        ? await controller.updateInvoice(widget.invoice!.id!, invoice)
        : await controller.createInvoice(invoice);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Facture mise à jour avec succès'
                : 'Facture créée avec succès',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: context.ey.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<InvoicesController>();

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
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                      tooltip: 'Fermer',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifier la facture' : 'Nouvelle facture',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EySurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const EyEyebrow(label: 'Informations générales'),
                              const SizedBox(height: 16),
                              EyTextField(
                                label: 'Numéro de facture',
                                controller: _invoiceNumberController,
                                hint: 'INV-2026-001',
                                prefixIcon: const Icon(Icons.tag_rounded),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le numéro est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              EyTextField(
                                label: 'Nom du client',
                                controller: _clientNameController,
                                hint: 'Entreprise ABC',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le nom du client est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              EyTextField(
                                label: 'Montant',
                                controller: _amountController,
                                hint: '1500.00',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                prefixIcon: const Icon(Icons.euro_rounded),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le montant est requis';
                                  }
                                  final amount = double.tryParse(value.trim());
                                  if (amount == null || amount <= 0) {
                                    return 'Montant invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Statut',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StatusChip(
                                    label: 'En attente',
                                    value: 'PENDING',
                                    selected: _status == 'PENDING',
                                    onTap: () => setState(() => _status = 'PENDING'),
                                  ),
                                  _StatusChip(
                                    label: 'Payée',
                                    value: 'PAID',
                                    selected: _status == 'PAID',
                                    onTap: () => setState(() => _status = 'PAID'),
                                  ),
                                  _StatusChip(
                                    label: 'En retard',
                                    value: 'OVERDUE',
                                    selected: _status == 'OVERDUE',
                                    onTap: () => setState(() => _status = 'OVERDUE'),
                                  ),
                                  _StatusChip(
                                    label: 'Annulée',
                                    value: 'CANCELLED',
                                    selected: _status == 'CANCELLED',
                                    onTap: () => setState(() => _status = 'CANCELLED'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        EySurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const EyEyebrow(label: 'Dates'),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.inputBorder),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date d\'émission',
                                              style: textTheme.labelSmall?.copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(_issueDate),
                                              style: textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => _selectDate(context, false),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.inputBorder),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_rounded,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date d\'échéance (optionnel)',
                                              style: textTheme.labelSmall?.copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _dueDate != null
                                                  ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                                                  : 'Non définie',
                                              style: textTheme.bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_dueDate != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () => setState(() => _dueDate = null),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        EySurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const EyEyebrow(label: 'Description (optionnel)'),
                              const SizedBox(height: 16),
                              EyTextField(
                                label: 'Description',
                                controller: _descriptionController,
                                hint: 'Détails supplémentaires...',
                                maxLines: 4,
                                prefixIcon: const Icon(Icons.notes_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        EyPrimaryButton(
                          label: isEditing ? 'Mettre à jour' : 'Créer la facture',
                          icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                          isLoading: controller.isLoading,
                          onPressed: _submit,
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.eySoft : colors.bgGhost,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.eyLine : colors.border1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
