import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../l10n/scan_texts.dart';
import '../models/scan_draft.dart';
import '../../../core/l10n/app_texts.dart';
import 'scan_tracking_sheet.dart';

enum ScanSuccessAction { scanAnother, recentDrafts }

class ScanSuccessScreen extends StatelessWidget {
  const ScanSuccessScreen({super.key, this.message, this.draft});

  final String? message;
  final ScanDraft? draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final texts = ScanTexts.of(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        safeArea: false,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: EySurfaceCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts.t('success.title'),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message?.trim().isNotEmpty == true
                            ? message!.trim()
                            : texts.t('success.body'),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (draft?.backendTransactionId != null) ...[
                        EyStatusChip(
                          label: AppTexts.of(context).t('tracking.pending'),
                          tone: EyStatusTone.info,
                        ),
                        const SizedBox(height: 12),
                        EySecondaryButton(
                          label: AppTexts.of(context).t('tracking.title'),
                          icon: Icons.track_changes,
                          onPressed: () =>
                              ScanTrackingSheet.open(context, draft!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      EyPrimaryButton(
                        label: texts.t('success.scanAnother'),
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(ScanSuccessAction.scanAnother),
                      ),
                      const SizedBox(height: 12),
                      EySecondaryButton(
                        label: texts.t('success.recent'),
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(ScanSuccessAction.recentDrafts),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
