# Améliorations mobile - 6 novembre 2026

## Périmètre livré dans ce lot

- Conservation des composants et du thème existants.
- Assistant relié à POST /knowledge-base/ask avec le jeton de session, historique des six derniers messages, sources, limite de saisie, délai maximal et nouvelle tentative.
- Bouton de discussion dans la navigation principale ; fenêtre à fond extérieur translucide. Conversation conservée tant que l'accueil connecté existe, sans stockage persistant.
- Confirmation de déconnexion.
- Recherche fournisseur/référence/montant et filtres Tous / À terminer / Envoyés dans l'historique local.
- Sauvegarde différée des champs de correction et confirmation au retour.
- Conservation du brouillon avant une tentative d'envoi.
- Priorité aux champs obligatoires manquants et aux champs à contrôler.
- Amélioration de la résolution des images galerie : 2400 px, qualité 92.
- Contraste des textes secondaires et tertiaires en thème clair.
- Remplacement de plusieurs termes techniques visibles et du nom de secours non traduit.
- Ajout d'un test de parité des clés FR/EN/AR.
- Guide mobile prêt à importer dans la base documentaire : assistant-mobile.md.

## Vérifications et limites

L'analyse Flutter et les tests automatisés ne remplacent pas la recette sur téléphone.
Les tests API existants emploient des réponses HTTP contrôlées ; ils ne prouvent pas la disponibilité d'un serveur réel.
L'assistant doit être testé avec un compte réel autorisé par RagUser ; le guide doit être importé et validé par l'administration avant recherche documentaire.
Ne pas annoncer que toute la liste validée est terminée.

## Compléments implémentés depuis le premier lot

- Scanner natif Android multipage avec repli caméra classique ; import PDF. Validation sur appareil encore nécessaire.
- Champs fiables repliables, aperçu repliable, dates au clavier/calendrier, suggestions de champs facultatifs, confirmation des champs incertains.
- Contrôles indicatifs de total simple, date, échéance, matricule et référence dupliquée ; pas de validation fiscale complète par ligne.
- Reclassification du document alignée sur les champs obligatoires du backend.
- Synchronisation du fournisseur choisi avec les champs et invalidation du rapprochement après modification de son identité.
- Reprise persistante des envois temporaires, avec attente exponentielle, suspendue pendant la correction. Seulement pour les documents déjà importés et tant que l'application tourne.
- Backend : répétition idempotente d'un même scan, refus des champs obligatoires manquants et contrôle de concurrence EF.
- Brouillons isolés par entreprise et utilisateur ; anciennes données non attribuées conservées sans migration automatique.
- Suivi authentifié par GET /api/expenses/{id}, actualisation, activité et véritables états du justificatif.
- Filtres locaux par période et type, retrait local annulable sans suppression serveur.
- Guide de scan replié après le premier document ; mot de passe oublié vers le portail.
- Police arabe Cairo, valeurs structurées LTR, montants et dates localisés, messages de connexion sans détails techniques.

## Travail restant réel du périmètre accepté

- Navigation Factures : les opérations de création/modification existantes lèvent encore une erreur indiquant un contrat incomplet. Les raccorder avant de les exposer.
- Contrôles de cohérence par ligne et facture, taxes, remises et net à payer.
- Capture initiale hors connexion : actuellement, une connexion reste nécessaire pour importer et lire le nouveau document.
- Biométrie et validation de sa politique de verrouillage ; aucun faux bouton de renvoi pour les codes générés par une application de sécurité.
- Audit RTL intégral sur appareil, y compris police téléchargée et clavier système.
- Notifications système lorsque l'application est fermée : fournisseur push et livraison serveur à configurer. La cloche interne est désormais raccordée au serveur.
- Recette des rôles, états vides, erreurs réseau, texte agrandi et thèmes sur appareil.

## Recette de ce lot

1. Modifier un champ, attendre une seconde et vérifier le brouillon après retour.
2. Quitter pendant la saisie : vérifier les choix et la reprise du brouillon.
3. Couper la connexion pendant un envoi : le brouillon doit rester disponible.
4. Rechercher un montant et une référence, puis combiner avec les filtres.
5. Ouvrir l'assistant, poser une question, consulter les sources, fermer et rouvrir.
6. Tester assistant avec réseau absent, compte non autorisé et jeton expiré.
7. Se déconnecter puis changer de compte : aucune conversation précédente ne doit apparaître.
8. Tester clavier ouvert, arabe RTL, thèmes clair/sombre et texte à 130 %.

## État des vérifications

- Tests Flutter : 47 tests réussis, dont notifications authentifiées, états non lus, isolation du cache, suspension de reprise pendant correction et synchronisation du fournisseur sans reprise de l'ancien compte bancaire.
- Backend : 9 tests ciblés réussis (soumission et notifications). Le test de concurrence utilise EF InMemory et ne remplace pas un test PostgreSQL connecté. Compilation API réussie ; analyse Flutter sans anomalie.
- Widgets : aperçu et historique testés à 360 px, texte 130 %, FR/EN/AR et clair/sombre. Ces tests emploient le thème de test et ne valident pas le chargement réel des polices.
- APK : compilation Android debug réussie après rétablissement de l'accès Google, le 6 novembre 2026. Fichier : build/app/outputs/flutter-apk/app-debug.apk. Installation et recette sur appareil non effectuées.
- Aucun appareil Android connecté ; caméra native, PDF multipage et assistant réel non recettés.
- Le stockage des brouillons utilise SharedPreferences et les fichiers privés de l'application ; ne pas le présenter comme un stockage chiffré.

## Mise à disposition du guide à l'assistant

Importer docs/assistant-mobile.md depuis la base documentaire avec un compte administrateur autorisé, puis valider le document. Le fichier local seul n'est pas indexé.
Contrat vérifié : POST /api/knowledge-base/import (multipart File, Title, Category, Source, PublishedAt), puis PATCH /api/knowledge-base/{id}/status avec {"status":"Valide"}. Ne pas utiliser le statut accentué "Validé", non reconnu par le service actuel.
Vérifier ensuite une question mobile via le service connecté et la présence du guide parmi les sources. Cette importation n'a pas été exécutée dans cette session.

## Notifications ajoutées

GET /api/mobile/document-updates fournit les dernières révisions des documents mobiles de l'utilisateur connecté, filtrées côté serveur par utilisateur et entreprise. Aucun identifiant d'entreprise fourni par le client n'est utilisé. Le statut de lecture est local, isolé par compte.
Une cloche avec compteur ouvre les états à corriger, en attente et validé. Actualisation manuelle, toutes les 30 secondes en premier plan et au retour dans l'application ; ouverture du suivi au toucher. Les erreurs réseau conservent le cache et sont signalées dans la liste.
Ce n'est pas un système push lorsque l'application est fermée, ni un journal exhaustif de tous les états intermédiaires. La liste couvre les 100 documents mobiles les plus récemment modifiés.
Guide utilisateur : assistant-mobile.md. Installation et protocole téléphone : recette-telephone-android.md.
