import 'package:flutter/widgets.dart';

import '../models/scan_draft.dart';
import '../models/scan_supplier_match.dart';

class ScanTexts {
  ScanTexts._(this._languageCode);

  final String _languageCode;

  static ScanTexts of(BuildContext context) {
    return ScanTexts._(
      Localizations.localeOf(context).languageCode.toLowerCase(),
    );
  }

  Map<String, String> get _bundle => switch (_languageCode) {
    'ar' => _ar,
    'en' => _en,
    _ => _fr,
  };

  String t(String key) => _bundle[key] ?? _fr[key] ?? key;

  String documentTypeLabel(ScanDocumentType type) =>
      t('doc.${type.name}.label');

  String documentTypeDescription(ScanDocumentType type) =>
      t('doc.${type.name}.description');

  String documentTypeShort(ScanDocumentType type) {
    final key = 'doc.${type.name}.short';
    return _bundle[key] ?? _fr[key] ?? documentTypeLabel(type);
  }

  String draftStatusLabel(ScanDraftStatus status) => t('draft.${status.name}');

  String supplierStatusLabel(ScanSupplierStatus status) =>
      t('supplier.${status.name}.label');

  String supplierStatusNote(ScanSupplierStatus status) =>
      t('supplier.${status.name}.note');

  static const Map<String, String> _fr = <String, String>{
    'screen.title': 'Scanner vos documents',
    'screen.subtitle':
        'Choisissez le type de document, prenez une photo puis vérifiez les champs avant envoi.',
    'screen.sourceTitle': 'Choisissez votre source',
    'screen.sourceReady':
        'Le scan envoie l’image au serveur puis PaddleOCR retourne les champs avec leurs scores.',
    'screen.sourceUnavailable':
        'Le service de scan n’est pas disponible pour le moment.',
    'screen.documentType': 'Type de document',
    'screen.documentTypeHint':
        'Choisissez le type le plus proche pour améliorer l’extraction.',
    'screen.camera': 'Prendre une photo',
    'screen.gallery': 'Importer depuis la galerie',
    'screen.flowTitle': 'Flux mobile',
    'screen.flow1Title': 'Capture',
    'screen.flow1Text': 'Caméra ou depuis votre galerie',
    'screen.flow2Title': 'Extraction des données',
    'screen.flow2Text': 'Extraction des champs et calcul du score de validité',
    'screen.flow3Title': 'Interprétation',
    'screen.flow3Text':
        'Vert : > 70%\nOrange : À vérifier\nRouge : Champ requis manquant',
    'screen.flow3Good': '> 70%',
    'screen.flow3Review': 'À vérifier',
    'screen.flow3Required': 'Champ requis manquant',
    'screen.flow4Title': 'Envoi au dashboard',
    'screen.flow4Text': 'Le document passe à la validation du comptable',
    'screen.latestDraft': 'Dernier brouillon',
    'screen.openDraft': 'Ouvrir la correction',
    'preview.title.new': 'Vérifier l’extraction',
    'preview.title.edit': 'Modifier le brouillon',
    'preview.confidence': '% global',
    'preview.detectedFields': 'Champs détectés',
    'preview.ruleSummary':
        'Vert à partir de 70%, orange à vérifier, rouge si le champ est absent.',
    'preview.required': 'Champ requis',
    'preview.optional': 'Optionnel',
    'preview.rawText': 'Texte OCR brut',
    'preview.rawTextEmpty': 'Aucun texte OCR brut retourné.',
    'preview.saveDraft': 'Enregistrer le brouillon',
    'preview.submit': 'Valider et envoyer',
    'preview.blocking':
        'Complétez les champs obligatoires en rouge avant l’envoi.',
    'preview.sentDefault': 'Document envoyé pour vérification.',
    'preview.badge.blocking': 'Bloquant',
    'preview.badge.fill': 'À renseigner',
    'preview.badge.review': 'À vérifier',
    'preview.badge.good': 'Fiable',
    'preview.supplierTitle': 'Fournisseur',
    'preview.supplierAction': 'Confirmer le fournisseur',
    'preview.supplierRefresh': 'Relancer la recherche',
    'preview.supplierManual': 'Chercher manuellement',
    'preview.supplierRequired': 'Confirmez le fournisseur avant l’envoi.',
    'preview.successBody': 'Le comptable va vérifier cette dépense côté web.',
    'success.title': 'Envoyé avec succès',
    'success.body':
        'Le document a été transmis au dashboard web avec le statut à vérifier.',
    'success.scanAnother': 'Scanner un autre document',
    'success.recent': 'Voir mes envois récents',
    'supplier.unresolved.label': 'À confirmer',
    'supplier.unresolved.note':
        'Le fournisseur détecté doit encore être confirmé.',
    'supplier.autoMatched.label': 'Reconnu automatiquement',
    'supplier.autoMatched.note': 'Le fournisseur existe déjà dans votre base.',
    'supplier.needsChoice.label': 'Choix requis',
    'supplier.needsChoice.note':
        'Plusieurs fournisseurs ressemblent au résultat OCR.',
    'supplier.notFound.label': 'Non trouvé',
    'supplier.notFound.note': 'Aucun fournisseur correspondant n’a été trouvé.',
    'supplier.created.label': 'Créé',
    'supplier.created.note': 'Le fournisseur a été créé à partir du scan.',
    'supplier.confirmed.label': 'Confirmé',
    'supplier.confirmed.note':
        'Le fournisseur choisi sera envoyé avec la dépense.',
    'supplier.sheet.title': 'Choisir le fournisseur',
    'supplier.sheet.subtitle':
        'Recherchez, confirmez ou créez le fournisseur avant l’envoi.',
    'supplier.sheet.searchLabel': 'Nom du fournisseur',
    'supplier.sheet.searchHint': 'Ex. ABC SARL',
    'supplier.sheet.searchAction': 'Rechercher',
    'supplier.sheet.createAction': 'Créer ce fournisseur',
    'supplier.sheet.close': 'Fermer',
    'supplier.sheet.noResult': 'Aucun résultat pour ce fournisseur.',
    'supplier.sheet.candidates': 'Résultats disponibles',
    'supplier.sheet.use': 'Choisir',
    'supplier.sheet.matching': 'Recherche du fournisseur…',
    'draft.extracted': 'Extrait',
    'draft.reviewed': 'Brouillon',
    'draft.validated': 'Envoyé',
    'doc.facture.label': 'Facture',
    'doc.facture.description':
        'Facture achat/vente avec parties, TVA, echeance et totaux.',
    'doc.facture.short': 'Facture',
    'doc.proforma.label': 'Facture proforma',
    'doc.proforma.description': 'Proforma commerciale non comptable.',
    'doc.proforma.short': 'Proforma',
    'doc.avoir.label': 'Avoir',
    'doc.avoir.description': 'Avoir ou note de credit.',
    'doc.avoir.short': 'Avoir',
    'doc.devis.label': 'Devis',
    'doc.devis.description': 'Offre de prix avec client et montants.',
    'doc.devis.short': 'Devis',
    'doc.bonCommande.label': 'Bon de commande',
    'doc.bonCommande.description':
        'Commande fournisseur/client, articles et quantites.',
    'doc.bonCommande.short': 'Commande',
    'doc.bonLivraison.label': 'Bon de livraison',
    'doc.bonLivraison.description':
        'BL avec emetteur, destinataire, articles et totaux.',
    'doc.bonLivraison.short': 'BL',
    'doc.bonSortie.label': 'Bon de sortie',
    'doc.bonSortie.description': 'Sortie de stock ou sortie interne.',
    'doc.bonSortie.short': 'Sortie',
    'doc.paiementRecu.label': 'Paiement recu',
    'doc.paiementRecu.description':
        'Encaissement client, reference et montant.',
    'doc.paiementRecu.short': 'Encaissement',
    'doc.paiementEmis.label': 'Paiement emis',
    'doc.paiementEmis.description':
        'Decaissement fournisseur, reference et montant.',
    'doc.paiementEmis.short': 'Decaissement',
    'doc.ordreFabrication.label': 'Ordre de fabrication',
    'doc.ordreFabrication.description': 'Ordre de production interne.',
    'doc.ordreFabrication.short': 'Fabrication',
    'doc.supplierInvoice.label': 'Facture fournisseur',
    'doc.supplierInvoice.description':
        'TVA, fournisseur, numéro, échéance et montants.',
    'doc.supplierInvoice.short': 'TVA, fournisseur, échéance',
    'doc.cashReceipt.label': 'Ticket restaurant / caisse',
    'doc.cashReceipt.description':
        'Enseigne, date, heure, total TTC et mode de paiement.',
    'doc.cashReceipt.short': 'Enseigne, date, total TTC',
    'doc.paymentReceipt.label': 'Reçu de paiement',
    'doc.paymentReceipt.description':
        'Référence, montant, bénéficiaire et mode de paiement.',
    'doc.paymentReceipt.short': 'Référence, montant, paiement',
    'doc.deliveryNote.label': 'Bon de livraison',
    'doc.deliveryNote.description':
        'Numéro BL, date, fournisseur et commande liée.',
    'doc.deliveryNote.short': 'BL, date, fournisseur',
    'doc.expenseReport.label': 'Note de frais',
    'doc.expenseReport.description': 'Nature de dépense, date et montant TTC.',
    'doc.expenseReport.short': 'Dépense, date, montant TTC',
    'doc.bankStatement.label': 'Relevé bancaire',
    'doc.bankStatement.description': 'IBAN et période du relevé.',
    'doc.bankStatement.short': 'IBAN, période, opérations',
    'doc.creditNote.label': 'Avoir',
    'doc.creditNote.description': 'Montants, référence et fournisseur.',
    'doc.creditNote.short': 'Avoir',
    'doc.quote.label': 'Devis',
    'doc.quote.description': 'Montant, client et référence devis.',
    'doc.quote.short': 'Devis',
    'doc.purchaseOrder.label': 'Bon de commande',
    'doc.purchaseOrder.description':
        'Numéro de commande, articles et quantités.',
    'doc.purchaseOrder.short': 'Bon de commande',
    'doc.other.label': 'Autre',
    'doc.other.description': 'Type de document non répertorié.',
    'doc.other.short': 'Autre',
  };

  static const Map<String, String> _en = <String, String>{
    'screen.title': 'Scan your documents',
    'screen.subtitle':
        'Choose the document type, take a picture, then review the fields before sending.',
    'screen.sourceTitle': 'Choose your source',
    'screen.sourceReady':
        'The scan uploads the image to the server, then PaddleOCR returns the extracted fields and scores.',
    'screen.sourceUnavailable': 'The scan service is currently unavailable.',
    'screen.documentType': 'Document type',
    'screen.documentTypeHint':
        'Pick the closest type to improve extraction quality.',
    'screen.camera': 'Take a photo',
    'screen.gallery': 'Import from gallery',
    'screen.flowTitle': 'Mobile flow',
    'screen.flow1Title': 'Capture',
    'screen.flow1Text': 'Camera or from your gallery',
    'screen.flow2Title': 'Data extraction',
    'screen.flow2Text': 'Field extraction and validity score calculation',
    'screen.flow3Title': 'Interpretation',
    'screen.flow3Text':
        'Green: > 70%\nOrange: To review\nRed: Required field missing',
    'screen.flow3Good': '> 70%',
    'screen.flow3Review': 'To review',
    'screen.flow3Required': 'Required field missing',
    'screen.flow4Title': 'Send to dashboard',
    'screen.flow4Text': 'The document moves to accountant validation',
    'screen.latestDraft': 'Latest draft',
    'screen.openDraft': 'Open review',
    'preview.title.new': 'Review extraction',
    'preview.title.edit': 'Edit draft',
    'preview.confidence': '% overall',
    'preview.detectedFields': 'Detected fields',
    'preview.ruleSummary':
        'Green at 70%+, orange for review, red when the field is missing.',
    'preview.required': 'Required field',
    'preview.optional': 'Optional',
    'preview.rawText': 'Raw OCR text',
    'preview.rawTextEmpty': 'No raw OCR text returned.',
    'preview.saveDraft': 'Save draft',
    'preview.submit': 'Validate and send',
    'preview.blocking': 'Complete the required red fields before sending.',
    'preview.sentDefault': 'Document sent for review.',
    'preview.badge.blocking': 'Blocking',
    'preview.badge.fill': 'To fill',
    'preview.badge.review': 'Review',
    'preview.badge.good': 'Reliable',
    'preview.supplierTitle': 'Supplier',
    'preview.supplierAction': 'Confirm supplier',
    'preview.supplierRefresh': 'Run match again',
    'preview.supplierManual': 'Search manually',
    'preview.supplierRequired': 'Confirm the supplier before sending.',
    'preview.successBody':
        'The accountant will review this expense on the web.',
    'success.title': 'Sent successfully',
    'success.body':
        'The document was sent to the web dashboard with pending review status.',
    'success.scanAnother': 'Scan another document',
    'success.recent': 'View recent submissions',
    'supplier.unresolved.label': 'To confirm',
    'supplier.unresolved.note':
        'The detected supplier still needs confirmation.',
    'supplier.autoMatched.label': 'Matched automatically',
    'supplier.autoMatched.note':
        'The supplier already exists in your directory.',
    'supplier.needsChoice.label': 'Choice required',
    'supplier.needsChoice.note':
        'Multiple suppliers look close to the OCR result.',
    'supplier.notFound.label': 'Not found',
    'supplier.notFound.note': 'No supplier matched the scanned data.',
    'supplier.created.label': 'Created',
    'supplier.created.note': 'The supplier was created from this scan.',
    'supplier.confirmed.label': 'Confirmed',
    'supplier.confirmed.note':
        'The selected supplier will be sent with the expense.',
    'supplier.sheet.title': 'Choose supplier',
    'supplier.sheet.subtitle':
        'Search, confirm or create the supplier before sending.',
    'supplier.sheet.searchLabel': 'Supplier name',
    'supplier.sheet.searchHint': 'Ex. ABC LLC',
    'supplier.sheet.searchAction': 'Search',
    'supplier.sheet.createAction': 'Create this supplier',
    'supplier.sheet.close': 'Close',
    'supplier.sheet.noResult': 'No result for this supplier.',
    'supplier.sheet.candidates': 'Available matches',
    'supplier.sheet.use': 'Select',
    'supplier.sheet.matching': 'Searching supplier…',
    'draft.extracted': 'Extracted',
    'draft.reviewed': 'Draft',
    'draft.validated': 'Sent',
    'doc.facture.label': 'Invoice',
    'doc.facture.description':
        'Purchase/sales invoice with parties, VAT, due date and totals.',
    'doc.facture.short': 'Invoice',
    'doc.proforma.label': 'Proforma invoice',
    'doc.proforma.description': 'Commercial proforma, not posted by default.',
    'doc.proforma.short': 'Proforma',
    'doc.avoir.label': 'Credit note',
    'doc.avoir.description': 'Credit note or partial cancellation.',
    'doc.avoir.short': 'Credit note',
    'doc.devis.label': 'Quote',
    'doc.devis.description': 'Price offer with customer and totals.',
    'doc.devis.short': 'Quote',
    'doc.bonCommande.label': 'Purchase order',
    'doc.bonCommande.description':
        'Supplier/customer order, items and quantities.',
    'doc.bonCommande.short': 'Order',
    'doc.bonLivraison.label': 'Delivery note',
    'doc.bonLivraison.description':
        'Delivery note with issuer, recipient, items and totals.',
    'doc.bonLivraison.short': 'Delivery note',
    'doc.bonSortie.label': 'Stock issue note',
    'doc.bonSortie.description': 'Stock issue or internal output document.',
    'doc.bonSortie.short': 'Issue note',
    'doc.paiementRecu.label': 'Payment received',
    'doc.paiementRecu.description':
        'Customer collection, reference and amount.',
    'doc.paiementRecu.short': 'Collection',
    'doc.paiementEmis.label': 'Payment sent',
    'doc.paiementEmis.description': 'Supplier payment, reference and amount.',
    'doc.paiementEmis.short': 'Payment',
    'doc.ordreFabrication.label': 'Manufacturing order',
    'doc.ordreFabrication.description': 'Internal production order.',
    'doc.ordreFabrication.short': 'Manufacturing',
    'doc.supplierInvoice.label': 'Supplier invoice',
    'doc.supplierInvoice.description':
        'VAT, supplier, number, due date and totals.',
    'doc.supplierInvoice.short': 'VAT, supplier, due date',
    'doc.cashReceipt.label': 'Cash / restaurant receipt',
    'doc.cashReceipt.description':
        'Merchant, date, time, total and payment method.',
    'doc.cashReceipt.short': 'Merchant, date, total',
    'doc.paymentReceipt.label': 'Payment receipt',
    'doc.paymentReceipt.description':
        'Reference, amount, beneficiary and payment method.',
    'doc.paymentReceipt.short': 'Reference, amount, payment',
    'doc.deliveryNote.label': 'Delivery note',
    'doc.deliveryNote.description':
        'Delivery note number, date, supplier and linked order.',
    'doc.deliveryNote.short': 'Number, date, supplier',
    'doc.expenseReport.label': 'Expense report',
    'doc.expenseReport.description': 'Expense type, date and total amount.',
    'doc.expenseReport.short': 'Type, date, total',
    'doc.bankStatement.label': 'Bank statement',
    'doc.bankStatement.description': 'IBAN and statement period.',
    'doc.bankStatement.short': 'IBAN, period, transactions',
    'doc.creditNote.label': 'Credit note',
    'doc.creditNote.description': 'Amounts, reference and supplier.',
    'doc.creditNote.short': 'Credit note',
    'doc.quote.label': 'Quote',
    'doc.quote.description': 'Amount, customer and quote reference.',
    'doc.quote.short': 'Quote',
    'doc.purchaseOrder.label': 'Purchase order',
    'doc.purchaseOrder.description': 'Order number, items and quantities.',
    'doc.purchaseOrder.short': 'Purchase order',
    'doc.other.label': 'Other',
    'doc.other.description': 'Unlisted document type.',
    'doc.other.short': 'Other',
  };

  static const Map<String, String> _ar = <String, String>{
    'screen.title': 'امسح مستنداتك',
    'screen.subtitle':
        'اختر نوع المستند ثم التقط صورة وراجع الحقول قبل الإرسال.',
    'screen.sourceTitle': 'اختر مصدر المستند',
    'screen.sourceReady':
        'يتم رفع الصورة إلى الخادم ثم يعيد PaddleOCR الحقول مع نسب الثقة.',
    'screen.sourceUnavailable': 'خدمة المسح غير متاحة حالياً.',
    'screen.documentType': 'نوع المستند',
    'screen.documentTypeHint': 'اختر أقرب نوع لتحسين جودة الاستخراج.',
    'screen.camera': 'التقاط صورة',
    'screen.gallery': 'استيراد من المعرض',
    'screen.flowTitle': 'تدفق الجوال',
    'screen.flow1Title': 'التقاط',
    'screen.flow1Text': 'الكاميرا أو من معرض الصور',
    'screen.flow2Title': 'استخراج البيانات',
    'screen.flow2Text': 'استخراج الحقول وحساب درجة الصحة',
    'screen.flow3Title': 'تفسير النتائج',
    'screen.flow3Text':
        'أخضر: > 70%\nبرتقالي: يحتاج مراجعة\nأحمر: حقل مطلوب ناقص',
    'screen.flow3Good': '> 70%',
    'screen.flow3Review': 'يحتاج مراجعة',
    'screen.flow3Required': 'حقل مطلوب ناقص',
    'screen.flow4Title': 'الإرسال إلى اللوحة',
    'screen.flow4Text': 'ينتقل المستند إلى تحقق المحاسب',
    'screen.latestDraft': 'آخر مسودة',
    'screen.openDraft': 'فتح المراجعة',
    'preview.title.new': 'مراجعة الاستخراج',
    'preview.title.edit': 'تعديل المسودة',
    'preview.confidence': '% إجمالي',
    'preview.detectedFields': 'الحقول المستخرجة',
    'preview.ruleSummary':
        'الأخضر من 70%، البرتقالي للمراجعة، والأحمر عند غياب الحقل.',
    'preview.required': 'حقل مطلوب',
    'preview.optional': 'اختياري',
    'preview.rawText': 'النص الخام من OCR',
    'preview.rawTextEmpty': 'لم يتم إرجاع نص OCR خام.',
    'preview.saveDraft': 'حفظ المسودة',
    'preview.submit': 'تأكيد وإرسال',
    'preview.blocking': 'أكمل الحقول الحمراء المطلوبة قبل الإرسال.',
    'preview.sentDefault': 'تم إرسال المستند للمراجعة.',
    'preview.badge.blocking': 'مطلوب',
    'preview.badge.fill': 'يحتاج تعبئة',
    'preview.badge.review': 'للمراجعة',
    'preview.badge.good': 'موثوق',
    'preview.supplierTitle': 'المورد',
    'preview.supplierAction': 'تأكيد المورد',
    'preview.supplierRefresh': 'إعادة المطابقة',
    'preview.supplierManual': 'بحث يدوي',
    'preview.supplierRequired': 'أكد المورد قبل الإرسال.',
    'preview.successBody': 'سيقوم المحاسب بمراجعة هذا المصروف على الويب.',
    'success.title': 'تم الإرسال بنجاح',
    'success.body': 'تم إرسال المستند إلى لوحة الويب بحالة بانتظار المراجعة.',
    'success.scanAnother': 'مسح مستند آخر',
    'success.recent': 'عرض الإرسالات الأخيرة',
    'supplier.unresolved.label': 'بانتظار التأكيد',
    'supplier.unresolved.note': 'يجب تأكيد المورد المكتشف قبل الإرسال.',
    'supplier.autoMatched.label': 'تمت المطابقة تلقائياً',
    'supplier.autoMatched.note': 'المورد موجود بالفعل في قاعدة البيانات.',
    'supplier.needsChoice.label': 'يلزم اختيار',
    'supplier.needsChoice.note': 'هناك عدة موردين مشابهين لنتيجة OCR.',
    'supplier.notFound.label': 'غير موجود',
    'supplier.notFound.note': 'لم يتم العثور على مورد مطابق.',
    'supplier.created.label': 'تم الإنشاء',
    'supplier.created.note': 'تم إنشاء المورد من هذا المسح.',
    'supplier.confirmed.label': 'تم التأكيد',
    'supplier.confirmed.note': 'سيتم إرسال المورد المختار مع المصروف.',
    'supplier.sheet.title': 'اختيار المورد',
    'supplier.sheet.subtitle': 'ابحث أو أكد أو أنشئ المورد قبل الإرسال.',
    'supplier.sheet.searchLabel': 'اسم المورد',
    'supplier.sheet.searchHint': 'مثال: ABC SARL',
    'supplier.sheet.searchAction': 'بحث',
    'supplier.sheet.createAction': 'إنشاء هذا المورد',
    'supplier.sheet.close': 'إغلاق',
    'supplier.sheet.noResult': 'لا توجد نتائج لهذا المورد.',
    'supplier.sheet.candidates': 'النتائج المتاحة',
    'supplier.sheet.use': 'اختيار',
    'supplier.sheet.matching': 'جارٍ البحث عن المورد…',
    'draft.extracted': 'مستخرج',
    'draft.reviewed': 'مسودة',
    'draft.validated': 'تم الإرسال',
    'doc.facture.label': 'Facture',
    'doc.facture.description':
        'Facture achat/vente avec parties, TVA, echeance et totaux.',
    'doc.facture.short': 'Facture',
    'doc.proforma.label': 'Facture proforma',
    'doc.proforma.description': 'Proforma commerciale non comptable.',
    'doc.proforma.short': 'Proforma',
    'doc.avoir.label': 'Avoir',
    'doc.avoir.description': 'Avoir ou note de credit.',
    'doc.avoir.short': 'Avoir',
    'doc.devis.label': 'Devis',
    'doc.devis.description': 'Offre de prix avec client et montants.',
    'doc.devis.short': 'Devis',
    'doc.bonCommande.label': 'Bon de commande',
    'doc.bonCommande.description':
        'Commande fournisseur/client, articles et quantites.',
    'doc.bonCommande.short': 'Commande',
    'doc.bonLivraison.label': 'Bon de livraison',
    'doc.bonLivraison.description':
        'BL avec emetteur, destinataire, articles et totaux.',
    'doc.bonLivraison.short': 'BL',
    'doc.bonSortie.label': 'Bon de sortie',
    'doc.bonSortie.description': 'Sortie de stock ou sortie interne.',
    'doc.bonSortie.short': 'Sortie',
    'doc.paiementRecu.label': 'Paiement recu',
    'doc.paiementRecu.description':
        'Encaissement client, reference et montant.',
    'doc.paiementRecu.short': 'Encaissement',
    'doc.paiementEmis.label': 'Paiement emis',
    'doc.paiementEmis.description':
        'Decaissement fournisseur, reference et montant.',
    'doc.paiementEmis.short': 'Decaissement',
    'doc.ordreFabrication.label': 'Ordre de fabrication',
    'doc.ordreFabrication.description': 'Ordre de production interne.',
    'doc.ordreFabrication.short': 'Fabrication',
    'doc.supplierInvoice.label': 'فاتورة مورد',
    'doc.supplierInvoice.description':
        'ضريبة القيمة المضافة، المورد، الرقم، الاستحقاق والإجماليات.',
    'doc.supplierInvoice.short': 'المورد، الاستحقاق، الضريبة',
    'doc.cashReceipt.label': 'إيصال مطعم / صندوق',
    'doc.cashReceipt.description':
        'اسم الجهة، التاريخ، الوقت، الإجمالي وطريقة الدفع.',
    'doc.cashReceipt.short': 'الجهة، التاريخ، الإجمالي',
    'doc.paymentReceipt.label': 'إيصال دفع',
    'doc.paymentReceipt.description': 'المرجع، المبلغ، المستفيد وطريقة الدفع.',
    'doc.paymentReceipt.short': 'المرجع، المبلغ، الدفع',
    'doc.deliveryNote.label': 'إذن تسليم',
    'doc.deliveryNote.description':
        'رقم الإذن، التاريخ، المورد والطلب المرتبط.',
    'doc.deliveryNote.short': 'رقم، تاريخ، مورد',
    'doc.expenseReport.label': 'تقرير مصروف',
    'doc.expenseReport.description': 'نوع المصروف، التاريخ والمبلغ الإجمالي.',
    'doc.expenseReport.short': 'نوع، تاريخ، مبلغ',
    'doc.bankStatement.label': 'كشف بنكي',
    'doc.bankStatement.description': 'رقم IBAN وفترة الكشف.',
    'doc.bankStatement.short': 'IBAN، الفترة، العمليات',
    'doc.creditNote.label': 'إشعار دائن',
    'doc.creditNote.description': 'المبالغ، المرجع والمورد.',
    'doc.creditNote.short': 'إشعار دائن',
    'doc.quote.label': 'عرض سعر',
    'doc.quote.description': 'المبلغ، العميل ومرجع العرض.',
    'doc.quote.short': 'عرض سعر',
    'doc.purchaseOrder.label': 'أمر شراء',
    'doc.purchaseOrder.description': 'رقم الطلب، الأصناف والكميات.',
    'doc.purchaseOrder.short': 'أمر شراء',
    'doc.other.label': 'أخرى',
    'doc.other.description': 'نوع مستند غير مدرج.',
    'doc.other.short': 'أخرى',
  };
}
