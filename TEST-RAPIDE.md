# 🧪 Test Rapide - Module Factures

## ⚡ Test en 5 Minutes

### 1. Lancer le Backend (1 min)

```bash
cd C:\backendpfe\einvoicing
mvn spring-boot:run
```

Attendez de voir : `Started Application in X seconds`

### 2. Lancer l'App Mobile (1 min)

```bash
cd C:\mobile\ey_invoice_mobile
flutter run -d chrome
```

### 3. Se Connecter (30 sec)

- Email : Votre email de test
- Password : Votre mot de passe
- Code 2FA : Si demandé

### 4. Tester le Module Factures (2 min 30)

#### A. Voir la Liste (10 sec)
1. Cliquez sur l'onglet **"Factures"** (4ème onglet en bas)
2. Vous devriez voir les factures du backend

#### B. Créer une Facture (1 min)
1. Cliquez sur le bouton **"+"** en haut à droite
2. Remplissez :
   - Numéro : `TEST-001`
   - Client : `Test Client`
   - Montant : `1000`
   - Statut : `En attente`
3. Cliquez sur **"Créer la facture"**
4. ✅ La facture apparaît dans la liste

#### C. Modifier une Facture (40 sec)
1. Cliquez sur une facture
2. Cliquez sur **"Modifier"**
3. Changez le statut en **"Payée"**
4. Cliquez sur **"Mettre à jour"**
5. ✅ Le statut est mis à jour

#### D. Rechercher (20 sec)
1. Tapez dans la barre de recherche : `TEST`
2. ✅ Les résultats se filtrent

#### E. Supprimer (20 sec)
1. Cliquez sur **"Supprimer"** sur une facture
2. Confirmez
3. ✅ La facture disparaît

---

## ✅ Résultat Attendu

Si tout fonctionne, vous devriez avoir :

- ✅ 4 onglets dans la navigation (Accueil, Scanner, Historique, **Factures**)
- ✅ Liste des factures du backend affichée
- ✅ Statistiques (Total, Payées, En attente)
- ✅ Création de facture fonctionnelle
- ✅ Modification de facture fonctionnelle
- ✅ Suppression de facture fonctionnelle
- ✅ Recherche en temps réel

---

## 🐛 Si Ça Ne Marche Pas

### Problème 1 : Liste Vide

**Test** : Ouvrez dans le navigateur
```
http://localhost:8080/api/invoices
```

**Si vide** : Ajoutez des données de test dans PostgreSQL

**Si erreur** : Le backend n'est pas lancé

### Problème 2 : Erreur de Connexion

**Vérifiez** :
```bash
# Test avec curl
curl http://localhost:8080/api/invoices

# Ou avec PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/api/invoices" -Method Get
```

**Si erreur** : Vérifiez CORS dans le backend

### Problème 3 : Onglet Factures Absent

**Solution** : Relancez l'application
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📊 Captures d'Écran Attendues

### Onglet Factures
```
┌─────────────────────────────────────┐
│ Factures Backend        🔄 +        │
│ Liste complète depuis l'API         │
├─────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │  5   │ │  3   │ │  2   │         │
│ │Total │ │Payées│ │Attent│         │
│ └──────┘ └──────┘ └──────┘         │
│                                     │
│ 🔍 Rechercher...                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ INV-001          [Payée]        │ │
│ │ Client A                        │ │
│ │ 1500.00 EUR • 01/05/2026        │ │
│ │ [Modifier] [Supprimer]          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ INV-002          [En attente]   │ │
│ │ Client B                        │ │
│ │ 2500.00 EUR • 15/04/2026        │ │
│ │ [Modifier] [Supprimer]          │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ [🏠] [📸] [📜] [📄 Factures]        │
└─────────────────────────────────────┘
```

---

## ⏱️ Temps Total : 5 Minutes

- Backend : 1 min
- Mobile : 1 min
- Connexion : 30 sec
- Tests : 2 min 30

---

## 🎯 Checklist Rapide

- [ ] Backend lancé
- [ ] Mobile lancé
- [ ] Connecté
- [ ] Onglet "Factures" visible
- [ ] Liste affichée
- [ ] Création testée
- [ ] Modification testée
- [ ] Suppression testée
- [ ] Recherche testée

---

**Si tous les tests passent : Félicitations ! 🎉**

Votre application mobile est maintenant **complètement connectée** au backend !

---

**Créé le** : 1 Mai 2026  
**Version** : 1.0.0
