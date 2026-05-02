# 🚀 Guide de Lancement Complet

## 📋 Prérequis

- ✅ Visual Studio (pour backend .NET)
- ✅ VS Code (pour frontend Angular et mobile Flutter)
- ✅ Flutter installé
- ✅ Node.js installé
- ✅ PostgreSQL actif

---

## 🎯 Lancement en 3 Étapes

### **Étape 1 : Lancer le Backend .NET** 🔧

#### Option A : Avec Visual Studio (Recommandé)

1. **Ouvrez Visual Studio**
2. **File** → **Open** → **Project/Solution**
3. Naviguez vers `C:\backendpfe\einvoicing`
4. Ouvrez le fichier `.sln` (solution)
5. **Appuyez sur F5** ou cliquez sur ▶️ **Start**

Le backend va démarrer et afficher :
```
Now listening on: https://localhost:5001
Now listening on: http://localhost:5000
```

#### Option B : Avec la Ligne de Commande

```bash
cd C:\backendpfe\einvoicing
dotnet run
```

**✅ Vérification** : 
- Ouvrez votre navigateur
- Allez sur `http://localhost:5001/api/invoices`
- Vous devriez voir les données JSON

---

### **Étape 2 : Lancer le Frontend Angular** 🌐

#### Dans VS Code (Terminal 1)

```bash
cd C:\frontendpfe\ey-invoice-portal
npm start
```

Ou :

```bash
cd C:\frontendpfe\ey-invoice-portal
ng serve
```

Le frontend va démarrer sur `http://localhost:4200`

**✅ Vérification** :
- Ouvrez `http://localhost:4200` dans votre navigateur
- Vous devriez voir la page de connexion

---

### **Étape 3 : Lancer l'Application Mobile Flutter** 📱

#### Dans VS Code (Terminal 2)

```bash
cd C:\mobile\ey_invoice_mobile
flutter pub get
flutter run -d chrome
```

**Choix de la plateforme** :

- **Chrome (Web)** : `flutter run -d chrome`
- **Windows** : `flutter run -d windows`
- **Android** : `flutter run -d android` (si émulateur actif)

**✅ Vérification** :
- L'application mobile s'ouvre
- Vous voyez l'écran de connexion

---

## 🖥️ Configuration Recommandée

### Fenêtre 1 : Visual Studio
```
┌─────────────────────────────────────┐
│ Visual Studio                       │
│                                     │
│ Backend .NET en cours d'exécution   │
│ Port: 5001                          │
│                                     │
│ Console: Logs du backend            │
└─────────────────────────────────────┘
```

### Fenêtre 2 : VS Code (Terminal 1)
```
┌─────────────────────────────────────┐
│ VS Code - Terminal 1                │
│                                     │
│ $ cd C:\frontendpfe\ey-invoice-portal│
│ $ npm start                         │
│                                     │
│ Angular Live Development Server     │
│ http://localhost:4200               │
└─────────────────────────────────────┘
```

### Fenêtre 3 : VS Code (Terminal 2)
```
┌─────────────────────────────────────┐
│ VS Code - Terminal 2                │
│                                     │
│ $ cd C:\mobile\ey_invoice_mobile    │
│ $ flutter run -d chrome             │
│                                     │
│ Flutter app running on Chrome       │
└─────────────────────────────────────┘
```

---

## 📊 Architecture Complète

```
┌─────────────────────────────────────┐
│  Frontend Angular (Port 4200)       │
│  http://localhost:4200              │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Mobile Flutter (Chrome/Windows)    │
│  Application mobile                 │
└──────────────┬──────────────────────┘
               │
               ↓ HTTP/REST
┌─────────────────────────────────────┐
│  Backend .NET (Port 5001)           │
│  https://localhost:5001/api         │
└──────────────┬──────────────────────┘
               │
               ↓ Entity Framework
┌─────────────────────────────────────┐
│  PostgreSQL Database                │
│  Base de données                    │
└─────────────────────────────────────┘
```

---

## 🧪 Tester l'Application Mobile

### 1. Connexion

1. L'app mobile s'ouvre sur l'écran de connexion
2. Entrez vos identifiants
3. Validez le code 2FA si nécessaire

### 2. Navigation

Vous verrez **4 onglets** en bas :

```
[🏠 Accueil] [📸 Scanner] [📜 Historique] [📄 Factures]
```

### 3. Tester le Module Factures

1. **Cliquez sur l'onglet "Factures"** (4ème onglet)
2. Vous devriez voir :
   - Statistiques (Total, Payées, En attente)
   - Liste des factures du backend
   - Barre de recherche
   - Bouton "+" pour créer

3. **Créer une facture** :
   - Cliquez sur le bouton "+"
   - Remplissez le formulaire
   - Cliquez sur "Créer la facture"
   - ✅ La facture apparaît dans la liste

4. **Modifier une facture** :
   - Cliquez sur une facture
   - Cliquez sur "Modifier"
   - Changez le statut
   - Cliquez sur "Mettre à jour"
   - ✅ Le changement est visible

5. **Supprimer une facture** :
   - Cliquez sur "Supprimer"
   - Confirmez
   - ✅ La facture disparaît

6. **Rechercher** :
   - Tapez dans la barre de recherche
   - ✅ Les résultats se filtrent en temps réel

---

## 🐛 Résolution de Problèmes

### Problème 1 : Backend ne démarre pas

**Erreur** : "Port already in use"

**Solution** :
```bash
# Trouver le processus sur le port 5001
netstat -ano | findstr :5001

# Tuer le processus (remplacez PID par le numéro)
taskkill /PID <PID> /F
```

### Problème 2 : Frontend ne démarre pas

**Erreur** : "Port 4200 is already in use"

**Solution** :
```bash
# Tuer le processus Angular
taskkill /F /IM node.exe

# Ou utiliser un autre port
ng serve --port 4201
```

### Problème 3 : Flutter - Erreur de connexion

**Erreur** : "Connection refused"

**Vérifications** :
1. Le backend est-il lancé ? → Vérifiez Visual Studio
2. L'URL est-elle correcte ? → `http://localhost:5001/api`
3. CORS est-il activé ? → Vérifiez le backend .NET

**Test manuel** :
```bash
# Tester l'API
curl http://localhost:5001/api/invoices

# Ou avec PowerShell
Invoke-RestMethod -Uri "http://localhost:5001/api/invoices" -Method Get
```

### Problème 4 : Liste de factures vide

**Causes** :
1. Pas de données dans la base
2. Endpoint incorrect
3. Erreur backend

**Solutions** :
1. Vérifiez les logs du backend dans Visual Studio
2. Testez l'API avec Postman : `GET http://localhost:5001/api/invoices`
3. Ajoutez des données de test dans PostgreSQL

---

## 📝 Commandes Utiles

### Backend .NET

```bash
# Lancer
cd C:\backendpfe\einvoicing
dotnet run

# Nettoyer et rebuilder
dotnet clean
dotnet build

# Voir les logs
dotnet run --verbosity detailed
```

### Frontend Angular

```bash
# Lancer
cd C:\frontendpfe\ey-invoice-portal
npm start

# Nettoyer
rm -rf node_modules
npm install

# Builder pour production
ng build --prod
```

### Mobile Flutter

```bash
# Lancer sur Chrome
cd C:\mobile\ey_invoice_mobile
flutter run -d chrome

# Lancer sur Windows
flutter run -d windows

# Nettoyer
flutter clean
flutter pub get

# Voir les appareils disponibles
flutter devices

# Logs
flutter logs
```

---

## ✅ Checklist de Démarrage

### Avant de Commencer

- [ ] PostgreSQL est actif
- [ ] Visual Studio est installé
- [ ] VS Code est installé
- [ ] Flutter est installé (`flutter --version`)
- [ ] Node.js est installé (`node --version`)

### Lancement

- [ ] Backend .NET lancé (Visual Studio)
- [ ] Frontend Angular lancé (VS Code Terminal 1)
- [ ] Mobile Flutter lancé (VS Code Terminal 2)

### Vérifications

- [ ] Backend accessible : `http://localhost:5001/api/invoices`
- [ ] Frontend accessible : `http://localhost:4200`
- [ ] Mobile lancé et connecté
- [ ] Onglet "Factures" visible
- [ ] Liste des factures affichée

---

## 🎯 Ordre de Lancement Recommandé

1. **PostgreSQL** (doit être déjà actif)
2. **Backend .NET** (Visual Studio - F5)
3. **Frontend Angular** (VS Code Terminal 1)
4. **Mobile Flutter** (VS Code Terminal 2)

**Temps total** : ~2-3 minutes

---

## 📱 Plateformes de Test

### Chrome (Recommandé pour débuter)

```bash
flutter run -d chrome
```

**Avantages** :
- ✅ Rapide à lancer
- ✅ Hot reload
- ✅ DevTools intégrés
- ✅ Pas besoin d'émulateur

### Windows Desktop

```bash
flutter run -d windows
```

**Avantages** :
- ✅ Application native
- ✅ Performances optimales
- ✅ Expérience desktop

### Android (Émulateur)

```bash
# Lancer l'émulateur d'abord
# Puis :
flutter run -d android
```

**Avantages** :
- ✅ Test mobile réel
- ✅ Fonctionnalités natives (caméra, etc.)

---

## 🔗 URLs Importantes

| Service | URL | Description |
|---------|-----|-------------|
| Backend .NET | `http://localhost:5001` | API REST |
| API Invoices | `http://localhost:5001/api/invoices` | Endpoint factures |
| Frontend Angular | `http://localhost:4200` | Application web |
| Mobile Flutter | Variable | Application mobile |

---

## 💡 Conseils

### Pour le Développement

1. **Gardez Visual Studio ouvert** pour voir les logs du backend
2. **Utilisez Chrome** pour le mobile (plus rapide)
3. **Hot Reload** : Appuyez sur `r` dans le terminal Flutter pour recharger
4. **DevTools** : Appuyez sur `d` pour ouvrir les DevTools Flutter

### Pour le Débogage

1. **Logs Backend** : Regardez la console Visual Studio
2. **Logs Frontend** : Regardez la console du navigateur (F12)
3. **Logs Mobile** : Regardez le terminal Flutter

### Pour les Tests

1. **Testez d'abord l'API** avec Postman ou curl
2. **Testez ensuite le frontend** Angular
3. **Testez enfin le mobile** Flutter

---

## 🎉 Résultat Final

Une fois tout lancé, vous aurez :

```
✅ Backend .NET actif (Port 5001)
✅ Frontend Angular actif (Port 4200)
✅ Mobile Flutter actif (Chrome/Windows)
✅ 3 applications connectées à la même base de données
✅ Synchronisation en temps réel
```

---

**Créé le** : 1 Mai 2026  
**Version** : 1.0.0

**Bon développement ! 🚀**
