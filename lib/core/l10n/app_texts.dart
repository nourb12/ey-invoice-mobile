import 'package:flutter/widgets.dart';

/// Global translations for the entire app
/// Use this for common texts across all features
class AppTexts {
  AppTexts._(this._languageCode);

  final String _languageCode;

  static AppTexts of(BuildContext context) {
    return AppTexts._(
      Localizations.localeOf(context).languageCode.toLowerCase(),
    );
  }

  Map<String, String> get _bundle => switch (_languageCode) {
    'ar' => _ar,
    'en' => _en,
    _ => _fr,
  };

  String t(String key) => _bundle[key] ?? _fr[key] ?? key;

  // French translations
  static const Map<String, String> _fr = <String, String>{
    // Common
    'common.save': 'Enregistrer',
    'common.cancel': 'Annuler',
    'common.delete': 'Supprimer',
    'common.edit': 'Modifier',
    'common.loading': 'Chargement...',
    'common.error': 'Une erreur est survenue',
    'common.success': 'Opération réussie',
    'common.close': 'Fermer',
    'common.confirm': 'Confirmer',
    
    // App
    'app.name': 'EY Invoice Mobile',
    'app.tagline': 'Facturation électronique certifiée',
    
    // Splash
    'splash.title': 'EY Invoice Mobile',
    'splash.subtitle': 'Initialisation du thème, de la session et des brouillons locaux.',
    
    // Login
    'login.eyebrow': 'Portail mobile',
    'login.title1': 'Encore des Documents !',
    'login.title2': 'Pensez au Scan.',
    'login.email': 'Adresse email',
    'login.emailHint': 'exemple@entreprise.tn',
    'login.password': 'Mot de passe',
    'login.passwordHint': 'Saisis ton mot de passe',
    'login.submit': 'Se connecter',
    'login.error': 'Renseigne ton email et ton mot de passe.',
    'login.tuniflow': 'TuniFlow',
    'login.loginLabel': 'Login',
    
    // OTP
    'otp.title': 'Code de vérification',
    'otp.subtitle': 'Entrez le code à 6 chiffres',
    'otp.submit': 'Vérifier',
    'otp.resend': 'Renvoyer le code',
    
    // Navigation
    'nav.home': 'Accueil',
    'nav.scan': 'Scanner',
    'nav.history': 'Historique',
    'nav.invoices': 'Factures',
    'nav.scannedInvoices': 'Factures web',

    // Portal
    'portal.eyebrow': 'Portail web',
    'portal.scannedInvoicesTitle': 'Factures scannees',
    'portal.scannedInvoicesSubtitle': 'Ouvre le dashboard web pour confirmer, signer et suivre les documents envoyes depuis le mobile.',
    'portal.openScannedInvoices': 'Ouvrir les factures scannees',
    
    // Theme
    'theme.toggle': 'Changer de thème',
    'theme.light': 'Thème clair',
    'theme.dark': 'Thème sombre',
    
    // Language
    'language.change': 'Changer de langue',
    'language.french': 'Français',
    'language.english': 'English',
    'language.arabic': 'العربية',
  };

  // English translations
  static const Map<String, String> _en = <String, String>{
    // Common
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.loading': 'Loading...',
    'common.error': 'An error occurred',
    'common.success': 'Operation successful',
    'common.close': 'Close',
    'common.confirm': 'Confirm',
    
    // App
    'app.name': 'EY Invoice Mobile',
    'app.tagline': 'Certified electronic invoicing',
    
    // Splash
    'splash.title': 'EY Invoice Mobile',
    'splash.subtitle': 'Initializing theme, session and local drafts.',
    
    // Login
    'login.eyebrow': 'Mobile portal',
    'login.title1': 'More Documents!',
    'login.title2': 'Think Scan.',
    'login.email': 'Email address',
    'login.emailHint': 'example@company.tn',
    'login.password': 'Password',
    'login.passwordHint': 'Enter your password',
    'login.submit': 'Sign in',
    'login.error': 'Enter your email and password.',
    'login.tuniflow': 'TuniFlow',
    'login.loginLabel': 'Login',
    
    // OTP
    'otp.title': 'Verification code',
    'otp.subtitle': 'Enter the 6-digit code',
    'otp.submit': 'Verify',
    'otp.resend': 'Resend code',
    
    // Navigation
    'nav.home': 'Home',
    'nav.scan': 'Scan',
    'nav.history': 'History',
    'nav.invoices': 'Invoices',
    'nav.scannedInvoices': 'Web invoices',

    // Portal
    'portal.eyebrow': 'Web portal',
    'portal.scannedInvoicesTitle': 'Scanned invoices',
    'portal.scannedInvoicesSubtitle': 'Open the web dashboard to confirm, sign and track documents sent from mobile.',
    'portal.openScannedInvoices': 'Open scanned invoices',
    
    // Theme
    'theme.toggle': 'Change theme',
    'theme.light': 'Light theme',
    'theme.dark': 'Dark theme',
    
    // Language
    'language.change': 'Change language',
    'language.french': 'Français',
    'language.english': 'English',
    'language.arabic': 'العربية',
  };

  // Arabic translations
  static const Map<String, String> _ar = <String, String>{
    // Common
    'common.save': 'حفظ',
    'common.cancel': 'إلغاء',
    'common.delete': 'حذف',
    'common.edit': 'تعديل',
    'common.loading': 'جارٍ التحميل...',
    'common.error': 'حدث خطأ',
    'common.success': 'تمت العملية بنجاح',
    'common.close': 'إغلاق',
    'common.confirm': 'تأكيد',
    
    // App
    'app.name': 'EY Invoice Mobile',
    'app.tagline': 'الفوترة الإلكترونية المعتمدة',
    
    // Splash
    'splash.title': 'EY Invoice Mobile',
    'splash.subtitle': 'جارٍ تهيئة السمة والجلسة والمسودات المحلية.',
    
    // Login
    'login.eyebrow': 'البوابة المحمولة',
    'login.title1': 'المزيد من المستندات!',
    'login.title2': 'فكر في المسح.',
    'login.email': 'عنوان البريد الإلكتروني',
    'login.emailHint': 'example@company.tn',
    'login.password': 'كلمة المرور',
    'login.passwordHint': 'أدخل كلمة المرور',
    'login.submit': 'تسجيل الدخول',
    'login.error': 'أدخل بريدك الإلكتروني وكلمة المرور.',
    'login.tuniflow': 'TuniFlow',
    'login.loginLabel': 'تسجيل الدخول',
    
    // OTP
    'otp.title': 'رمز التحقق',
    'otp.subtitle': 'أدخل الرمز المكون من 6 أرقام',
    'otp.submit': 'تحقق',
    'otp.resend': 'إعادة إرسال الرمز',
    
    // Navigation
    'nav.home': 'الرئيسية',
    'nav.scan': 'مسح',
    'nav.history': 'السجل',
    'nav.invoices': 'الفواتير',
    'nav.scannedInvoices': 'Factures web',

    // Portal
    'portal.eyebrow': 'Portail web',
    'portal.scannedInvoicesTitle': 'Factures scannees',
    'portal.scannedInvoicesSubtitle': 'Ouvre le dashboard web pour confirmer, signer et suivre les documents envoyes depuis le mobile.',
    'portal.openScannedInvoices': 'Ouvrir les factures scannees',
    
    // Theme
    'theme.toggle': 'تغيير السمة',
    'theme.light': 'السمة الفاتحة',
    'theme.dark': 'السمة الداكنة',
    
    // Language
    'language.change': 'تغيير اللغة',
    'language.french': 'Français',
    'language.english': 'English',
    'language.arabic': 'العربية',
  };
}
