# Conception — Lot 2 : authentification et autorisations

**État : conception préparatoire seulement.** Aucun code, table, migration, fonction, composant ou politique RLS du Lot 2 n'est créé par ce document. Les règles ci-dessous doivent être validées par FAFEDAA avant implémentation.

## Principes

- Le dashboard est strictement réservé au personnel interne invité et actif.
- La sécurité est imposée par PostgreSQL/RLS et les fonctions serveur; les routes React ne sont qu'une aide UX.
- Les rôles viennent des tables contrôlées côté serveur, jamais de `user_metadata`, du navigateur ou d'une valeur modifiable par le membre.
- Refus par défaut : aucun accès aux données sans identité, profil actif, privilège SQL explicite et politique RLS concordante.
- La clé `service_role`/secret ne quitte jamais les fonctions serveur. Le navigateur utilise exclusivement une clé publishable/anon.
- Les données de bénéficiaires ne sont visibles qu'au personnel ayant une attribution ou une autorisation administrative justifiée.

## Authentification et profils du personnel

Supabase Auth assure connexion, déconnexion, récupération et changement de mot de passe, renouvellement et révocation de session. L'inscription publique demeure désactivée. Les pages du dashboard vérifient une session valide puis l'existence d'un profil interne actif; ce contrôle de route n'accorde aucun privilège de base de données.

Chaque `auth.users.id` correspond à un `profiles.id`. Un compte sans profil actif est refusé. La préférence linguistique et le nom d'affichage sont des attributs de profil, pas des attributs d'autorisation. Les changements de rôle, activation et désactivation sont des opérations serveur auditées.

## Rôles et périmètre envisagé

Une personne peut recevoir plusieurs rôles, mais les permissions effectives sont l'union explicite des capacités accordées, avec refus en cas d'ambiguïté. Le modèle exact doit être approuvé avant les politiques.

| Rôle | Accès proposé |
| --- | --- |
| `super_admin` | Gestion du personnel et des rôles, configuration et consultation administrative globale; accès d'urgence audité. |
| `admin` | Opérations administratives, dossiers nécessaires, dons et rapports; gestion des contenus. La gestion des autres super administrateurs est exclue. |
| `program_manager` | Programmes et activités; données de suivi agrégées ou dossiers explicitement affectés au programme, sans gestion des rôles ni opérations financières. |
| `social_worker` | Demandes et bénéficiaires associés à ses affectations actives; notes et mises à jour opérationnelles permises. Aucun accès transversal implicite. |
| `content_editor` | Brouillons et publications d'actualités/contenus publics. Aucun accès aux bénéficiaires, demandes, coordonnées privées, dons ou transactions. |

Cette matrice est une proposition à faire valider; elle ne reflète pas encore des politiques exécutables.

## Bootstrap sécurisé du premier `super_admin`

1. Créer le projet et désactiver l'inscription publique; limiter l'accès au tableau de bord Supabase aux administrateurs de l'organisation.
2. Créer le premier utilisateur Auth par invitation administrative vérifiée, sur une adresse professionnelle contrôlée.
3. Vérifier indépendamment l'identité, l'ID `auth.users` et le contexte projet de développement/production.
4. Attribuer le profil actif et le rôle par une opération administrative serveur/DB unique et authentifiée, sans endpoint public de promotion. Aucun rôle n'est lu depuis les métadonnées utilisateur.
5. Écrire un événement d'audit minimal, tester les permissions positives et négatives, puis supprimer/verrouiller l'accès d'amorçage temporaire.
6. Conserver une procédure d'urgence à deux personnes, avec approbation et audit, pour la récupération d'un accès super administrateur.

Pas de mot de passe, secret partagé, token de bootstrap ou clé serveur dans le code, la migration versionnée, les logs ou le dépôt. L'affectation initiale est manuelle et contrôlée hors de tout flux public.

## Invitations contrôlées et séparation des responsabilités

Une fonction serveur d'invitation vérifie l'acteur actif et son droit à inviter, valide le rôle demandé, restreint les domaines/adresses selon une liste approuvée et écrit un audit sans donnée inutile. Le navigateur ne peut ni créer un utilisateur administratif librement ni changer un rôle. Les utilisateurs Auth sans invitation/profil actif restent refusés.

La personne qui demande une promotion ne peut pas s'auto-promouvoir. Les changements de super administrateur exigent un approbateur distinct. Les rôles financiers, éditoriaux et sociaux restent séparés selon la matrice approuvée. Les désactivations invalident l'accès et les sessions selon la procédure retenue.

## Conception des politiques RLS

- Activer RLS sur chaque table applicative et garder un refus par défaut.
- Accorder uniquement les privilèges SQL nécessaires, puis définir des politiques distinctes pour `SELECT`, `INSERT`, `UPDATE`, `DELETE`; `WITH CHECK` contrôle aussi les nouvelles valeurs et relations.
- Anonyme : aucun accès direct aux dossiers, bénéficiaires, messages privés ou finances. Les soumissions publiques passent par des fonctions serveur dédiées (hors périmètre du Lot 2).
- `authenticated` : aucun accès automatique du seul fait d'une session Auth; profil actif et capacité métier sont requis.
- `content_editor` : politiques limitées aux contenus; aucune lecture des tables financières ou sociales.
- `program_manager` : accès limité au périmètre des programmes autorisés.
- `social_worker` : une demande n'est visible que si une affectation active la lie au `auth.uid()` et si le profil est actif. Les bénéficiaires liés sont accessibles uniquement via les demandes autorisées, sans accès global.
- `admin` et `super_admin` : politiques explicites selon la matrice approuvée; opérations privilégiées journalisées.
- `audit_logs` : insertion par chemin de confiance seulement; aucune modification ou suppression par les utilisateurs ordinaires. Lecture très limitée.
- Les fonctions d'aide aux politiques, si nécessaires pour éviter la récursion, utilisent un `search_path` fixé, retournent le minimum, ont des privilèges explicitement révoqués/accordés et ne permettent pas d'appel privilégié générique.
- `service_role` reste réservé aux fonctions backend contrôlées; il contourne RLS et n'est jamais utilisé dans le navigateur.

## Audit des actions sensibles

Journaliser l'acteur, l'action, le type/ID de cible, l'horodatage, le résultat et un identifiant de corrélation pour les invitations, changements de rôle, accès sensible si requis, affectations, transitions d'état, décisions administratives, exports et opérations financières. Éviter le corps des dossiers, coordonnées, secrets et données d'enfants dans `metadata`. Les journaux sont append-only pour les utilisateurs usuels; rétention, lecture, export et accès d'urgence sont définis avec FAFEDAA.

## Plan de tests d'autorisation

**Tests positifs** : personnel actif reçoit uniquement ses capacités approuvées; agent social lit et met à jour un dossier qui lui est attribué; responsable voit le programme accordé; éditeur publie un contenu autorisé; administrateur invité effectue l'opération prévue; profil utilisateur peut lire ses seules informations de profil.

**Tests négatifs** : anonyme ne lit ni n'insère directement dans les tables privées; utilisateur sans profil/inactif est refusé; agent ne lit pas un dossier non affecté et ne peut pas modifier son affectation; éditeur ne lit pas les dons/transactions; responsable de programme ne modifie pas les rôles; utilisateur ne s'accorde pas un rôle; rôle d'admin ne s'élève pas en super admin; affectation à un profil inactif échoue; journal d'audit ne peut pas être altéré; client ne peut pas appeler une fonction privilégiée avec des paramètres arbitraires.

Tester avec `anon`, utilisateur authentifié de chaque rôle, profil inactif, rôle multiple et `service_role` uniquement dans un projet isolé. Vérifier à la fois les privilèges SQL (`GRANT`) et l'effet RLS; un refus SQL seul ne prouve pas la qualité d'une politique. Ne commencer ces tests qu'une fois le Lot 1 appliqué et validé sur la base de test.
