# Déclaration de confidentialité App Store (« étiquette nutritionnelle »)

Réponses à donner dans App Store Connect, onglet **Confidentialité de l'app**.

---

## La seule question qui compte

> **Recueillez-vous, vous ou vos partenaires tiers, des données à partir de cette app ?**
>
> ### ▸ Non, nous ne recueillons aucune donnée à partir de cette app.

Le questionnaire s'arrête là. L'étiquette affichée sur la fiche App Store sera
**« Aucune donnée collectée »**.

---

## Pourquoi cette réponse est exacte

Apple définit la collecte comme la transmission de données hors de l'appareil.
Bobcrapette n'en transmet aucune :

- **aucun code réseau** — l'application n'embarque ni `URLSession`, ni client
  HTTP, ni socket. Elle ne peut techniquement contacter aucun serveur. Les
  liens de la section « À propos » sont de simples `Link` SwiftUI : ils passent
  la main à Safari, qui se connecte à notre place ;
- **aucune bibliothèque tierce** — le projet ne dépend d'aucun paquet externe,
  donc d'aucun kit susceptible de collecter à notre insu ;
- **aucun identifiant** — ni compte, ni IDFA, ni identifiant d'appareil lu ;
- **aucune autorisation demandée** — pas de localisation, de contacts, de
  photos, de micro, d'appareil photo ni de notifications. L'`Info.plist` ne
  contient aucune clé `NS…UsageDescription`, ce qui se vérifie d'un coup d'œil.

Le jeu écrit trois choses dans son propre espace sur l'appareil : la partie en
cours, les réglages et les statistiques. Apple ne considère pas comme une
collecte ce qui reste sur l'appareil et n'est jamais transmis.

## Vérification

```sh
# Aucun appel réseau dans le code
grep -rn "URLSession\|NSURLConnection\|CFNetwork\|Network\." Bobcrapette/ || echo "aucun"

# Aucune autorisation demandée
/usr/libexec/PlistBuddy -c Print Bobcrapette.app/Info.plist | grep UsageDescription || echo "aucune"
```

## Champs liés

| Champ App Store Connect | Réponse |
| --- | --- |
| Politique de confidentialité (URL) | `https://boboul-cloud.github.io/Bobcrapette/confidentialite.html` |
| Suivi publicitaire (App Tracking Transparency) | Non concerné — aucun suivi |
| Contenu généré par les utilisateurs | Non |
| Publicité tierce | Non |
| Achats intégrés | Non |
| Connexion avec un compte | Non |
