import Foundation

/// Une partie mise de côté, pour la retrouver au prochain lancement.
struct SavedGame: Codable, Sendable {
    var state: GameState
    var difficulty: Difficulty
    var savedAt: Date
}

/// Rangement de la partie en cours sur le disque.
enum GameArchive {
    private static let filename = "partie-en-cours.json"

    private static var url: URL? {
        guard let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return nil }
        return directory.appendingPathComponent(filename)
    }

    static func save(_ game: SavedGame) {
        guard let url else { return }
        do {
            let data = try JSONEncoder().encode(game)
            try data.write(to: url, options: .atomic)
        } catch {
            // Une sauvegarde ratée ne doit jamais interrompre la partie.
        }
    }

    static func load() -> SavedGame? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedGame.self, from: data)
    }

    static func clear() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
