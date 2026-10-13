import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_texts.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_background.dart';
import '../../../core/widgets/ey_components.dart';
import '../../../core/widgets/language_picker_button.dart';
import '../controllers/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _localError = null;
    });

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      final texts = AppTexts.of(context);
      setState(() {
        _localError = texts.t('login.error');
      });
      return;
    }

    await context.read<SessionController>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final session = context.watch<SessionController>();
    final themeController = context.read<ThemeController>();
    final texts = AppTexts.of(context);
    final errorMessage = session.errorMessage ?? _localError;

    return Scaffold(
      backgroundColor: colors.pageBg,
      body: EyBackground(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            // Sticky header row: logo, title, language, theme
            SafeArea(
              child: Row(
                children: [
                  const EyBrandMark(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texts.t('login.tuniflow'),
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          texts.t('login.loginLabel'),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const LanguagePickerButton(),
                  const SizedBox(width: 8),
                  EyIconAction(
                    icon: context.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () {
                      themeController.toggle();
                    },
                    tooltip: texts.t('theme.toggle'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Expandable content area with centered form
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 120,
                    maxWidth: 520,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        EySurfaceCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EyEyebrow(label: texts.t('login.eyebrow')),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    texts.t('login.title1'),
                                    style: textTheme.headlineMedium,
                                  ),
                                  Text(
                                    texts.t('login.title2'),
                                    style: textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
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
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: colors.warn,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colors.warn,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              EyTextField(
                                label: texts.t('login.email'),
                                controller: _emailController,
                                hint: texts.t('login.emailHint'),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                prefixIcon: const Icon(Icons.alternate_email_rounded),
                              ),
                              const SizedBox(height: 14),
                              EyTextField(
                                label: texts.t('login.password'),
                                controller: _passwordController,
                                hint: texts.t('login.passwordHint'),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              EyPrimaryButton(
                                label: texts.t('login.submit'),
                                icon: Icons.arrow_forward_rounded,
                                isLoading: session.isBusy,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
