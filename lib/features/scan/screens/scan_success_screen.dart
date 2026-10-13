import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../l10n/scan_texts.dart';

enum ScanSuccessAction { scanAnother, recentDrafts }

class ScanSuccessScreen extends StatelessWidget {
  const ScanSuccessScreen({super.key, this.message});

  final String? message;

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
                    EyPrimaryButton(
                      label: texts.t('success.scanAnother'),
                      onPressed: () => Navigator.of(context).pop(
                        ScanSuccessAction.scanAnother,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EySecondaryButton(
                      label: texts.t('success.recent'),
                      onPressed: () => Navigator.of(context).pop(
                        ScanSuccessAction.recentDrafts,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
