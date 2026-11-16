# Formulaire de soumission — Bobcrapette 1.0

Une seule feuille, à ouvrir à côté d'App Store Connect. Les champs sont dans
l'ordre des écrans ; chaque valeur est prête à être recopiée telle quelle.

- Ce qui est **noté `⬜`** attend une information que vous seul détenez.
- Les limites de caractères d'Apple sont rappelées entre parenthèses ; les
  textes ci-dessous les respectent, compteur à l'appui.
- Le détail et les justifications restent dans `fiche-app-store.md`,
  `confidentialite-app-store.md` et `notes-pour-la-revue.md`.

---

## ⬜ Les six choses qui manquent

Renseignez-les ici une fois pour toutes, elles sont reprises plus bas.

| # | Information | Votre réponse |
| --- | --- | --- |
| 1 | Prénom et nom du contact de revue | `Robert Oulhen` (à confirmer) |
| 2 | Numéro de téléphone avec indicatif | ⬜ `+33 6 ……` |
| 3 | Adresse postale publiée sur la fiche (voir « Statut de professionnel ») | ⬜ |
| 4 | Prix : gratuit, ou montant | ⬜ |
| 5 | Territoires : monde entier, ou liste | ⬜ |
| 6 | Publication sur le Mac App Store, ou simple compatibilité Apple silicon | ⬜ |

---

## 1. Nouvelle app — écran de création

| Champ | Valeur |
| --- | --- |
| Plateformes | iOS *(cocher macOS si vous publiez aussi sur le Mac App Store)* |
| Nom | `Bobcrapette` |
| Langue principale | `Français (France)` |
| Identifiant de lot | `com.oulhen.bobcrapette` |
| SKU | `BOBCRAPETTE-1` |
| Accès utilisateur | `Accès complet` |

Le SKU est une référence interne, invisible du public et définitive : n'importe
quelle chaîne fait l'affaire, mais elle ne se modifie plus ensuite.

---

## 2. Informations générales sur l'app

| Champ | Valeur |
| --- | --- |
| Sous-titre (30) | `La crapette au jeu de tarot` — 27 caractères |
| Catégorie principale | `Jeux` → sous-catégorie `Cartes` |
| Catégorie secondaire | `Jeux` → sous-catégorie `Famille` |
| Droits d'auteur | `2026 Robert Oulhen` |
| Contrat de licence | Contrat type d'Apple (ne rien téléverser) |
| Contenu de tiers | `Non` — cartes, icône et code écrits pour l'app |
| Fichier de routage (Routing App Coverage) | Aucun |
| Game Center | Désactivé |
| Achats intégrés | Aucun |

### Classification par âge → **4+**

Au questionnaire, tout est à **Aucun** : violence, contenu sexuel, langage
grossier, thèmes d'horreur, consommation de substances, contenu médical.

> ⚠️ **La question à ne pas manquer** : *jeux d'argent simulés* → **Non**.
> La crapette est un jeu de patience : ni mise, ni monnaie virtuelle, ni
> coffre à butin. Un « oui » distrait ferait basculer la fiche en 17+.

Les trois questions suivantes sont également à **Non** : contenu web illimité,
échanges entre utilisateurs, partage de position.

---

## 3. Version 1.0 pour iOS

### Texte promotionnel (170) — 151 caractères

Modifiable à tout moment sans repasser par la revue.

```
Un adversaire qui vous surveille, des atouts qui font une cinquième famille, et le plaisir de crier « Crapette ! » quand il oublie un coup obligatoire.
```

### Description (4000)

À recopier depuis `fiche-app-store.md`, section « Description ». Le texte y est
mis en forme avec les intertitres en capitales, qui passent tels quels : l'App
Store n'accepte ni gras, ni italique, ni Markdown.

### Mots-clés (100, séparés par des virgules, **sans espace après la virgule**)

```
cartes,réussite,solitaire,patience,atout,deux,joueurs,societe,famille,solo,duel,hors,ligne
```

90 caractères. Deux principes ont guidé la liste :

- **ne jamais répéter** un mot déjà présent dans le nom ou le sous-titre —
  « crapette », « tarot » et « jeu » sont déjà indexés par le sous-titre, les
  remettre ici gaspillerait 14 caractères pour rien ;
- **des mots isolés plutôt que des expressions** : Apple recompose lui-même les
  combinaisons entre le nom, le sous-titre et les mots-clés. `societe` suffit à
  faire ressortir « jeu de société », `deux` et `joueurs` à faire « deux
  joueurs ». Les accents sont indifférents à la recherche.

### Liens

| Champ | Valeur |
| --- | --- |
| URL d'assistance *(obligatoire)* | `https://boboul-cloud.github.io/Bobcrapette/assistance.html` |
| URL marketing *(facultative)* | `https://boboul-cloud.github.io/Bobcrapette/` |

### Captures d'écran

| Emplacement | Appareil | Dimensions | Nombre |
| --- | --- | --- | --- |
| `store/captures/iphone-6.9/` | iPhone 6,9 pouces | 1320 × 2868 | 3 |
| `store/captures/ipad-13/` | iPad Pro 13 pouces | 2064 × 2752 | 3 |

Dimensions vérifiées. Ces deux tailles suffisent : App Store Connect décline la
capture 6,9 pouces vers les iPhone plus petits, et la 13 pouces vers les iPad
plus petits. Ordre à respecter : accueil, donne, partie en cours.

### Version et build

| Champ | Valeur |
| --- | --- |
| Numéro de version | `1.0` |
| Build | `1` — envoyé depuis Xcode, il apparaît ici après traitement |
| Droits d'auteur | `2026 Robert Oulhen` |
| Publication | `Manuelle` — recommandé : la fiche ne sort que quand vous le décidez |
| Mise à jour progressive | Sans objet pour une première version |

---

## 4. Confidentialité de l'app

| Champ | Réponse |
| --- | --- |
| URL de la politique de confidentialité | `https://boboul-cloud.github.io/Bobcrapette/confidentialite.html` |
| Recueillez-vous des données ? | **Non, aucune donnée n'est recueillie** |
| Suivi publicitaire (ATT) | Sans objet |

Le questionnaire s'arrête à la première question et l'étiquette affichée sera
« Aucune donnée collectée ». Le raisonnement est détaillé dans
`confidentialite-app-store.md`.

---

## 5. Informations pour la revue

| Champ | Valeur |
| --- | --- |
| Connexion requise | **Non** (décocher la case) |
| Prénom | `Robert` |
| Nom | `Oulhen` |
| Téléphone | ⬜ `+33 6 …` — Apple n'appelle qu'en cas de blocage |
| Adresse électronique | `bob.oulhen@gmail.com` |
| Notes | Recopier le bloc **anglais** de `notes-pour-la-revue.md` |
| Pièce jointe | Aucune |

---

## 6. Statut de professionnel et adresse publique

> C'est le point le plus délicat du dossier, et le seul qui touche à votre vie
> privée. **À vérifier écran en main**, la règle ayant changé plusieurs fois.

Depuis l'entrée en vigueur du règlement européen sur les services numériques,
App Store Connect demande à chaque développeur de déclarer s'il agit en tant
que **professionnel** (*trader*). Ce que cela implique :

- une app dont le statut n'est pas déclaré **n'est pas distribuée dans l'Union
  européenne** — donc ni en France, ni en Belgique, ni au Luxembourg. Pour un
  jeu en français, c'est rédhibitoire ;
- si vous vous déclarez professionnel, Apple vérifie puis **publie sur la fiche
  App Store** votre nom, votre adresse postale, votre téléphone et votre adresse
  électronique, visibles de tous dans l'UE.

| Champ | Votre réponse |
| --- | --- |
| Statut | ⬜ Professionnel / Non-professionnel |
| Nom ou raison sociale | ⬜ |
| Adresse | ⬜ |
| Code postal et ville | ⬜ |
| Pays | `France` |
| Téléphone public | ⬜ |
| Adresse électronique publique | ⬜ |

**Deux conseils.** Ne donnez pas votre domicile si vous pouvez l'éviter : une
boîte postale ou une adresse de domiciliation convient, dès lors que le courrier
vous parvient. Et prévoyez une adresse électronique dédiée, par exemple
`bobcrapette@…`, plutôt que votre boîte personnelle : celle qui figure sur la
fiche reçoit toutes les sollicitations.

Par ailleurs, sur un compte individuel, le **nom du vendeur** affiché est votre
nom légal. Faire apparaître un autre nom suppose une demande séparée auprès
d'Apple, pièces à l'appui.

---

## 7. Tarifs et disponibilité

| Champ | Votre réponse |
| --- | --- |
| Prix | ⬜ Gratuit, ou palier (2,99 € = palier 3) |
| Territoires | ⬜ Monde entier *(par défaut)*, ou France, Belgique, Suisse, Canada, Luxembourg |
| Précommande | Non |
| Disponibilité sur Mac | ⬜ Voir ci-dessous |
| Distribution personnalisée / éducation | Non |

**Sur le Mac, deux chemins.** Soit vous publiez une vraie app Mac depuis cette
même fiche — il faut alors cocher macOS à la création, archiver une seconde fois
et fournir une capture de 1280 × 800 au minimum. Soit vous cochez simplement
« Rendre cette app disponible » dans la section Mac, et les Mac Apple silicon
exécuteront la version iPad telle quelle, sans travail supplémentaire.

Si le prix n'est pas nul, les **contrats payants** doivent être signés et les
coordonnées bancaires et fiscales renseignées avant la mise en vente : comptez
une journée de démarches et un IBAN sous la main.

---

## 8. Dernières vérifications avant d'envoyer

```sh
# Les tests passent
xcodebuild test -scheme Bobcrapette -destination 'platform=macOS'

# La construction Release pour appareil réel aboutit et est signée
xcodebuild build -scheme Bobcrapette -configuration Release \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates

# Les trois URL du site répondent
for p in "" assistance.html confidentialite.html conditions.html; do
  curl -o /dev/null -s -w "%{http_code}  $p\n" \
    "https://boboul-cloud.github.io/Bobcrapette/$p"
done
```

- [ ] `MARKETING_VERSION` = `1.0` et `CURRENT_PROJECT_VERSION` = `1` dans
      `project.yml`. Le numéro de build doit **augmenter à chaque envoi**.
- [ ] Schéma en configuration *Release*, destination *Any iOS Device*, puis
      *Product ▸ Archive ▸ Distribute App ▸ App Store Connect*.
- [ ] Une partie complète se joue sur un appareil réel.
- [ ] Le compte Apple Developer est actif — 99 € par an, obligatoire pour
      soumettre. Un certificat de développement seul ne suffit pas.
