# Préparer Supabase en local et par environnement

## Prérequis

- Créer des projets Supabase distincts pour développement, staging et production depuis les comptes contrôlés par FAFEDAA.
- Installer Supabase CLI selon la documentation officielle de l'organisation et se connecter au projet de développement uniquement.
- Ne jamais utiliser un vrai dossier bénéficiaire ou un faux compte administratif réel comme donnée de test.

## Application locale

1. Copier `.env.example` en `.env.local`.
2. Renseigner `VITE_SUPABASE_URL` et la clé publique `anon`/publishable du projet de développement.
3. Vérifier que `.env.local` n'est pas ajouté à Git.
4. Depuis la racine, exécuter `supabase start` si la CLI locale est installée.
5. Examiner la migration puis exécuter `supabase db reset` uniquement sur la base locale jetable. Pour un projet distant non productif, lier explicitement son identifiant puis appliquer avec `supabase db push` après revue.
6. Configurer Vercel Preview et Production avec les variables publiques correspondant à leurs projets dédiés; ne jamais réutiliser les clés entre environnements.

## Secrets et sauvegardes

`SUPABASE_SERVICE_ROLE_KEY` n'est pas une variable Vite et ne doit jamais être exposée au navigateur. Les secrets serveur seront configurés séparément dans Supabase Edge Functions quand ces fonctions seront développées. Avant toute évolution de schéma non locale, exporter une sauvegarde cohérente, conserver les sauvegardes chiffrées avec accès restreint et répéter régulièrement une restauration sur un environnement isolé. Les procédures de sauvegarde/restauration opérées restent à valider avec l'administrateur Supabase FAFEDAA.

La migration initiale ne doit pas être poussée en production dans le cadre du lot 1.
