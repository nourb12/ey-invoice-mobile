import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/session_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _localError = null;
    });

    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() {
        _localError = AppTexts.of(context).t('otp.invalid');
      });
      return;
    }

    await context.read<SessionController>().verifyTwoFactorCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final session = context.watch<SessionController>();
    final texts = AppTexts.of(context);
    final errorMessage = session.errorKey == null
        ? _localError
        : texts.t(session.errorKey!);

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: EySurfaceCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const EyBrandMark(),
                      const SizedBox(width: 12),
                      Text(
                        texts.t('otp.twoFactor'),
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  EyEyebrow(label: texts.t('otp.securityStep')),
                  const SizedBox(height: 16),
                  Text(
                    texts.t('otp.instruction'),
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    texts.t('otp.description'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.warn.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.warn.withValues(alpha: .22),
                        ),
                      ),
                      child: Text(
                        errorMessage,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.warn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  EyTextField(
                    label: texts.t('otp.code'),
                    controller: _codeController,
                    hint: '000000',
                    mono: true,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _validate(),
                  ),
                  const SizedBox(height: 10),
                  Text(texts.t('otp.tip'), style: textTheme.bodySmall),
                  const SizedBox(height: 18),
                  EyPrimaryButton(
                    label: texts.t('otp.validate'),
                    icon: Icons.verified_rounded,
                    isLoading: session.isBusy,
                    onPressed: _validate,
                  ),
                  const SizedBox(height: 12),
                  EySecondaryButton(
                    label: texts.t('otp.backToLogin'),
                    icon: Icons.arrow_back_rounded,
                    onPressed: session.isBusy ? null : session.cancelTwoFactor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
