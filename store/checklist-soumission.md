# Feuille de route de la soumission

Ce qui est **fait**, ce qui **demande une décision**, et ce qui **reste à faire
chez Apple**. Tout ce qui relève du dépôt est déjà en place.

---

## ✅ Fait dans le dépôt

- [x] **Icône** complète (16 → 1024 px, iOS et macOS), générée en vectoriel par
      `Tools/MakeIcon.swift`.
- [x] **Conformité à l'exportation** : `ITSAppUsesNonExemptEncryption = false`
      dans l'`Info.plist`. Apple ne posera plus la question à chaque envoi.
- [x] **Droits d'auteur** dans l'`Info.plist` (`NSHumanReadableCopyright`).
- [x] **Orientations** déclarées par famille d'appareil, iPad multitâche compris.
- [x] **Signature** automatique sur l'équipe `38DQ8FW23J`, vérifiée sur Mac,
      simulateur et appareil réel.
- [x] **Politique de confidentialité** publiée, bilingue.
- [x] **Conditions d'utilisation** publiées, bilingues.
- [x] **Page d'assistance** publiée, avec questions fréquentes.
- [x] **Mentions accessibles depuis l'app** : `Réglages ▸ À propos` renvoie vers
      les trois pages, comme Apple le recommande.
- [x] **Captures** aux deux tailles exigées, avec barre d'état à 9:41.
- [x] **Fiche** rédigée et calibrée aux limites de caractères.
- [x] **Étiquette de confidentialité** : aucune donnée collectée.
- [x] **Notes pour la revue**, en anglais.

---

## ⚠️ Décisions qui vous reviennent

- [ ] **Prix.** Gratuit ou payant ? L'application n'a ni publicité ni achat
      intégré : le modèle naturel est soit gratuit, soit un achat unique autour
      de 2,99 €. Ce choix se fait dans App Store Connect, rien à changer dans le
      code.
- [ ] **Disponibilité Mac.** Deux options : publier une vraie application Mac
      depuis la même fiche (prévoir alors une capture 1280 × 800), ou se contenter
      de « Rendre disponible sur Mac » pour les Mac Apple silicon.
- [ ] **Territoires.** Par défaut, le monde entier. L'interface étant en français,
      vous pouvez restreindre à la France, la Belgique, la Suisse, le Canada et le
      Luxembourg — ou laisser ouvert, le jeu se comprend aux couleurs des cartes.
- [ ] **Compte développeur.** Le programme Apple Developer coûte 99 € par an et
      est obligatoire pour publier. Votre certificat actuel est un certificat de
      développement : il permet d'installer sur vos appareils, pas de soumettre.

---

## 📋 À faire dans App Store Connect

1. **Créer la fiche** : *Mes apps ▸ +* → plateforme iOS, nom `Bobcrapette`,
   langue principale français (France), identifiant `com.oulhen.bobcrapette`.
2. **Recopier** `fiche-app-store.md` : sous-titre, description, mots-clés, texte
   promotionnel, nouveautés, catégories, URL.
3. **Téléverser les captures** de `store/captures/`.
4. **Répondre au questionnaire de classification** : tout à *Aucun*, et bien
   répondre **Non** aux jeux d'argent simulés → 4+.
5. **Remplir la confidentialité** : voir `confidentialite-app-store.md`.
   Réponse unique : aucune donnée collectée.
6. **Coller les notes de revue** : voir `notes-pour-la-revue.md`.
7. **Envoyer la version** depuis Xcode : *Product ▸ Archive*, puis
   *Distribute App ▸ App Store Connect*. Vérifier auparavant que le schéma est
   en configuration *Release* et la destination *Any iOS Device*.
8. **Soumettre pour examen.** Comptez un à trois jours.

---

## 🔍 Vérifications avant d'archiver

```sh
# Les tests passent
xcodebuild test -scheme Bobcrapette -destination 'platform=macOS'
xcodebuild test -scheme BobcrapetteUI -destination 'platform=iOS Simulator,name=iPhone 17'

# La construction Release pour appareil réel aboutit et est signée
xcodebuild build -scheme Bobcrapette -configuration Release \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates
```

- [ ] Le numéro de version (`MARKETING_VERSION`) et le numéro de build
      (`CURRENT_PROJECT_VERSION`) sont à jour dans `project.yml`. Le numéro de
      build doit **augmenter à chaque envoi**, même pour corriger une broutille.
- [ ] Les trois URL du site répondent bien (vérifier après l'activation de
      GitHub Pages, qui prend quelques minutes).
- [ ] L'application se lance sur un appareil réel et une partie va jusqu'au bout.

---

## Motifs de refus les plus fréquents, et où nous en sommes

| Motif | Situation |
| --- | --- |
| Politique de confidentialité absente ou inaccessible | Publiée et liée depuis l'app ✅ |
| Fiche qui ne décrit pas l'app | Description fidèle, captures réelles ✅ |
| Application incomplète ou de démonstration | Jeu complet, moteur de règles couvert par 51 tests ✅ |
| Pas de valeur ajoutée / simple gabarit | Moteur, IA et dessin des cartes écrits pour ce jeu ✅ |
| Plantage au lancement | Testé sur iPhone, iPad, Mac et appareil réel ✅ |
| Classification inadaptée | 4+, sans jeu d'argent simulé ✅ |
| Liens morts dans la fiche | À revérifier une fois Pages en ligne ⚠️ |
