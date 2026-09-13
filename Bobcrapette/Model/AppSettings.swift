import Foundation
import Observation

/// Ce que coûte un « Crapette ! » crié à tort. Il faut bien que cela coûte
/// quelque chose : sans prix, la meilleure tactique serait d'appuyer à chaque
/// tour au cas où, et le cri ne voudrait plus rien dire.
enum FalseCallPenalty: String, CaseIterable, Codable, Sendable, Identifiable {
    /// On passe la main sans retourner de carte : la punition qu'on voulait
    /// infliger se retourne contre soi.
    case loseTurn
    /// Rien du tout, hormis le démenti.
    case harmless
    /// Un nombre d'erreurs compté ; au-delà, le bouton ne répond plus.
    case rationed

    var id: String { rawValue }

    /// Erreurs tolérées par partie, quand elles sont comptées.
    static let allowance = 3

    var title: String {
        switch self {
        case .loseTurn: "Vous perdez la main"
        case .harmless: "Rien"
        case .rationed: "Trois erreurs par partie"
        }
    }

    var subtitle: String {
        switch self {
        case .loseTurn:
            "Crier à tort vous fait passer la main sans retourner de carte : exactement la punition que vous vouliez infliger. C'est la règle de table la plus courante."
        case .harmless:
            "Un simple démenti, et la partie continue. Rien ne vous empêche alors de tenter votre chance à chaque tour."
        case .rationed:
            "Trois erreurs par partie, ensuite le bouton se tait. Les cris justes ne comptent pas : seules les erreurs se paient."
        }
    }
}

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
    /// Maintenir le doigt sur une carte l'affiche en grand, le temps de la lire.
    var magnifierEnabled: Bool { didSet { store(magnifierEnabled, "magnifier") } }
    var humanStarts: Bool { didSet { store(humanStarts, "humanStarts") } }
    /// Ce que coûte un « Crapette ! » crié à tort.
    var falseCallPenalty: FalseCallPenalty { didSet { store(falseCallPenalty.rawValue, "falseCall") } }

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
        magnifierEnabled = Self.flag(d, "magnifier", or: true)
        humanStarts = Self.flag(d, "humanStarts", or: true)
        falseCallPenalty = FalseCallPenalty(rawValue: d.string(forKey: "falseCall") ?? "") ?? .loseTurn
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
