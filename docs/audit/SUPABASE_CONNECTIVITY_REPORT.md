# Rapport de connectivité Supabase

Date : 27 novembre 2026  
Périmètre : tests réseau en lecture seule effectués avec les variables locales. Aucun identifiant, clé ou secret n'est consigné ici.

## Résultats

| Contrôle | Résultat |
| --- | --- |
| Endpoint Auth `/auth/v1/health` | **PASS — HTTP 200** avec validation TLS activée. |
| Client officiel Supabase JS vers la Data API | **PASS — requête atteinte jusqu'à PostgreSQL.** |
| Lecture de `roles` | **Refus attendue — SQLSTATE `42501`**, reçue par le SDK sous forme d'erreur structurée. Aucune ligne n'a été lue. |
| Requête initiale sur `/rest/v1/` | **HTTP 401 attendu** : la racine OpenAPI REST exige une clé secrète; une clé publishable n'est pas destinée à cette route. Ce résultat n'indique pas que le projet ou la clé publishable est hors ligne. |
| Écriture ou mutation | **Aucune écriture effectuée.** |
| Divulgation/enregistrement de secrets | **Aucune clé API, aucun token, mot de passe ou secret affiché ni enregistré dans ce rapport.** |

## Interprétation du refus `42501`

La migration révoque les privilèges directs de `PUBLIC`, `anon` et `authenticated` sur les tables et n'ajoute aucune politique RLS permissive. Le rôle utilisé pour la lecture anonyme n'a donc pas le privilège SQL `SELECT` sur `roles`. Le refus `42501` est une erreur de privilège SQL au niveau table; il ne faut pas la décrire comme une ligne filtrée par RLS. Si le privilège était accordé ultérieurement sans politique `SELECT`, RLS continuerait également à refuser la lecture. Ce comportement ne doit pas être contourné pour le seul besoin de faire disparaître l'erreur.

Le SDK Supabase renvoie l'échec sous forme d'objet `error` et de statut HTTP. Le test a reçu SQLSTATE `42501` avec HTTP 401. Le frontend n'exécute actuellement aucune requête de table dans son parcours utilisateur; il n'a donc pas encore d'affichage de cette erreur dans l'interface. `src/services/backend.ts` ne signale aujourd'hui que l'absence de configuration. La gestion UX des erreurs de requête reste à concevoir lors de l'intégration frontend; elle ne nécessite pas d'ouvrir les privilèges de la table.

## Configuration vérifiée

- `src/lib/supabase.ts` lit l'URL et la clé publique depuis `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`; aucune valeur n'y est codée en dur.
- `.env.example` ne contient que les emplacements vides pour l'URL et la clé publique, et avertit de ne pas exposer de clé serveur dans `VITE_*`.
- Aucun `service_role`, `sb_secret_*` ou nom de variable de secret serveur n'a été détecté dans le bundle client construit.
- La migration accorde des privilèges étendus à `service_role`, rôle réservé au serveur, et révoque les privilèges API directs décrits ci-dessus.
- Aucune instruction `CREATE POLICY` n'est présente dans la migration; aucune politique RLS permissive n'a été ajoutée.
- `supabase/config.toml` définit uniquement la configuration locale et désactive l'inscription ouverte; il ne contient aucune clé.

Vérification bundle exécutée : `npm.cmd run build`, puis recherche de marqueurs `service_role`, `SERVICE_ROLE`, `sb_secret_` et de noms de variables serveur dans `dist/assets` : aucun résultat.

## Limites

La connectivité prouve que les endpoints Auth et Data API sont joignables avec la configuration locale testée. Elle ne valide pas que le projet est temporaire, que la migration versionnée a été appliquée, ni que le Lot 1 est opérationnellement validé. Ces contrôles sont détaillés dans [le rapport de validation opérationnelle](LOT_1_OPERATIONAL_VALIDATION_REPORT.md).
