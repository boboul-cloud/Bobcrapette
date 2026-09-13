import SwiftUI

/// Les règles de la variante jouée, telles que l'application les applique.
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    RuleSection(
                        "But du jeu",
                        "Se débarrasser le premier de ses trois paquets personnels : sa crapette, son talon et sa défausse. Les colonnes du centre n'appartiennent à personne."
                    )

                    RuleSection(
                        "Le matériel",
                        """
                        Chaque joueur apporte son jeu de tarot, reconnaissable à son dos. Un jeu compte 77 cartes :
                        • les quatre couleurs, de l'As au Roi, avec le Cavalier intercalé entre le Valet et la Dame — soit 14 cartes par couleur ;
                        • les 21 atouts, numérotés de 1 à 21, qui forment une cinquième famille.
                        L'Excuse est écartée.
                        """
                    )

                    RuleSection(
                        "La donne",
                        """
                        On distribue à chacun 13 cartes face cachée : c'est la crapette, dont on retourne la carte du dessus. Chacun pose ensuite 4 cartes face visible devant lui : les huit colonnes du centre. Le reste, 60 cartes, forme le talon.
                        """
                    )

                    RuleSection(
                        "Les fondations",
                        """
                        Au centre, dix piles se montent par famille, sans trou : de l'As au Roi pour chaque couleur, de l'atout 1 à l'atout 21 pour les atouts. Deux piles par famille, puisque deux jeux sont en présence — et les cartes des deux jeux se mélangent sur une même pile.
                        """
                    )

                    RuleSection(
                        "Les colonnes",
                        """
                        Les huit colonnes du centre se descendent en alternant rouge et noir : un 7 de cœur se pose sur un 8 de pique ou de trèfle.
                        Les atouts font bande à part : un atout ne se pose que sur un atout de rang immédiatement supérieur, sans contrainte de couleur. Aucune carte de couleur ne se pose sur un atout, et réciproquement.
                        Une colonne vide accueille n'importe quelle carte.
                        On ne déplace jamais qu'une carte à la fois.
                        """
                    )

                    RuleSection(
                        "Gêner l'adversaire",
                        """
                        C'est ce qui fait tout le sel du jeu : vous pouvez poser sur la crapette ou la défausse de l'adversaire une carte de la même famille et de rang voisin, au-dessus ou en dessous. Chaque carte ainsi déposée rallonge son travail.
                        """
                    )

                    RuleSection(
                        "Le déroulement d'un tour",
                        """
                        Vous enchaînez autant de coups que vous voulez, en jouant la carte du dessus de votre crapette, de votre défausse ou d'une colonne. Le tour se termine quand vous retournez une carte de votre talon sur votre défausse.
                        Talon épuisé ? On retourne la défausse pour en refaire un talon.
                        """
                    )

                    RuleSection(
                        "Les coups obligatoires et le cri de « Crapette ! »",
                        """
                        Deux coups ne se refusent pas :
                        1. poser un As ou l'atout 1 dès qu'il est disponible ;
                        2. poser sur une fondation la carte retournée de sa propre crapette, si elle y a sa place.
                        Celui qui termine son tour en laissant passer l'un de ces coups se fait crier « Crapette ! » : il perd la main sans retourner de carte, et le coup obligatoire l'attend toujours au tour suivant.
                        Le cri marche dans les deux sens — surveillez l'adversaire, un bouton apparaît quelques secondes quand il faute.
                        """
                    )

                    RuleSection(
                        "Prendre la main dans l'application",
                        """
                        • Touchez une carte : elle se met en avant et les emplacements où elle peut aller s'allument en vert.
                        • Touchez-la une seconde fois : elle part d'elle-même sur sa fondation, ou vers l'unique destination possible.
                        • Vous pouvez aussi la faire glisser jusqu'au paquet visé.
                        • Un liseré orange signale un coup obligatoire, un liseré bleu le conseil demandé, un liseré rose le dernier coup de l'adversaire.
                        • Le bouton du bas retourne une carte de votre talon et passe la main.
                        """
                    )

                    RuleSection(
                        "Une partie sans vainqueur",
                        "Si plus personne ne peut jouer ni retourner de carte, la partie est déclarée nulle."
                    )
                }
                .padding(22)
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Règles de la crapette")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 620, minHeight: 560, idealHeight: 680)
        #endif
    }

    @ViewBuilder
    private func RuleSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .serif))
            Text(body)
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
