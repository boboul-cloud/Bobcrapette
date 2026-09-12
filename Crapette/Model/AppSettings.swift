import Foundation
import Observation

/// Préférences et statistiques, conservées dans les réglages du système.
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings(defaults: .standard)

    var variantPreset: VariantPreset { didSet { store(variantPreset.rawValue, "variant") } }
    var difficulty: Difficulty { didSet { store(difficulty.rawValue, "difficulty") } }
    /// Signale les coups obligatoires et prévient avant une faute.
    var assistEnabled: Bool { didSet { store(assistEnabled, "assist") } }
    var allowUndo: Bool { didSet { store(allowUndo, "undo") } }
    /// Taille de la crapette : 13 cartes comme au jeu de 52, ou 19 pour un jeu de tarot bien rempli.
    var crapetteSize: Int { didSet { store(crapetteSize, "crapetteSize") } }
    /// Multiplicateur de vitesse des animations, de 0,5 (posé) à 2 (rapide).
    var animationSpeed: Double { didSet { store(animationSpeed, "animationSpeed") } }
    var hapticsEnabled: Bool { didSet { store(hapticsEnabled, "haptics") } }
    var humanStarts: Bool { didSet { store(humanStarts, "humanStarts") } }

    private(set) var gamesPlayed: Int { didSet { store(gamesPlayed, "gamesPlayed") } }
    private(set) var gamesWon: Int { didSet { store(gamesWon, "gamesWon") } }

    private let defaults: UserDefaults

    /// `defaults` permet d'isoler le stockage — les tests passent le leur
    /// pour ne pas écrire dans les réglages de l'utilisateur.
    init(defaults: UserDefaults) {
        self.defaults = defaults
        let d = defaults
        variantPreset = VariantPreset(rawValue: d.string(forKey: "variant") ?? "") ?? .tarot77
        difficulty = Difficulty(rawValue: d.string(forKey: "difficulty") ?? "") ?? .normal
        assistEnabled = Self.flag(d, "assist", or: true)
        allowUndo = Self.flag(d, "undo", or: true)
        crapetteSize = Self.number(d, "crapetteSize", or: 13)
        animationSpeed = Self.decimal(d, "animationSpeed", or: 1.0)
        hapticsEnabled = Self.flag(d, "haptics", or: true)
        humanStarts = Self.flag(d, "humanStarts", or: true)
        gamesPlayed = d.integer(forKey: "gamesPlayed")
        gamesWon = d.integer(forKey: "gamesWon")
    }

    /// La variante effective : le préréglage choisi, avec la taille de crapette demandée.
    var variant: GameVariant {
        var v = variantPreset.variant
        v.crapetteSize = crapetteSize
        return v
    }

    func recordResult(won: Bool) {
        gamesPlayed += 1
        if won { gamesWon += 1 }
    }

    func resetStatistics() {
        gamesPlayed = 0
        gamesWon = 0
    }

    /// Lectures tolérantes : une valeur absente rend la valeur par défaut,
    /// et une valeur venue de la ligne de commande est convertie correctement.
    private static func flag(_ d: UserDefaults, _ key: String, or fallback: Bool) -> Bool {
        d.object(forKey: key) == nil ? fallback : d.bool(forKey: key)
    }

    private static func number(_ d: UserDefaults, _ key: String, or fallback: Int) -> Int {
        d.object(forKey: key) == nil ? fallback : d.integer(forKey: key)
    }

    private static func decimal(_ d: UserDefaults, _ key: String, or fallback: Double) -> Double {
        d.object(forKey: key) == nil ? fallback : d.double(forKey: key)
    }

    private func store(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }
}
