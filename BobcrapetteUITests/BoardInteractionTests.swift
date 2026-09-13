import XCTest

/// Tests d'interface : ils tapent et glissent vraiment sur l'écran du
/// simulateur, seule façon de vérifier que les gestes atteignent les cartes.
///
/// Toutes les parties se jouent sur la graine 74, dont la donne est connue :
/// la carte retournée de la crapette du joueur est l'As de cœur, et sa
/// fondation est l'emplacement numéro 2.
final class BoardInteractionTests: XCTestCase {

    private var app: XCUIApplication!
    private let heartsFoundation = "foundation-2"
    /// Les machines d'intégration continue sont lentes : la donne peut
    /// prendre bien plus de temps que sur une machine de développement.
    private let deadline: TimeInterval = 90

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            // Réglages imposés, prioritaires sur ceux enregistrés.
            "-humanStarts", "YES",
            "-assist", "YES",
            "-undo", "YES",
            "-difficulty", "normal",
            "-crapetteSize", "13",
            "-variant", "tarot77",
            "-animationSpeed", "2",
            // Ouvre directement la partie, sur une donne reproductible.
            "-startGame", "-seed", "74"
        ]
        app.launch()
    }

    // MARK: - Repérage

    private func card(_ pile: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "top-\(pile)").firstMatch
    }

    private func slot(_ pile: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "slot-\(pile)").firstMatch
    }

    /// Attend que la donne soit finie **et** que la main soit revenue au
    /// joueur. L'apparition d'une carte ne suffit pas : pendant la
    /// distribution, l'application n'accepte encore aucun coup.
    private func waitForBoard() {
        XCTAssertTrue(app.staticTexts["À vous de jouer"].waitForExistence(timeout: deadline),
                      "La donne ne s'est pas terminée, ou la main n'est pas au joueur")
        XCTAssertTrue(card("crapette-south").waitForExistence(timeout: 10),
                      "Le tapis ne s'est pas affiché")
    }

    /// Attend qu'une carte soit effectivement choisie avant d'enchaîner.
    private func waitUntilSelected(_ element: XCUIElement, timeout: TimeInterval = 15) {
        let chosen = expectation(for: NSPredicate(format: "selected == true"),
                                 evaluatedWith: element)
        wait(for: [chosen], timeout: timeout)
    }

    // MARK: - Tests

    func testLeTapisEstCompletEtAtteignable() {
        waitForBoard()
        XCTAssertTrue(card("stock-south").exists, "Le talon du joueur manque")
        XCTAssertTrue(card("tableau-0").exists, "La première colonne manque")
        XCTAssertTrue(slot(heartsFoundation).exists, "La fondation de cœur manque")
        XCTAssertTrue(card("crapette-south").isHittable, "La crapette n'est pas atteignable")
        XCTAssertTrue(card("tableau-0").isHittable, "Les colonnes ne sont pas atteignables")
        XCTAssertTrue(card("stock-south").isHittable, "Le talon n'est pas atteignable")
    }

    func testToucherUneCarteLaSelectionne() {
        waitForBoard()
        let ace = card("crapette-south")
        XCTAssertFalse(ace.isSelected, "La carte ne devait pas être déjà choisie")

        ace.tap()
        waitUntilSelected(ace)
    }

    func testDeuxTapesEnvoientLAsSurSaFondation() {
        waitForBoard()
        XCTAssertFalse(card(heartsFoundation).exists,
                       "La fondation de cœur devait être vide au départ")

        let ace = card("crapette-south")
        ace.tap()                 // choisit la carte
        waitUntilSelected(ace)    // la deuxième tape n'a de sens qu'après
        ace.tap()                 // la joue sur sa fondation

        XCTAssertTrue(card(heartsFoundation).waitForExistence(timeout: 15),
                      "L'As n'est pas monté sur sa fondation")
    }

    func testGlisserLAsJusquASaFondation() {
        waitForBoard()
        XCTAssertFalse(card(heartsFoundation).exists)

        card("crapette-south").press(forDuration: 0.3, thenDragTo: slot(heartsFoundation))

        XCTAssertTrue(card(heartsFoundation).waitForExistence(timeout: 15),
                      "Le glisser-déposer n'a pas déplacé l'As")
    }

    func testPasserAvecUnCoupObligatoireAvertitLeJoueur() {
        waitForBoard()
        card("stock-south").tap()

        let warning = app.staticTexts["Coup obligatoire"]
        XCTAssertTrue(warning.waitForExistence(timeout: 15),
                      "L'aide visuelle n'a pas signalé le coup obligatoire")

        app.buttons["Jouer le coup"].tap()
        XCTAssertFalse(warning.exists, "L'avertissement aurait dû se refermer")
    }

    func testLesMentionsSontAccessiblesDepuisLesReglages() {
        waitForBoard()
        app.buttons["Réglages"].tap()
        XCTAssertTrue(app.buttons["Terminé"].waitForExistence(timeout: 15),
                      "Les réglages ne se sont pas ouverts")

        // La section « À propos » ferme la liste : SwiftUI ne construit ses
        // lignes qu'une fois qu'elles approchent de l'écran.
        let site = app.staticTexts["Site du jeu"]
        var defilements = 0
        while !site.exists && defilements < 10 {
            app.swipeUp()
            defilements += 1
        }

        XCTAssertTrue(site.exists, "Le lien vers le site manque dans les réglages")
        XCTAssertTrue(app.staticTexts["Politique de confidentialité"].exists,
                      "Le lien vers la politique de confidentialité manque")
        XCTAssertTrue(app.staticTexts["Conditions d'utilisation"].exists,
                      "Le lien vers les conditions manque")
        XCTAssertTrue(app.staticTexts["Assistance"].exists,
                      "Le lien vers l'assistance manque")
    }

    func testUneCarteDeColonneSeChoisitAussi() {
        waitForBoard()
        let column = card("tableau-0")
        column.tap()
        waitUntilSelected(column)
    }
}
