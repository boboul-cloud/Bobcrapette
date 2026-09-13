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
    private let deadline: TimeInterval = 25

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

    private func waitForBoard() {
        XCTAssertTrue(card("crapette-south").waitForExistence(timeout: deadline),
                      "Le tapis ne s'est pas affiché")
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

        let chosen = expectation(for: NSPredicate(format: "selected == true"),
                                 evaluatedWith: ace)
        wait(for: [chosen], timeout: 5)
    }

    func testDeuxTapesEnvoientLAsSurSaFondation() {
        waitForBoard()
        XCTAssertFalse(card(heartsFoundation).exists,
                       "La fondation de cœur devait être vide au départ")

        let ace = card("crapette-south")
        ace.tap()   // choisit la carte
        ace.tap()   // la joue sur sa fondation

        XCTAssertTrue(card(heartsFoundation).waitForExistence(timeout: 5),
                      "L'As n'est pas monté sur sa fondation")
    }

    func testGlisserLAsJusquASaFondation() {
        waitForBoard()
        XCTAssertFalse(card(heartsFoundation).exists)

        card("crapette-south").press(forDuration: 0.2, thenDragTo: slot(heartsFoundation))

        XCTAssertTrue(card(heartsFoundation).waitForExistence(timeout: 5),
                      "Le glisser-déposer n'a pas déplacé l'As")
    }

    func testPasserAvecUnCoupObligatoireAvertitLeJoueur() {
        waitForBoard()
        card("stock-south").tap()

        let warning = app.staticTexts["Coup obligatoire"]
        XCTAssertTrue(warning.waitForExistence(timeout: 5),
                      "L'aide visuelle n'a pas signalé le coup obligatoire")

        app.buttons["Jouer le coup"].tap()
        XCTAssertFalse(warning.exists, "L'avertissement aurait dû se refermer")
    }

    func testUneCarteDeColonneSeChoisitAussi() {
        waitForBoard()
        let column = card("tableau-0")
        column.tap()

        let chosen = expectation(for: NSPredicate(format: "selected == true"),
                                 evaluatedWith: column)
        wait(for: [chosen], timeout: 5)
    }
}
