import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../../../core/widgets/language_picker_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_draft.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenScan,
    required this.onOpenHistory,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final VoidCallback onOpenScan;
  final VoidCallback onOpenHistory;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final session = context.watch<SessionController>();
    final scanController = context.watch<ScanController>();
    final recentDrafts = scanController.drafts.take(3).toList();
    final userName = session.user?.prenom.isNotEmpty == true
      ? session.user!.prenom
      : 'Utilisateur';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenue $userName', style: textTheme.titleMedium),
                  ],
                ),
              ),
              const LanguagePickerButton(),
              const SizedBox(width: 8),
              EyIconAction(
                icon: context.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: onToggleTheme,
                tooltip: 'Changer de thème',
              ),
              const SizedBox(width: 8),
              EyIconAction(
                icon: Icons.logout_rounded,
                onTap: () => onLogout(),
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          const SizedBox(height: 20),
          EySurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyEyebrow(label: 'Scannez vos documents'),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gérez vos Documents',
                      style: textTheme.headlineMedium,
                    ),
                    Text(
                      'Papiers Depuis Votre Mobile',
                      style: textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Capturez vos documents, vérifiez les informations scannées, validez en quelques secondes.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: EyPrimaryButton(
                        label: 'Scanner',
                        icon: Icons.document_scanner_outlined,
                        onPressed: onOpenScan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EySecondaryButton(
                        label: 'Historique',
                        icon: Icons.history_rounded,
                        onPressed: onOpenHistory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Brouillons',
                  value: scanController.reviewedCount.toString(),
                  tone: EyStatusTone.neutral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Validé',
                  value: scanController.validatedCount.toString(),
                  tone: EyStatusTone.ok,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'À revalider',
                  value: scanController.extractedCount.toString(),
                  tone: EyStatusTone.warn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EySurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Derniers brouillons', style: textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: onOpenHistory,
                      child: const Text('Tout voir'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (recentDrafts.isEmpty)
                  Text(
                    'Aucun scan enregistré pour le moment.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                else
                  ...recentDrafts.map(
                    (draft) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const EyBrandMark(size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft.title,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${draft.amountLabel} • ${DateFormat('dd/MM/yyyy HH:mm').format(draft.updatedAt)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          EyStatusChip(
                            label: draft.status.label,
                            tone: draft.status == ScanDraftStatus.validated
                                ? EyStatusTone.ok
                                : draft.status == ScanDraftStatus.reviewed
                                ? EyStatusTone.info
                                : EyStatusTone.warn,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: switch (tone) {
                EyStatusTone.ok => colors.ok,
                EyStatusTone.warn => colors.warn,
                EyStatusTone.info => colors.info,
                EyStatusTone.error => colors.error,
                EyStatusTone.ey => colors.ey,
                EyStatusTone.neutral => colors.textSecondary.withValues(alpha: .45),
              },
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
