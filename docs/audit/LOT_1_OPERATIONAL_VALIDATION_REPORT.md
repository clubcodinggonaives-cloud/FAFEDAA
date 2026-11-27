# Rapport de validation opérationnelle — Lot 1 Supabase

Date : 27 novembre 2026  
Statut global : **BLOCKED — migration, rollback et réapplication non exécutés**.

## Environnement observé

- Node.js : `v24.22.0` (**PASS**).
- npm : `11.19.1` (**PASS**).
- npx : `11.19.1` (**PASS**, commande disponible).
- Supabase CLI globale : absente.
- Tentative `npx.cmd --yes supabase --version` : téléchargement/exécution non terminé après environ 90 secondes; processus interrompu. CLI non validée (**BLOCKED**).
- Docker est présent, mais le daemon ne répond pas; aucun `psql` ni serveur PostgreSQL local n'est disponible.
- `supabase/config.toml` se parse comme TOML valide.
- Le fichier `.env` local n'est pas suivi par Git. Il ne contient pas de variable de clé serveur détectée; il a été ajouté aux règles d'exclusion Git. Aucune valeur de clé n'a été affichée ou copiée dans ce rapport.

## Projet Supabase candidat

- Référence technique visible dans l'URL locale : `mrmmldgxneadgqnplyca`.
- Nom du projet : **non vérifié**.
- Statut « temporaire / développement distinct de la production » : **non vérifié**.
- Les credentials publics du fichier local ne prouvent pas l'environnement du projet. Aucune API de gestion de projet n'est configurée pour vérifier son nom ou son rattachement organisationnel.

Le statut du projet cible est donc **BLOCKED**. Par mesure de protection, aucune commande de liaison, migration, inspection SQL distante, ni opération de rollback n'a été exécutée.

## Contrôles

| Contrôle | Statut | Résultat |
| --- | --- | --- |
| Node/npm/npx disponibles | PASS | Versions indiquées ci-dessus. |
| Supabase CLI via npx | BLOCKED | Téléchargement non terminé; aucune installation globale. |
| Configuration Supabase locale | PASS | `supabase/config.toml` valide; migration et rollback attendus présents dans le dépôt. |
| Connectivité Auth avec le projet candidat | PASS | Endpoint santé Auth a répondu HTTP 200 lors d'un test antérieur, validation TLS activée. |
| Chemin client Supabase JS vers Data API | PASS avec accès refusé | Requête de lecture vers `roles` a atteint PostgreSQL et retourné SQLSTATE `42501` (permission refusée), cohérent avec les privilèges retirés aux rôles API. Aucun contenu de table n'a été lu. Cela ne vérifie pas l'identité environnementale du projet ni l'application de la migration présente dans le dépôt. |
| Cible prouvée non-production/temporaire | BLOCKED | Nom et environnement non vérifiables avec la configuration actuelle. |
| Application de la migration exacte | NOT TESTED | Aucune migration exécutée. |
| Vérification des 17 tables/FK/contraintes/index | NOT TESTED | Aucune introspection PostgreSQL effectuée. |
| Vérification RLS et privilèges effectifs | NOT TESTED | Les intentions déclarées par le fichier ne remplacent pas les catalogues et tests de rôles. |
| Test des huit triggers `updated_at` | NOT TESTED | Aucun insert/update de test effectué. |
| Rollback sur base temporaire | BLOCKED | Base temporaire non identifiée; aucune confirmation de rollback n'a été demandée ni reçue. Le script n'a pas été exécuté. |
| Vérification objets résiduels | NOT TESTED | Dépend du rollback isolé. |
| Réapplication et vérification finale | NOT TESTED | Dépend des contrôles précédents. |

## Commandes exécutées

- `node --version`
- `npm.cmd --version`
- `npx.cmd --version`
- `npx.cmd --yes supabase --version` — tentative interrompue après attente; aucune version CLI obtenue.
- Test HTTPS en lecture seule via le client Supabase JS et la clé publique locale; aucun secret affiché.
- Validation TOML locale de `supabase/config.toml`.

Ni `supabase db push`, ni SQL Editor, ni `psql`, ni rollback n'ont été invoqués. Aucune donnée ou migration n'a été écrite sur un projet distant.

## Corrections et risques

- `.env` a été ajouté à `.gitignore` avec exception conservée pour `.env.example`; le fichier `.env` local n'est pas suivi par Git.
- Risque principal restant : le projet Supabase candidat pourrait être la production. Son identifiant seul ne permet pas de l'exclure; il ne doit pas être ciblé avant confirmation de son nom et de son rôle temporaire.
- Le refus SQL `42501` confirme le passage jusqu'à PostgreSQL pour ce chemin et ce rôle, mais ne prouve pas que cette migration spécifique a été appliquée.
- Le rollback est destructif et n'a été ni exécuté ni validé. Une confirmation explicite sera nécessaire juste avant son exécution, après vérification de la cible temporaire.

## Pour débloquer la validation

1. Créer un nouveau projet Supabase temporaire, clairement nommé pour la validation FAFEDAA, dans l'organisation contrôlée par l'équipe. Ne pas réutiliser un projet dont l'environnement est ambigu.
2. Fournir uniquement le **nom du projet et sa référence non secrète** pour confirmer la cible. Ne pas envoyer de mot de passe, access token, clé secrète ou clé publishable dans la conversation.
3. Configurer l'URL et la clé publishable du projet temporaire dans le `.env` local ignoré par Git. Authentifier Supabase CLI localement via le flux interactif ou le gestionnaire de secrets du poste; ne pas écrire le token dans le dépôt.
4. Vérifier le nom et la référence avec `npx supabase projects list` ou le Dashboard, puis vérifier explicitement que le projet est temporaire avant de lier et pousser la migration.
5. Après inspection du rollback et confirmation de la base isolée, demander/obtenir la confirmation explicite requise avant de l'exécuter.
6. Interroger les catalogues PostgreSQL, tester les huit triggers avec des données fictives minimales, vérifier les objets supprimés puis réappliquer la migration et refaire les contrôles.

Le Lot 1 **ne peut pas être déclaré opérationnellement validé**. Le Lot 2 n'a pas commencé.
