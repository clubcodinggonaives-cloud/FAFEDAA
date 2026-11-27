# Plan d’implémentation FAFEDAA

Ce plan suit l’existant React/Vite et livre des incréments vérifiables. La vitrine actuelle reste la base ; aucun backend opérationnel n’est présumé.

## Étape 1 — Audit et assainissement du contenu

- Documenter l’état initial dans `docs/audit/INITIAL_AUDIT.md`.
- Corriger l’encodage défectueux, vérifier lint/build.
- Faire valider les faits institutionnels, les programmes et les coordonnées par FAFEDAA avant de les certifier sur le site.

## Étape 2 — Fondations de la vitrine

- Séparer progressivement les vues et contenus traduits pour faciliter maintenance et tests.
- Ajouter page 404, métadonnées par route, sitemap et robots après validation des URL et textes.
- Tester le menu et les formulaires au clavier et sur petits écrans ; optimiser images et ressources distantes après mesures.

## Étape 3 — Cadrage sécurité et données

- Définir les rôles, permissions, collecte minimale, consentement, rétention/suppression, journal d’audit, sauvegardes et procédure d’orientation.
- Choisir le backend/PostgreSQL et l’hébergement en fonction des contraintes de l’organisation, puis documenter le modèle et les menaces.
- Ne jamais placer de secrets serveur dans le bundle Vite ni exposer les dossiers bénéficiaires publiquement.

## Étape 4 — Demandes d’assistance

- Concevoir un formulaire minimal, traduisible, avec validation côté serveur et information de confidentialité approuvée.
- Enregistrer les demandes dans un stockage privé, produire un identifiant non devinable et un accusé de réception neutre.
- Mettre en place attribution, statuts, notes internes et historique derrière des contrôles d’accès serveur.
- Tester isolement des dossiers, permissions, erreurs, abus et parcours mobile avant toute mise en production.

## Étape 5 — Administration et contenus

- Ajouter authentification sécurisée et rôles d’abord, puis gestion des demandes.
- Étendre aux bénéficiaires, programmes, dons, partenaires, actualités et utilisateurs uniquement selon les besoins confirmés.
- Ajouter journalisation des actions privilégiées, exports contrôlés, règles de conservation et guide d’administration.

## Étape 6 — Validation et déploiement

- Ajouter tests unitaires, formulaires, routes, permissions et E2E adaptés aux flux livrés.
- Vérifier build, responsive, accessibilité et mesures Lighthouse sans promettre de scores non mesurés.
- Documenter environnements Vercel, variables, surveillance, sauvegardes et retour arrière ; déployer après revue des régressions critiques.

## Incrément de cette livraison

- Réalisé : audit initial et plan de modernisation.
- Réalisé : correction de l’encodage dans `src/App.jsx` et `index.html`, puis lint/build réussis.
- Réalisé : rafraîchissement du design responsive des pages publiques, clarification des formulaires et simplification de la page de soutien pour retirer les espaces vides et les options de paiement non confirmées.
- Bloqué par décision organisationnelle avant traitement réel : coordonnées officielles, activités confirmées, règles de protection, choix du backend et politique de données.
