import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/language_controller.dart';
import '../theme/theme_extensions.dart';

class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  // Language configuration with flags (matching frontend)
  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      code: 'fr',
      label: 'Français',
      flag: '🇫🇷',
    ),
    _LanguageOption(
      code: 'en',
      label: 'English',
      flag: '🇺🇸',
    ),
    _LanguageOption(
      code: 'ar',
      label: 'العربية',
      flag: '🇹🇳',
    ),
  ];

  static _LanguageOption _getLanguage(String code) {
    return _languages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => _languages[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final controller = context.watch<LanguageController>();
    final currentLang = _getLanguage(controller.languageCode);

    return Tooltip(
      message: 'Changer de langue',
      child: Material(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: PopupMenuButton<String>(
          tooltip: '',
          initialValue: controller.languageCode,
          onSelected: controller.setLanguage,
          color: colors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.border1),
          ),
          itemBuilder: (context) => _languages
              .map(
                (lang) => PopupMenuItem<String>(
                  value: lang.code,
                  child: Row(
                    children: [
                      // Flag emoji
                      Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      // Language label
                      Expanded(
                        child: Text(
                          lang.label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: lang.code == controller.languageCode
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      // Checkmark for selected language
                      if (lang.code == controller.languageCode)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: colors.ey,
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border1),
            ),
            child: Text(
              currentLang.flag,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;
}
