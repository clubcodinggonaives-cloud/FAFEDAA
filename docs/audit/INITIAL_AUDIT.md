# Audit initial — FAFEDAA

Date : 26 novembre 2026  
Périmètre : dépôt local fourni, inspection statique de l’application et vérification lint/build. Le site publié n’a pas pu être chargé dans l’outil de consultation web disponible ; son rendu réel et son état de déploiement restent à vérifier dans un navigateur.

## Résumé

Le dépôt contient une vitrine React 19 / Vite 8 avec quatre routes publiques reconnues (`/`, `/actions`, `/histoire`, `/contact`) et une page de soutien (`/soutenir`). Il ne contient ni backend, ni base de données, ni authentification, ni espace d’administration. Les pages de programmes, témoignages et représentants sont des contenus statiques. Le formulaire de contact prépare un message `mailto:` et ne transmet ni n’enregistre une demande sur le site.

Le lint Oxlint et le build de production réussissent. Aucun script ou répertoire de tests n’a été trouvé. La documentation du dépôt est encore celle du modèle React/Vite.

## Inventaire technique

- Frontend : React 19, React DOM, Vite 8, Tailwind CSS 4 (plugin configuré, CSS applicatif principalement écrit en CSS classique).
- Structure : une application dans `src/App.jsx` (environ 34 Ko) et `src/App.css` (environ 25 Ko), styles globaux minimes, point d’entrée `src/main.jsx`.
- Navigation : sélection des vues par `window.location.pathname`; liens HTML classiques. Pas de bibliothèque de routage ni de gestion de pages 404 explicite. Le comportement de repli Vercel pour les chemins directs n’est pas présent dans le dépôt.
- État : langue FR/HT/EN stockée dans `localStorage`; état du menu mobile local au composant.
- API/données/authentification : aucune intégration trouvée. Aucune dépendance backend ou de validation de formulaire.
- Configuration : `vite.config.js`, `.gitignore`, `index.html`; aucune configuration Vercel ou fichier d’environnement détecté. Aucun secret n’a été inspecté hors des fichiers présents.
- Tests : aucun script de test dans `package.json`, aucun fichier de test détecté.
- Ressources : logo local, photos distantes Unsplash et Google Fonts chargé par CSS. Les photos sont illustratives, pas des preuves d’activités FAFEDAA.

## Constatations classées par gravité

| Gravité | Constat et preuve locale | Conséquence | Recommandation |
|---|---|---|---|
| Critique avant toute collecte sensible | Aucun serveur, stockage, authentification ou contrôle d’accès ; les demandes d’aide ne sont pas enregistrées. | Impossible de traiter des dossiers et dangereux de présenter le formulaire comme un canal de prise en charge. | Ne pas collecter de données bénéficiaires avant conception et mise en œuvre d’un backend avec contrôle d’accès, journalisation, conservation et procédures de protection de l’enfance. |
| Élevée | Encodage incorrect visible dans `src/App.jsx` et `index.html` (ex. « FranÃ§ais », « assurÃ© »). | Texte dégradé dans l’interface, métadonnées et expérience des personnes francophones/créolophones. | Corriger l’encodage à la source et ajouter une vérification de non-régression. |
| Élevée | Le formulaire de contact déclenche `mailto:` sans envoi ni accusé de réception applicatif. Champs nom, courriel et message sont remis au client de messagerie. | Beaucoup de téléphones n’ont pas de client configuré ; aucune demande n’est confirmée ou suivie. | Présenter clairement ce comportement temporaire ou intégrer un service serveur sécurisé avant d’annoncer une réception effective. |
| Élevée | Liens de soutien et textes mentionnent des méthodes de paiement (MonCash, Natcash, espèces, banque) mais aucun paiement ni registre n’existe. | Risque de confusion sur les coordonnées ou sur l’enregistrement des dons. | Ne pas afficher d’instructions de paiement non vérifiées ; ajouter un flux traçable uniquement après validation organisationnelle et backend. |
| Élevée | Des affirmations institutionnelles (fondation en 2008, nom d’un responsable, actions/programmes) sont codées en dur et ne sont pas corroborées par des pièces dans le dépôt. | Risque de publier des informations inexactes ou des activités non confirmées. | Faire valider chaque fait et distinguer les intentions des activités réalisées avant publication. |
| Moyenne | Les itinéraires et contenus sont condensés dans un seul composant ; aucune page d’actualités ni détail indépendant par programme. | Évolutivité, maintenance, testabilité et référencement limités. | Extraire progressivement les pages et composants sans migration structurelle inutile. |
| Moyenne | Les images distantes Unsplash et polices Google créent des dépendances réseau tierces. Une image de héros est chargée sans `loading`/dimensions explicites dans le JSX. | Temps de chargement et stabilité variables sur connexions lentes ; transfert de requêtes vers des tiers. | Mesurer, optimiser les images, déclarer les dimensions et réduire les dépendances réseau selon les choix de confidentialité. |
| Moyenne | Pas de tests automatisés, de route 404, de sitemap/robots, de données structurées ni de métadonnées OG visibles. | Régressions et indexation incomplète possibles. | Ajouter ces éléments après stabilisation des contenus et des routes. |
| À vérifier | Aucun parcours clavier complet, audit de contraste ou rendu mobile exécuté dans un navigateur. | L’accessibilité et le responsive ne peuvent pas être déclarés conformes sur inspection statique seule. | Faire un contrôle navigateur clavier/mobile et mesurer Lighthouse après correction des contenus. |
| À vérifier | Le site publié n’a pas été consultable avec l’outil web ; les réponses HTTP, domaines, en-têtes, déploiement et rendu ne sont pas vérifiés. | Aucun constat fiable sur l’environnement de production. | Vérifier depuis un navigateur et le tableau de bord Vercel autorisé par l’organisation. |

## Fonctionnalités observées

- Vues statiques : accueil, actions, histoire, contact, soutien.
- Commutateur FR/HT/EN et mémorisation locale de la langue.
- Menu mobile avec état ouvert/fermé.
- Formulaire de contact avec validation native HTML, puis ouverture d’un courriel prérempli.
- Liens vers ressources externes et éléments de présentation statiques.

Ces éléments ne prouvent pas l’existence d’un système de gestion, d’un programme opérationnel, d’un paiement ou d’une prise en charge.

## Vérifications exécutées

- `npm.cmd run lint` : réussi, aucune erreur signalée.
- `npm.cmd run build` : réussi avec Vite 8.3.8. Bundle client généré : JS 255,51 Ko (79,78 Ko gzip), CSS 24,08 Ko (6,28 Ko gzip).
- Tests applicatifs : non disponibles (aucun script ni suite détectés).
- Contrôle visuel du site publié : non effectué, l’outil web ne peut pas ouvrir l’URL fournie.

## Priorités recommandées

1. Corriger et vérifier l’encodage des contenus.
2. Valider avec FAFEDAA les informations institutionnelles et les activités réelles avant de les présenter comme établies.
3. Clarifier le formulaire temporaire et ne pas recueillir de renseignements sensibles tant qu’un traitement sécurisé côté serveur n’existe pas.
4. Définir les exigences de confidentialité, rôles et flux opérationnels avant de choisir/construire backend et schéma de données.
5. Développer ensuite les parcours d’assistance et l’administration par tranches, avec permissions serveur et tests avant mise en production.
6. Compléter accessibilité, performance, SEO et déploiement après vérification navigateur et mesure.
