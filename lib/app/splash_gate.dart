import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_texts.dart';
import '../core/theme/theme_extensions.dart';
import '../core/widgets/ey_background.dart';
import '../core/widgets/ey_components.dart';
import '../features/auth/controllers/session_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/home/screens/mobile_home_shell.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    switch (session.status) {
      case SessionStatus.booting:
        return const _SplashLoadingView();
      case SessionStatus.unauthenticated:
        return const LoginScreen();
      case SessionStatus.awaitingTwoFactor:
        return const OtpScreen();
      case SessionStatus.authenticated:
        return const MobileHomeShell();
    }
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context);

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EyBrandMark(size: 68),
                const SizedBox(height: 22),
                Text(
                  texts.t('splash.title'),
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  texts.t('splash.subtitle'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.ey),
                    backgroundColor: colors.border1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
