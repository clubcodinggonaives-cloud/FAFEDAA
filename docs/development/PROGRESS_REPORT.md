# Rapport d’avancement

Date : 26 novembre 2026

## Réalisé

- Audit initial et plan de modernisation documentés.
- Refonte visuelle de la vitrine : navigation persistante, échelle typographique plus lisible, grilles et cartes harmonisées, pages publiques plus cohérentes et styles adaptés aux petits écrans.
- Suppression du chargement externe de Google Fonts afin de limiter les dépendances réseau et de s’appuyer sur une pile système.
- Simplification de la page Soutien : les cartes de paiement, fiches représentants et espaces de témoignages sans données confirmées ne sont plus présentés.
- Vérification : Oxlint et build Vite réussis après la refonte.

## Limites et suite

- Le rendu n’a pas été inspecté dans un navigateur réel pendant cette livraison ; prévoir une revue visuelle mobile et bureau.
- Les contenus institutionnels, coordonnées et actions doivent être confirmés par FAFEDAA.
- Le formulaire de contact reste un `mailto:` et ne stocke rien. La refonte ne crée aucun traitement de demandes ou de dons.
- Étape suivante : revue avec l’organisation des textes et images, puis cadrage des rôles, données et règles de confidentialité avant l’architecture backend.

## Mise à jour du 26 novembre 2026

- Page « Nous soutenir » : présentation des quatre moyens demandés (MonCash, Natcash, espèces et compte bancaire) avec les icônes des applications MonCash/Natcash et des pictogrammes dédiés aux espèces et à la banque.
- Aucun numéro de portefeuille ni compte bancaire n’ayant été fourni, la page demande de confirmer les coordonnées officielles auprès de FAFEDAA avant un transfert.
- Les textes de mission, actions et contact sont formulés à l’échelle d’Haïti dans les trois langues. L’adresse réelle de FAFEDAA reste indiquée à Delmas 75 sur la page Contact.
- Les photos externes ont été remplacées par deux ressources locales issues d’une scène d’école haïtienne, dont un recadrage. Les crédits sont consignés dans `docs/ASSET_CREDITS.md`.
- Vérification : Oxlint et build Vite réussis.
