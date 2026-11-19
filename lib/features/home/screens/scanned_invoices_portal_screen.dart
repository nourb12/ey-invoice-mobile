import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/network/portal_config.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';

class ScannedInvoicesPortalScreen extends StatelessWidget {
  const ScannedInvoicesPortalScreen({super.key});

  static final Uri _portalUri = PortalConfig.uri('/factures-scannees');

  Future<void> _openPortal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = AppTexts.of(context).t('portal.openError');
    final ok = await launchUrl(
      _portalUri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyBrandMark(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texts.t('portal.scannedInvoicesTitle'),
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          EySurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyEyebrow(label: texts.t('portal.eyebrow')),
                const SizedBox(height: 16),
                Text(
                  texts.t('portal.scannedInvoicesTitle'),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  texts.t('portal.scannedInvoicesSubtitle'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border1),
                  ),
                  child: Text(
                    _portalUri.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                EyPrimaryButton(
                  label: texts.t('portal.openScannedInvoices'),
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => _openPortal(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
