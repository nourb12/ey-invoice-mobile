# 🚀 Lancement Simple - 3 Étapes

## ⚡ Démarrage Rapide

### 1️⃣ Backend .NET (Visual Studio)

**Ouvrez Visual Studio** :
1. File → Open → Project/Solution
2. Ouvrez `C:\backendpfe\einvoicing\*.sln`
3. **Appuyez sur F5** ▶️

✅ Vous verrez : `Now listening on: http://localhost:5001`

---

### 2️⃣ Frontend Angular (VS Code - Terminal 1)

**Ouvrez VS Code** :
1. Ouvrez le terminal (Ctrl + `)
2. Tapez :

```bash
cd C:\frontendpfe\ey-invoice-portal
npm start
```

✅ Vous verrez : `Angular Live Development Server is listening on localhost:4200`

---

### 3️⃣ Mobile Flutter (VS Code - Terminal 2)

**Dans VS Code** :
1. Ouvrez un **nouveau terminal** (Ctrl + Shift + `)
2. Tapez :

```bash
cd C:\mobile\ey_invoice_mobile
flutter run -d chrome
```

✅ L'application mobile s'ouvre dans Chrome

---

## 🎯 Tester le Mobile

### A. Connexion
1. Entrez vos identifiants
2. Validez le code 2FA

### B. Aller sur Factures
1. Cliquez sur l'onglet **"Factures"** (4ème onglet en bas)
2. Vous verrez la liste des factures

### C. Créer une Facture
1. Cliquez sur le bouton **"+"** en haut à droite
2. Remplissez :
   - Numéro : `TEST-001`
   - Client : `Test Client`
   - Montant : `1000`
3. Cliquez sur **"Créer la facture"**

✅ La facture apparaît dans la liste !

---

## 📊 Résumé Visuel

```
┌─────────────────────────────────────┐
│ Visual Studio                       │
│ Backend .NET (Port 5001)            │
│ ▶️ F5 pour lancer                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ VS Code - Terminal 1                │
│ Frontend Angular (Port 4200)        │
│ $ npm start                         │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ VS Code - Terminal 2                │
│ Mobile Flutter (Chrome)             │
│ $ flutter run -d chrome             │
└─────────────────────────────────────┘
```

---

## 🐛 Si Ça Ne Marche Pas

### Backend ne démarre pas ?
→ Vérifiez que PostgreSQL est actif

### Frontend ne démarre pas ?
→ Faites `npm install` d'abord

### Mobile ne se connecte pas ?
→ Vérifiez que le backend est lancé sur `http://localhost:5001`

---

## ✅ Checklist

- [ ] Visual Studio ouvert avec backend lancé
- [ ] VS Code Terminal 1 : Angular lancé
- [ ] VS Code Terminal 2 : Flutter lancé
- [ ] Mobile connecté et onglet "Factures" visible

---

**Temps total : 3 minutes** ⏱️

**C'est tout ! 🎉**
