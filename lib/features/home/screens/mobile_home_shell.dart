import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../../auth/controllers/session_controller.dart';
import '../../scan/screens/dashboard_screen.dart';
import '../../scan/screens/scan_history_screen.dart';
import '../../scan/screens/scan_screen.dart';
import 'scanned_invoices_portal_screen.dart';
import '../../assistant/assistant_sheet.dart';
import '../../notifications/document_alerts_controller.dart';
import '../../notifications/document_alerts_sheet.dart';

class MobileHomeShell extends StatefulWidget {
  const MobileHomeShell({super.key});

  @override
  State<MobileHomeShell> createState() => _MobileHomeShellState();
}

class _MobileHomeShellState extends State<MobileHomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  final _assistantMessages = <Map<String, dynamic>>[];
  late final DocumentAlertsController _alerts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final sessions = context.read<SessionController>();
    final user = sessions.session!.utilisateur;
    _alerts = DocumentAlertsController(
      account: '${user.entrepriseId}:${user.id}',
      token: () {
        final current = sessions.session;
        return current?.utilisateur.id == user.id &&
                current?.utilisateur.entrepriseId == user.entrepriseId
            ? current?.accessToken
            : null;
      },
    )..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _alerts.setActive(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alerts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.read<ThemeController>();
    final sessionController = context.read<SessionController>();
    final texts = AppTexts.of(context);

    final pages = <Widget>[
      DashboardScreen(
        onOpenScan: () => setState(() => _index = 1),
        onOpenHistory: () => setState(() => _index = 2),
        onToggleTheme: () {
          themeController.toggle();
        },
        onLogout: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(texts.t('session.logoutConfirm')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(texts.t('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(texts.t('common.logout')),
                ),
              ],
            ),
          );
          if (confirmed == true) await sessionController.logout();
        },
      ),
      const ScanScreen(),
      const ScanHistoryScreen(),
      const ScannedInvoicesPortalScreen(),
    ];

    return Scaffold(
      backgroundColor: context.ey.pageBg,
      floatingActionButton: FloatingActionButton.small(
        tooltip: texts.t('assistant.title'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black26,
          builder: (_) => MobileAssistant(messages: _assistantMessages),
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
      body: EyBackground(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedBuilder(
                  animation: _alerts,
                  builder: (context, _) => IconButton(
                    tooltip: texts.t('alerts.title'),
                    icon: Badge(
                      isLabelVisible: _alerts.unreadCount > 0,
                      label: Text('${_alerts.unreadCount}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      _alerts.refresh();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            DocumentAlertsSheet(controller: _alerts),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(index: _index, children: pages),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: EySurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_customize_outlined,
                        label: texts.t('nav.home'),
                        selected: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _NavItem(
                        icon: Icons.document_scanner_outlined,
                        label: texts.t('nav.scan'),
                        selected: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      _NavItem(
                        icon: Icons.history_rounded,
                        label: texts.t('nav.history'),
                        selected: _index == 2,
                        onTap: () => setState(() => _index = 2),
                      ),
                      _NavItem(
                        icon: Icons.receipt_long_outlined,
                        label: texts.t('nav.scannedInvoices'),
                        selected: _index == 3,
                        onTap: () => setState(() => _index = 3),
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? colors.eySoft : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
