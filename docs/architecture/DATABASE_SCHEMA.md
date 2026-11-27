# Schéma initial de données

La migration `supabase/migrations/20261127000100_initial_schema.sql` définit le schéma de départ FAFEDAA. Les identifiants sont UUID sauf pour le catalogue de rôles. Les suppressions de dossiers, dons et activités référencés sont bloquées (`RESTRICT`) ou préservent les références avec `SET NULL`; les données historiques ne sont donc pas effacées en cascade.

| Domaine | Tables | Règles principales |
| --- | --- | --- |
| Personnel et sécurité | `profiles`, `roles`, `profile_roles`, `audit_logs` | Profils liés à `auth.users`; rôles séparés des profils; audit horodaté. |
| Assistance | `beneficiaries`, `assistance_requests`, `case_assignments`, `case_notes` | Références de dossier générées avec des octets aléatoires; données de contact séparées des besoins; historique conservé. |
| Programmes | `programs`, `program_activities` | Slugs uniques, contenus traduits et statuts contrôlés. |
| Dons | `donors`, `donations`, `payment_transactions` | Dons financiers/en nature, transactions idempotentes; aucune donnée de carte. |
| Partenariats et contenu | `partners`, `partnership_requests`, `contact_messages`, `news` | Statuts contrôlés; contenus multilingues stockés séparément. |

RLS est activé sur chaque table dans cette fondation. Aucune politique n'est ajoutée avant le lot 2; l'accès via les rôles client est donc refusé par défaut. Ne pas insérer de données réelles tant que le lot 2 n'a pas défini et vérifié les politiques. Les champs JSON `sensitive_data`, `contact_data`, `consent_record` et `provider_payload` ont volontairement une forme souple pour le lot de fondation; leurs champs autorisés, validation et rétention doivent être cadrés avant la collecte en production.

La migration est additive et ne supprime pas de données existantes. Un retour arrière consiste à supprimer les tables dans l'ordre inverse des dépendances puis les types enum; effectuer cette opération uniquement sur un environnement jetable ou après une sauvegarde restaurable validée.
