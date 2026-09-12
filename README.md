# Crapette

Un jeu de **crapette au tarot**, natif pour **iPhone, iPad et Mac**. Un seul projet
SwiftUI, une seule cible, trois plateformes.

## La variante jouée

Chaque joueur apporte son jeu de tarot de **77 cartes** : les quatre couleurs de l'As
au Roi avec le **Cavalier** intercalé entre le Valet et la Dame (14 rangs), plus les
**21 atouts** qui forment une cinquième famille. L'Excuse est écartée.

- **Fondations** : dix piles au centre, deux par famille, montées sans trou — de l'As
  au Roi pour les couleurs, de l'atout 1 à l'atout 21 pour les atouts.
- **Colonnes** : huit piles communes, descendantes en alternant rouge et noir. Un atout
  ne se pose que sur un atout de rang immédiatement supérieur ; on ne mélange jamais
  atouts et couleurs dans une colonne. Une colonne vide accueille n'importe quelle carte.
- **Coups offensifs** : on peut charger la crapette ou la défausse de l'adversaire d'une
  carte de la même famille et de rang voisin.
- **Obligations** : poser un As ou l'atout 1 disponible ; monter sur une fondation la
  carte retournée de sa propre crapette. Terminer son tour sans l'avoir fait vaut un
  **« Crapette ! »** : on passe la main sans retourner de carte.
- **Victoire** : le premier qui n'a plus ni crapette, ni talon, ni défausse.

Le règlement complet est consultable dans l'application (bouton `?`).

Les variantes **tarot sans atouts** (56 cartes) et **jeu de 52 classique** sont
disponibles dans les réglages : le moteur de règles est piloté par le nombre de rangs
et d'atouts, rien d'autre ne change.

## Ouvrir le projet

Le projet Xcode est versionné, il suffit de l'ouvrir :

```sh
open Crapette.xcodeproj
```

Il est décrit par `project.yml` et régénéré avec [XcodeGen](https://github.com/yonaskolb/XcodeGen)
après tout ajout de fichier :

```sh
xcodegen generate
```

## Construire et tester

```sh
# Mac
xcodebuild build -scheme Crapette -destination 'platform=macOS'

# iPhone / iPad
xcodebuild build -scheme Crapette -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# La suite de tests
xcodebuild test -scheme Crapette -destination 'platform=macOS'
```

En `DEBUG`, l'argument de lancement `-startGame` ouvre directement une partie, ce qui
évite de passer par le menu quand on inspecte le tapis.

## Organisation

| Dossier | Contenu |
| --- | --- |
| `Crapette/Model` | Le jeu, sans une ligne d'interface : cartes, variantes, position, **moteur de règles**, adversaire artificiel, conduite de la partie, sauvegarde. |
| `Crapette/Views` | Le rendu : cartes dessinées en vectoriel, plan du tapis, plateau, écrans de menu, de réglages et de règles. |
| `CrapetteTests` | 45 tests : composition du jeu, fondations, colonnes, coups offensifs, obligations, déroulement d'un tour, adversaire, conduite de partie et plan du tapis. |
| `Tools/MakeIcon.swift` | Génère l'icône de l'application en CoreGraphics. |

Quelques partis pris :

- **Aucune image.** Cartes, enseignes, figures, atouts et dos sont des tracés vectoriels,
  nets de l'iPhone au Mac et sans un octet d'asset.
- **Le plan du tapis est calculé en « largeurs de carte »**, puis mis à l'échelle. Trois
  pliages existent (paysage, carré, portrait) et l'application retient celui qui donne
  les plus grandes cartes sur l'écran courant.
- **Les cartes sont posées en coordonnées absolues.** Quand la position change, SwiftUI
  interpole : distribution et coups s'animent sans code d'animation par carte.
- **Le moteur de règles est pur et sans état**, donc directement réutilisable par l'IA
  et testable sans interface.

## Réglages

Variante de jeu, taille de la crapette (13 ou 19 cartes), niveau de l'adversaire
(débutant, normal, fort), aide visuelle, annulation, vitesse des animations,
retour haptique, statistiques.
