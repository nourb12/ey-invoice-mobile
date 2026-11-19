# TuniFlow Mobile

Application Flutter destinée aux collaborateurs qui consultent des factures et numérisent des pièces justificatives.

## Parcours disponibles

- Connexion, renouvellement de session, déconnexion et vérification 2FA.
- Consultation de la liste et du détail des factures via l'API TuniFlow.
- Capture caméra ou import d'une image, envoi au backend, extraction OCR, correction des champs et validation.
- Conservation locale des brouillons de scan et de leurs images pour reprendre une revue interrompue.
- Interfaces française, anglaise et arabe ; l'arabe utilise une disposition RTL.

## OCR

Le parcours de scan de cette application utilise le service OCR serveur : Flutter envoie l'image à `POST /api/scan/upload`, puis l'API transmet le traitement au service FastAPI/PaddleOCR. L'application ne lance pas de reconnaissance OCR locale avec ML Kit. Les champs extraits et leurs niveaux de confiance sont retournés à Flutter pour vérification humaine avant l'appel `POST /api/scan/validate`.

## Configuration

En développement, les URLs sont résolues depuis `api_config_dev.dart` et `portal_config_dev.dart`. Sur Android, le mobile doit joindre l'adresse du poste qui héberge l'API et le portail. On peut remplacer le nom/IP local avec `ANDROID_DEV_HOST` et `ANDROID_DEV_PORTAL_HOST`.

En release, fournir les deux URLs publiques explicitement :

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.example.tn/api `
  --dart-define=PORTAL_BASE_URL=https://app.example.tn
```

Ne pas livrer un binaire release configuré sur `localhost`, une adresse Wi-Fi privée ou un environnement de démonstration.

## Vérification locale

```powershell
flutter pub get
flutter analyze
flutter test
```

Les tests couvrent le modèle de facture, le client HTTP, les brouillons OCR, la direction arabe et les contrats upload/validation du flux de scan. Ils ne remplacent pas une recette manuelle sur appareil avec caméra, réseau réel et backend de test.

## Intégration continue

Le pipeline Jenkins exécute systématiquement `flutter analyze` et `flutter test`. Les commandes utilisent l'image Flutter configurée dans le `Jenkinsfile`.
