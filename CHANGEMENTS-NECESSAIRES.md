# 🔧 Changements Nécessaires - EY Invoice Mobile

## ✅ Ce Qui Est Déjà Parfait

### 1. Design & Thème
- ✅ Couleurs EY (#FFE600) parfaitement implémentées
- ✅ Mode clair/sombre fonctionnel
- ✅ Composants réutilisables (boutons, cartes, chips)
- ✅ Typographie cohérente (Google Fonts)
- ✅ Espacement et padding harmonieux

### 2. Authentification
- ✅ Écran de login professionnel
- ✅ Double authentification (2FA/OTP)
- ✅ Gestion de session avec Provider
- ✅ Déconnexion fonctionnelle

### 3. Scan OCR
- ✅ Capture photo (caméra + galerie)
- ✅ OCR local (Google ML Kit)
- ✅ Extraction Regex automatique
- ✅ Sauvegarde brouillons locaux
- ✅ Historique des scans

### 4. Navigation
- ✅ Bottom navigation bar (3 onglets)
- ✅ Transitions fluides
- ✅ État préservé entre onglets

### 5. Configuration
- ✅ URL API corrigée : `http://localhost:8080/api`
- ✅ Support multi-plateformes (Android, iOS, Web, Desktop)

---

## ❌ Ce Qui Manque (À Implémenter)

### 1. 🔴 CRITIQUE : Connexion Backend Factures

**Problème** : Les brouillons scannés restent uniquement sur le mobile, ils ne sont pas envoyés au backend.

**Solution** :

#### A. Créer le Modèle Invoice

**Fichier à créer** : `lib/features/invoices/models/invoice.dart`

```dart
class Invoice {
  final int? id;
  final String invoiceNumber;
  final String clientName;
  final double amount;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  
  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.issueDate,
    this.dueDate,
  });
  
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      clientName: json['clientName'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'amount': amount,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
```

#### B. Créer le Service API

**Fichier à créer** : `lib/features/invoices/services/invoice_api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';
import '../models/invoice.dart';

class InvoiceApiService {
  // GET - Toutes les factures
  Future<List<Invoice>> getAllInvoices() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/invoices'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    }
    throw Exception('Erreur: ${response.statusCode}');
  }
  
  // POST - Créer une facture
  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/invoices'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoice.toJson()),
    );
    
    if (response.statusCode == 201) {
      return Invoice.fromJson(json.decode(response.body));
    }
    throw Exception('Erreur: ${response.statusCode}');
  }
  
  // PUT - Mettre à jour
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/invoices/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoice.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    }
    throw Exception('Erreur: ${response.statusCode}');
  }
  
  // DELETE - Supprimer
  Future<void> deleteInvoice(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/invoices/$id'),
    );
    
    if (response.statusCode != 204) {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
}
```

#### C. Créer le Controller

**Fichier à créer** : `lib/features/invoices/controllers/invoices_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/invoice_api_service.dart';

class InvoicesController extends ChangeNotifier {
  final InvoiceApiService _apiService;
  
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  InvoicesController({required InvoiceApiService apiService})
      : _apiService = apiService;
  
  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _invoices = await _apiService.getAllInvoices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final created = await _apiService.createInvoice(invoice);
      _invoices.insert(0, created);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteInvoice(int id) async {
    try {
      await _apiService.deleteInvoice(id);
      _invoices.removeWhere((inv) => inv.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
```

---

### 2. 🟡 IMPORTANT : Écran Liste Factures

**Fichier à créer** : `lib/features/invoices/screens/invoices_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ey_components.dart';
import '../controllers/invoices_controller.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<InvoicesController>().loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ey;
    final textTheme = Theme.of(context).textTheme;
    final controller = context.watch<InvoicesController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Factures', style: textTheme.headlineMedium),
                    Text(
                      'Liste complète depuis le backend',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              EyIconAction(
                icon: Icons.refresh_rounded,
                onTap: () => controller.loadInvoices(),
                tooltip: 'Actualiser',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (controller.errorMessage != null)
            EySurfaceCard(
              child: Text(
                'Erreur: ${controller.errorMessage}',
                style: TextStyle(color: colors.error),
              ),
            )
          else if (controller.invoices.isEmpty)
            EySurfaceCard(
              child: Text(
                'Aucune facture trouvée',
                style: textTheme.bodyMedium,
              ),
            )
          else
            ...controller.invoices.map((invoice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EySurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNumber,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          EyStatusChip(
                            label: invoice.status,
                            tone: invoice.status == 'PAID'
                                ? EyStatusTone.ok
                                : EyStatusTone.warn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invoice.clientName,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.amount.toStringAsFixed(2)} € • ${DateFormat('dd/MM/yyyy').format(invoice.issueDate)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
```

---

### 3. 🟡 IMPORTANT : Ajouter l'Onglet Factures

**Modifier** : `lib/features/home/screens/mobile_home_shell.dart`

```dart
// Ajouter dans _MobileHomeShellState

final pages = <Widget>[
  DashboardScreen(...),
  const ScanScreen(),
  const ScanHistoryScreen(),
  const InvoicesListScreen(), // ← AJOUTER
];

// Dans le Row des _NavItem, ajouter :
_NavItem(
  icon: Icons.receipt_long_outlined,
  label: 'Factures',
  selected: _index == 3,
  onTap: () => setState(() => _index = 3),
),
```

---

### 4. 🟢 OPTIONNEL : Envoyer Brouillon au Backend

**Modifier** : `lib/features/scan/screens/scan_preview_screen.dart`

Ajouter un bouton "Envoyer au backend" qui :
1. Convertit le brouillon en Invoice
2. Appelle `createInvoice()`
3. Affiche un message de succès
4. Supprime le brouillon local

---

### 5. 🟢 OPTIONNEL : Recherche et Filtres

Ajouter dans `InvoicesListScreen` :
- Barre de recherche (par numéro, client)
- Filtres (statut, date, montant)
- Tri (date, montant, client)

---

## 📋 Checklist des Changements

### Phase 1 : Backend Connection (URGENT)

- [ ] Créer `lib/features/invoices/models/invoice.dart`
- [ ] Créer `lib/features/invoices/services/invoice_api_service.dart`
- [ ] Créer `lib/features/invoices/controllers/invoices_controller.dart`
- [ ] Tester la connexion API avec Postman
- [ ] Vérifier que le backend répond correctement

### Phase 2 : Interface Factures (IMPORTANT)

- [ ] Créer `lib/features/invoices/screens/invoices_list_screen.dart`
- [ ] Ajouter le Provider dans `app.dart`
- [ ] Modifier `mobile_home_shell.dart` pour ajouter l'onglet
- [ ] Tester l'affichage de la liste

### Phase 3 : Synchronisation (OPTIONNEL)

- [ ] Ajouter bouton "Envoyer au backend" dans preview
- [ ] Implémenter la conversion brouillon → facture
- [ ] Gérer les erreurs réseau
- [ ] Ajouter feedback utilisateur

### Phase 4 : Améliorations (OPTIONNEL)

- [ ] Recherche de factures
- [ ] Filtres avancés
- [ ] Export PDF
- [ ] Statistiques avancées

---

## 🎯 Priorités

### 🔴 URGENT (Aujourd'hui)

1. Créer le modèle `Invoice`
2. Créer le service `InvoiceApiService`
3. Tester la connexion API

### 🟡 IMPORTANT (Cette Semaine)

1. Créer l'écran liste factures
2. Ajouter l'onglet navigation
3. Tester le flux complet

### 🟢 OPTIONNEL (Plus Tard)

1. Synchronisation brouillons
2. Recherche et filtres
3. Export PDF

---

## 🔧 Modifications du Fichier app.dart

**Ajouter le Provider** :

```dart
// Dans lib/app/app.dart

import '../features/invoices/controllers/invoices_controller.dart';
import '../features/invoices/services/invoice_api_service.dart';

// Dans MultiProvider, ajouter :
ChangeNotifierProvider<InvoicesController>(
  create: (_) => InvoicesController(
    apiService: InvoiceApiService(),
  ),
  lazy: false,
),
```

---

## 📊 Résumé Visuel

### Ce Qui Existe ✅

```
┌─────────────────────────────────────┐
│ 🔐 Authentification                 │
│    ✅ Login                          │
│    ✅ 2FA/OTP                        │
│    ✅ Session                        │
├─────────────────────────────────────┤
│ 📸 Scan OCR                         │
│    ✅ Capture photo                  │
│    ✅ OCR local                      │
│    ✅ Extraction Regex               │
│    ✅ Brouillons locaux              │
├─────────────────────────────────────┤
│ 🎨 Design                           │
│    ✅ Thème EY                       │
│    ✅ Mode clair/sombre              │
│    ✅ Composants réutilisables       │
└─────────────────────────────────────┘
```

### Ce Qui Manque ❌

```
┌─────────────────────────────────────┐
│ 📄 Gestion Factures Backend         │
│    ❌ Liste factures API             │
│    ❌ Créer facture                  │
│    ❌ Modifier facture               │
│    ❌ Supprimer facture              │
├─────────────────────────────────────┤
│ 🔄 Synchronisation                  │
│    ❌ Envoyer brouillons au backend  │
│    ❌ Récupérer factures du backend  │
├─────────────────────────────────────┤
│ 🔍 Fonctionnalités Avancées         │
│    ❌ Recherche                      │
│    ❌ Filtres                        │
│    ❌ Export PDF                     │
└─────────────────────────────────────┘
```

---

## 🚀 Prochaines Étapes

### Étape 1 : Créer les Fichiers

```bash
# Créer la structure
mkdir -p lib/features/invoices/models
mkdir -p lib/features/invoices/services
mkdir -p lib/features/invoices/controllers
mkdir -p lib/features/invoices/screens

# Créer les fichiers
touch lib/features/invoices/models/invoice.dart
touch lib/features/invoices/services/invoice_api_service.dart
touch lib/features/invoices/controllers/invoices_controller.dart
touch lib/features/invoices/screens/invoices_list_screen.dart
```

### Étape 2 : Copier le Code

Copiez le code fourni ci-dessus dans chaque fichier.

### Étape 3 : Tester

```bash
# Lancer le backend
cd C:\backendpfe\einvoicing
mvn spring-boot:run

# Lancer l'app mobile
cd C:\mobile\ey_invoice_mobile
flutter run
```

---

## ✅ Validation

Une fois les changements effectués, vous devriez avoir :

1. ✅ Un 4ème onglet "Factures" dans la navigation
2. ✅ La liste des factures du backend affichée
3. ✅ Possibilité de rafraîchir la liste
4. ✅ Affichage des détails (numéro, client, montant, statut)
5. ✅ Gestion des erreurs réseau

---

**Créé le** : 1 Mai 2026  
**Auteur** : Assistant Kiro  
**Version** : 1.0.0

**Voulez-vous que je crée ces fichiers maintenant ?** 🚀
