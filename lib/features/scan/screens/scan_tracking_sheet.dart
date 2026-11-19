import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_draft.dart';
import '../l10n/scan_texts.dart';

class ScanTrackingSheet extends StatefulWidget {
  const ScanTrackingSheet({super.key, this.draft, this.transactionId})
    : assert(draft != null || transactionId != null);
  final ScanDraft? draft;
  final String? transactionId;

  static Future<void> open(BuildContext context, ScanDraft draft) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ScanTrackingSheet(draft: draft),
      );

  @override
  State<ScanTrackingSheet> createState() => _ScanTrackingSheetState();
}

class _ScanTrackingSheetState extends State<ScanTrackingSheet> {
  late Future<Map<String, dynamic>> _request;

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<Map<String, dynamic>> _load() => context
      .read<ScanController>()
      .getExpense(widget.transactionId ?? widget.draft!.backendTransactionId!);

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      texts.t('tracking.title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: texts.t('invoice.refresh'),
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _request = _load()),
                  ),
                  IconButton(
                    tooltip: texts.t('common.close'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _request,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(texts.t('tracking.error')));
                    }
                    final data = snapshot.data!;
                    final status = data['statut']?.toString();
                    // These are receipt-review states, not electronic invoice transmission states.
                    final state = switch (status) {
                      '0' || 'NonJustifiee' => 'missing',
                      '1' || 'EnAttente' => 'pending',
                      '2' || 'Justifiee' => 'reviewed',
                      _ => 'unknown',
                    };
                    final activities = (data['activities'] as List?) ?? [];
                    return ListView(
                      children: [
                        Text(
                          data['tiersNom']?.toString() ??
                              (widget.draft == null
                                  ? texts.t('tracking.title')
                                  : ScanTexts.of(
                                      context,
                                    ).draftTitle(widget.draft!)),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: EyStatusChip(
                            label: texts.t('tracking.$state'),
                            tone: state == 'reviewed'
                                ? EyStatusTone.ok
                                : EyStatusTone.info,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (data['montant'] is num)
                          Text(
                            NumberFormat.currency(
                              locale: locale,
                              name: data['devise']?.toString() ?? 'TND',
                              decimalDigits:
                                  (data['devise']?.toString() ?? 'TND')
                                          .toUpperCase() ==
                                      'TND'
                                  ? 3
                                  : 2,
                            ).format(data['montant']),
                            textDirection: TextDirection.ltr,
                          ),
                        const SizedBox(height: 20),
                        Text(
                          texts.t('tracking.activity'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final activity in activities.whereType<Map>())
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.history,
                              color: context.ey.textSecondary,
                            ),
                            title: Text(
                              activity['description']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              _date(activity['createdAt'], locale),
                            ),
                          ),
                        if (activities.isEmpty)
                          Text(texts.t('tracking.noActivity')),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _date(dynamic value, String locale) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? ''
        : DateFormat.yMd(locale).add_Hm().format(date.toLocal());
  }
}
