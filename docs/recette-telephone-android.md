# TuniFlow Mobile : installation et recette Android

## État réel

La recette physique n'a pas été exécutée : aucun téléphone Android n'était connecté lors de la vérification. Les tests automatisés ne remplacent pas les contrôles ci-dessous.
La compilation Android debug a réussi le 6 novembre 2026 : build/app/outputs/flutter-apk/app-debug.apk. Les 47 tests Flutter et 9 tests backend ciblés passent ; l'analyse Flutter ne signale pas d'anomalie.

## Installation de développement

1. Activer les options développeur et le débogage USB du téléphone.
2. Brancher le téléphone, autoriser cet ordinateur et vérifier sa présence avec `flutter devices`.
3. Utiliser un serveur accessible au téléphone. L'adresse localhost désigne le téléphone lui-même, pas le PC.
4. Construire avec `flutter build apk --debug --dart-define=API_BASE_URL=https://SERVEUR/api` et, si nécessaire, la configuration du portail prévue par le projet.
5. Installer avec `flutter install -d IDENTIFIANT_APPAREIL`. Un APK debug n'est pas une livraison de production signée.

## Parcours à contrôler

| Contrôle | Manipulation | Résultat attendu |
|---|---|---|
| Connexion | Compte autorisé, mot de passe erroné, code de sécurité incorrect | Messages compréhensibles, pas d'accès sans autorisation |
| Caméra | Autoriser, refuser, puis réautoriser dans les réglages | Capture possible ou échec explicite ; pas de blocage de navigation |
| Scanner | Document incliné puis recadrage et validation | Document complet et lisible ; repli photo sur appareil incompatible |
| Multipage | Capturer deux pages | Un PDF envoyé au service ; vérifier les informations reconnues avant envoi |
| Import | Choisir un PDF puis annuler le sélecteur | Import valide, ou retour normal sans faux message de succès |
| Clavier | Dates, nombres décimaux, dernier champ, clavier ouvert | Saisie utilisable ; actions accessibles sans chevauchement |
| Sauvegarde | Modifier, patienter, quitter puis rouvrir | Corrections conservées sur le compte concerné |
| Fournisseur | Choisir un tiers puis modifier son identité | Nouvelle confirmation exigée ; ancien compte bancaire non réutilisé |
| Types | Passer de facture à bon de sortie puis paiement | Champs obligatoires adaptés |
| Envoi | Couper le réseau après import, tenter l'envoi puis rétablir | Demande conservée et reprise dans l'application sans nouvelle transaction pour le même scan |
| Corrections | Ouvrir un formulaire ayant un envoi en attente | Reprise automatique suspendue pendant la correction |
| Notifications | Modifier sur le portail un justificatif envoyé par ce compte | Cloche et état actualisés au plus tard au prochain cycle de synchronisation en premier plan |
| Lecture | Marquer une notification lue, actualiser, redémarrer | Lecture conservée ; une nouvelle révision redevient non lue |
| Compte | Changer d'utilisateur ou d'entreprise | Aucun brouillon ni notification de l'autre compte |
| Suivi | Toucher une notification | État actuel et activité du document, ou message d'indisponibilité |
| Arabe | Langue arabe, clair/sombre, texte agrandi | Lecture RTL, références et montants LTR, aucun texte tronqué essentiel |
| Assistant | Question mobile avec sources, puis perte réseau | Réponse sourcée si guide validé ; erreur et nouvelle tentative sinon |

## Limites des notifications de ce lot

Il s'agit d'une boîte de notifications dans l'application, synchronisée toutes les 30 secondes au premier plan et au retour dans l'application. Le serveur fournit les 100 documents mobiles les plus récemment modifiés de l'utilisateur connecté dans son entreprise. La liste présente leur dernière révision connue, pas un journal exhaustif de chaque état intermédiaire.

Les états correspondent à un justificatif à corriger, en attente ou validé, pas à un accusé TTN. Le statut non lu est enregistré sur cet appareil par compte.

Les notifications système lorsque l'application est fermée ne sont pas implémentées : elles nécessitent un fournisseur push, ses identifiants, l'enregistrement des appareils et un mécanisme serveur de livraison/reprise.

## Preuves de recette

Pour chaque contrôle, relever appareil/version Android, version APK, date, compte de test, résultat et capture sans données personnelles. Ne pas marquer un contrôle « réussi » sans exécution réelle.
