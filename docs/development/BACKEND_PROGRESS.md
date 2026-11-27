# Avancement backend

## Lot 1 — Fondations

- [x] Client navigateur Supabase avec variables Vite publiques et persistance de session.
- [x] Fichier `.env.example` sans valeurs secrètes.
- [x] Types de base et helper d'erreur de configuration pour le futur service.
- [x] Migration initiale couvrant identité, assistance, programmes, dons, partenariats, communication et audit.
- [x] RLS activé sur toutes les tables; aucune politique permissive n'est encore publiée.
- [x] Audit statique indépendant; droits directs `anon`/`authenticated` explicitement révoqués et triggers `updated_at` ajoutés.
- [ ] Validation opérationnelle sur projet Supabase temporaire (**bloquée** : projet configuré non vérifié comme distinct de la production; Supabase CLI via npx indisponible dans l'environnement).
- [x] Documentation de l'architecture, du schéma et de la procédure locale.
- [ ] Appliquer la migration, tester RLS/privilèges, exécuter le rollback puis réappliquer sur un projet de développement isolé.
- [ ] Revue/validation de ce lot avant de commencer le lot 2.

Aucune migration SQL distante n'a été appliquée et aucun rollback n'a été exécuté. Une requête de lecture antérieure a atteint le projet actuellement configuré, mais son environnement n'est pas vérifié comme temporaire; il n'a pas été utilisé pour des modifications. Voir [le rapport d'audit du Lot 1](../audit/LOT_1_VALIDATION_REPORT.md) et [le rapport de validation opérationnelle](../audit/LOT_1_OPERATIONAL_VALIDATION_REPORT.md). La collecte frontend et les opérations backend ne sont pas encore opérationnelles.

## État connectivité et Lot 2

- Connectivité Supabase (Auth HTTP 200, client JS atteint la Data API avec TLS vérifié) : **validée**.
- Accès direct aux tables via le rôle public : **volontairement restreint**; `roles` retourne SQLSTATE `42501` au niveau privilèges SQL. RLS est également activé sans politique `SELECT`, donc ne permettrait pas la lecture si le privilège SQL était accordé.
- Migration opérationnelle : **à valider** sur un projet temporaire isolé; application, rollback et réapplication ne sont pas exécutés.
- Lot 2 : **non commencé**. La conception préparatoire est documentée dans [LOT_2_AUTHORIZATION_DESIGN.md](LOT_2_AUTHORIZATION_DESIGN.md); aucune politique permissive n'a été ajoutée pour éliminer `42501`.
- Bundle frontend : build vérifié; aucune chaîne `service_role`, `sb_secret_` ni nom de variable serveur détectée. Les erreurs de requête sont retournées par le SDK, mais aucun parcours frontend de lecture n'est encore câblé pour les présenter dans l'interface.
- Rapport de connectivité : [SUPABASE_CONNECTIVITY_REPORT.md](../audit/SUPABASE_CONNECTIVITY_REPORT.md).
