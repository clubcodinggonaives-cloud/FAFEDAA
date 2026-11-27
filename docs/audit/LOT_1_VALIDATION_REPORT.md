# Rapport d'audit technique — Lot 1 Supabase

Date : 27 novembre 2026  
Périmètre : audit statique des migrations, permissions, modèle de données, configuration Supabase et client frontend. Aucune base distante ou réelle n'a été contactée.

## Conclusion

**Lot 1 non validé pour exécution.** L'audit statique a conduit à des corrections de la migration : mise à jour effective des colonnes `updated_at`, révocation explicite des droits directs des rôles `anon` et `authenticated`, retrait de l'extension `pgcrypto` qui n'était pas nécessaire, et script rollback aligné sur les objets ajoutés. Les contrôles lint, build et TypeScript ciblé réussissent.

La migration et le rollback n'ont pas été exécutés sur PostgreSQL. La CLI Supabase n'est pas installée, `psql`/serveur PostgreSQL sont absents, et Docker ne peut pas joindre un daemon. La syntaxe PostgreSQL, les droits effectifs, les contraintes et la répétabilité ne peuvent donc pas être déclarés validés sur la seule base de l'inspection.

## Travaux effectués et résultats

| Contrôle | Résultat | Détail |
| --- | --- | --- |
| Lecture complète migration et rollback | Réussi, statique | 17 tables, quatre types enum, 16 index secondaires, huit triggers `updated_at`; aucune vue, fonction `SECURITY DEFINER` ou fonction d'application autre que le trigger. |
| Relations et ordre de suppression | Cohérent, statique | FK vers `auth.users`, profils, rôles, dossiers, programmes, donateurs et dons. Les références métier utilisent `RESTRICT` ou `SET NULL`; aucune suppression en cascade. Le rollback supprime les tables dépendantes avant leurs parents, puis fonction et types. |
| RLS | 17/17 activé, statique | `profiles`, `roles`, `profile_roles`, `audit_logs`, `beneficiaries`, `assistance_requests`, `case_assignments`, `case_notes`, `programs`, `program_activities`, `donors`, `donations`, `payment_transactions`, `partners`, `partnership_requests`, `contact_messages`, `news`. La migration ne crée aucune politique. |
| Privilèges | Mesure défensive ajoutée, statique | La migration révoque les droits hérités de `PUBLIC` et les droits explicites de `anon`/`authenticated` sur les 17 tables; elle accorde `ALL` à `service_role` et limite sa séquence à `USAGE, SELECT`. L'exécution publique du trigger et l'accès public à la séquence sont révoqués. Les privilèges effectifs ne sont pas interrogés faute de base. |
| Fonctions, vues et accès indirect | Réussi, statique | Aucune vue ni fonction `SECURITY DEFINER`; `set_updated_at()` est une fonction trigger `SECURITY INVOKER`, `search_path` fixé à `pg_catalog`, exécution révoquée aux rôles API. Aucun chemin de lecture indirect n'est défini par cette migration. |
| Client TypeScript Supabase | Réussi, ciblé | `tsc --noEmit --target ES2022 --module ESNext --moduleResolution Bundler --strict --skipLibCheck src/lib/supabase.ts src/vite-env.d.ts` passe avec TypeScript 5.9.3 temporaire; aucune dépendance projet ajoutée pour ce contrôle. |
| Lint | Réussi | `npm.cmd run lint`. |
| Build frontend | Réussi | `npm.cmd run build`. |
| Outils de base locale | Non disponible | CLI `supabase`, `psql`, `postgres`, `pg_ctl`, `initdb` absents. Docker est installé, mais le daemon ne répond pas. |
| Application migration, tests RLS/grants, rollback et réapplication | Non exécutés | Nécessitent un serveur PostgreSQL/Supabase isolé. Aucun succès SQL n'est simulé dans ce rapport. |

## Matrice RLS et opérations

Pour **chacune des 17 tables listées ci-dessus**, la migration active RLS et ne crée aucune politique. Elle révoque `PUBLIC` ainsi que les droits explicites de `anon` et `authenticated` pour `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES` et `TRIGGER`. L'accès direct par ces deux rôles est donc fermé à la fois par privilèges et par RLS, même en présence de privilèges par défaut. `service_role` reçoit explicitement `ALL` et contourne habituellement RLS dans Supabase : sa clé doit rester exclusivement côté serveur. Le propriétaire de table peut aussi contourner RLS; ce comportement est administratif et n'est pas une frontière destinée au client.

Il n'existe pas de politiques à évaluer par opération `USING`/`WITH CHECK`; elles relèvent du lot 2. L'accès par le propriétaire de migration et les droits par défaut du projet ne peuvent pas être confirmés sans exécution.

## Corrections apportées pendant l'audit

- Ajout de `set_updated_at()` et de triggers `BEFORE UPDATE` sur les huit tables possédant `updated_at` (`profiles`, `beneficiaries`, `assistance_requests`, `programs`, `donations`, `payment_transactions`, `partners`, `news`).
- Révocation explicite des privilèges `PUBLIC`, `anon` et `authenticated` sur les 17 tables; droits explicites serveur pour `service_role` et révocation de l'accès public à la séquence identity `roles_id_seq` et à la fonction trigger.
- Suppression de `pgcrypto` et remplacement de `gen_random_bytes()` par des UUID v4 générés nativement par PostgreSQL 17 pour les références non prédictibles. Cela évite de dépendre du schéma où une extension préinstallée serait située.
- Le rollback supprime les tables dans l'ordre inverse des dépendances, puis la fonction trigger et les types enum. Il ne supprime pas d'extension partagée.

## Points de modèle et risques résiduels

- Les données personnelles sont placées dans des colonnes JSON (`beneficiaries.sensitive_data`, `assistance_requests.contact_data`/`consent_record`, `donors.contact_data`, `partners.contact_data`, etc.). Cette souplesse ne valide pas les clés, ne minimise pas le contenu et ne définit ni rétention ni anonymisation. Le schéma n'est pas prêt à recevoir des données sensibles réelles avant un modèle et des procédures approuvés.
- `contact_messages` stocke nom, courriel et message dans une seule table; la politique de rétention et l'accès opérationnel restent à définir.
- `donations.transaction_reference` peut recouper `payment_transactions.provider_reference`; aucune contrainte ne synchronise les montants/devises du don et des transactions. Les invariants financiers devront être contrôlés par le flux serveur du lot 4.
- Les champs `translations` et `provider_payload` sont du JSON libre. `provider_payload` doit être filtré pour éviter de conserver secrets ou données de paiement non nécessaires.
- `case_assignments` conserve un historique, mais le schéma n'impose pas d'unicité d'affectation active par dossier. La règle métier (un responsable ou une équipe) doit être décidée avant les fonctions d'affectation.
- La migration suppose un projet Supabase fournissant les rôles `anon`, `authenticated`, `service_role` et le schéma `auth.users`. Elle n'est pas une migration PostgreSQL autonome hors Supabase.
- Le rollback est destructif par nature. Son ordre est cohérent, mais les conséquences n'ont pas été vérifiées sur une base de test et le script ne doit jamais être lancé sur une base réelle.
- Le type `Database` frontend est un contrat générique temporaire, pas un type généré colonne par colonne; il doit être généré depuis le schéma après validation.

## Conditions avant validation du Lot 1

1. Installer/configurer Supabase CLI et un moteur Docker fonctionnel, ou fournir une instance PostgreSQL de test isolée avec le schéma `auth` et les rôles Supabase requis.
2. Appliquer la migration à une base vierge et vérifier catalogues, 17 tables, contraintes/FK, 16 index secondaires, huit triggers, RLS et privilèges effectifs.
3. Confirmer les refus `SELECT`/`INSERT`/`UPDATE`/`DELETE` pour `anon` et `authenticated`, ainsi que l'isolation du rôle `service_role` hors navigateur.
4. Exécuter le rollback uniquement sur cette base jetable, confirmer l'absence des objets créés, puis réappliquer la migration et répéter les contrôles.
5. Faire approuver le modèle de données sensibles, la rétention et les invariants des dons avant toute collecte réelle.

Le lot 2 n'est pas commencé dans cette livraison.
