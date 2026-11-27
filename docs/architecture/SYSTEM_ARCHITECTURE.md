# Architecture système — fondations

Le site public reste une application React 19 / Vite hébergée sur Vercel. Le navigateur utilisera uniquement l'URL du projet Supabase et sa clé publique (`anon`/publishable), via `src/lib/supabase.ts`. Les contrôles d'accès doivent être appliqués par RLS et les fonctions serveur; le code de route React ne constitue pas une frontière de sécurité.

Le schéma initial PostgreSQL est versionné dans `supabase/migrations/`. Les Edge Functions, Storage privé et intégrations de paiement restent à créer dans les lots suivants. Aucune connexion distante ni migration de production n'a été effectuée dans le lot 1.

Configuration par environnement : conserver les valeurs propres au projet dans les paramètres de l'environnement (local, preview/staging, production). Ne jamais préfixer un secret serveur par `VITE_`, car Vite l'intègre au bundle public. Le service role reste uniquement dans l'environnement serveur Supabase.
