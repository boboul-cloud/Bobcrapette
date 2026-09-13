# Notes pour l'équipe de revue Apple

À coller dans le champ **App Review Information ▸ Notes** d'App Store Connect.
Les relecteurs d'Apple travaillent en anglais : la version anglaise est donnée
en premier, c'est elle qu'il faut recopier.

---

## English (à recopier dans App Store Connect)

```
Bobcrapette is a single-player implementation of Crapette (also known as
Russian Bank), a traditional two-player French card game, played here against
a computer opponent.

LANGUAGE
The app's interface is in French only. Crapette is a French family card game
and the terminology ("crapette", "talon", "défausse", "atout") has no settled
English equivalent. Nothing in the app requires reading English.

NO ACCOUNT, NO NETWORK
No sign-in, no account, no registration. The app is fully offline: it contains
no networking code and contacts no server. It can be reviewed in airplane mode.

NO GAMBLING
This is a patience/solitaire-style card game. There is no wagering, no virtual
currency, no loot box, no simulated gambling of any kind. Age rating 4+.

NO DATA COLLECTED
The app collects nothing. It stores only the game in progress, the user's
settings and a win/loss counter, all in its own container on device. No
third-party SDKs are bundled.

HOW TO TRY IT IN ONE MINUTE
1. Tap "Nouvelle partie" (New game). Cards are dealt automatically.
2. Tap any card: the places it can legally go light up in green.
3. Tap it a second time and it flies to its foundation on its own.
4. You can also drag a card onto its destination.
5. The yellow button at the bottom right ("Retourner une carte") turns a card
   from your stock and ends your turn. The computer then plays its own turn.

TWO THINGS THAT MAY LOOK UNUSUAL
- An orange ring around a card means a compulsory move. In Crapette, an Ace
  must be played to the centre as soon as it is available. Ending your turn
  while one is pending triggers a penalty.
- A large red "CRAPETTE !" button sometimes appears for a few seconds at the
  bottom of the screen. This is the traditional call: the computer opponent
  missed a compulsory move and you may catch it out. It is part of the game,
  not an advertisement or an external link.

SETTINGS
"Réglages" (gear icon) contains the game variants, the opponent's level, and an
"À propos" section linking to the privacy policy, the terms of use and the
support page.

Contact: bob.oulhen@gmail.com
```

---

## Français (pour mémoire)

Bobcrapette est une mise en œuvre de la crapette, jeu de cartes traditionnel à
deux, jouée ici contre un adversaire artificiel.

- **Langue** : interface en français uniquement, ce qui se justifie par la nature
  du jeu. Aucune lecture de l'anglais n'est nécessaire.
- **Pas de compte, pas de réseau** : aucune inscription, aucun code réseau,
  testable en mode avion.
- **Pas de jeu d'argent** : ni mise, ni monnaie virtuelle, ni coffre à butin.
  Classification 4+.
- **Aucune donnée collectée**.
- **Deux points à expliquer** au relecteur : le liseré orange des coups
  obligatoires, et le bouton « CRAPETTE ! » qui apparaît quelques secondes quand
  l'adversaire commet une faute. Ce sont des éléments de règle, pas des
  publicités.

## Compte de démonstration

Aucun. Cocher **« Connexion requise : non »**.
