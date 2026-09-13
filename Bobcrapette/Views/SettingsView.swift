import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Picker("Jeu de cartes", selection: $settings.variantPreset) {
                        ForEach(VariantPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    Text(settings.variantPreset.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker("Taille de la crapette", selection: $settings.crapetteSize) {
                        Text("13 cartes").tag(13)
                        Text("19 cartes").tag(19)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Vous commencez", isOn: $settings.humanStarts)
                } header: {
                    Text("La partie")
                } footer: {
                    Text("Ces réglages s'appliquent à la prochaine nouvelle partie.")
                }

                Section("L'adversaire") {
                    Picker("Niveau", selection: $settings.difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(settings.difficulty.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Aide visuelle", isOn: $settings.assistEnabled)
                    Toggle("Autoriser l'annulation", isOn: $settings.allowUndo)
                } header: {
                    Text("Assistance")
                } footer: {
                    Text("L'aide visuelle signale les coups obligatoires d'un liseré orange et vous prévient avant une faute. Sans elle, les règles sont appliquées sans avertissement.")
                }

                Section("Confort") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Vitesse des animations")
                            Spacer()
                            Text(speedLabel).foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: $settings.animationSpeed, in: 0.5...2.0, step: 0.25)
                    }
                    #if os(iOS)
                    Toggle("Retour haptique", isOn: $settings.hapticsEnabled)
                    #endif
                }

                Section("Statistiques") {
                    LabeledContent("Parties jouées", value: "\(settings.gamesPlayed)")
                    LabeledContent("Victoires", value: "\(settings.gamesWon)")
                    if settings.gamesPlayed > 0 {
                        LabeledContent("Taux de réussite",
                                       value: "\(Int(Double(settings.gamesWon) / Double(settings.gamesPlayed) * 100)) %")
                    }
                    Button("Remettre les compteurs à zéro", role: .destructive) {
                        confirmReset = true
                    }
                }

                Section {
                    LabeledContent("Version", value: Self.version)
                    Link(destination: Self.siteURL) {
                        Label("Site du jeu", systemImage: "globe")
                    }
                    Link(destination: Self.privacy) {
                        Label("Politique de confidentialité", systemImage: "hand.raised")
                    }
                    Link(destination: Self.terms) {
                        Label("Conditions d'utilisation", systemImage: "doc.text")
                    }
                    Link(destination: Self.support) {
                        Label("Assistance", systemImage: "lifepreserver")
                    }
                } header: {
                    Text("À propos")
                } footer: {
                    Text("Bobcrapette ne collecte aucune donnée et ne se connecte à aucun serveur. Vos parties, vos réglages et vos statistiques ne quittent jamais cet appareil.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Réglages")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { dismiss() }
                }
            }
            .alert("Effacer les statistiques ?", isPresented: $confirmReset) {
                Button("Annuler", role: .cancel) {}
                Button("Effacer", role: .destructive) { settings.resetStatistics() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 560, idealHeight: 620)
        #endif
    }

    private var speedLabel: String {
        String(format: "×%.2g", settings.animationSpeed)
    }

    // MARK: - Mentions

    private static let site = "https://boboul-cloud.github.io/Bobcrapette"
    private static let siteURL = URL(string: site)!
    private static let privacy = URL(string: "\(site)/confidentialite.html")!
    private static let terms = URL(string: "\(site)/conditions.html")!
    private static let support = URL(string: "\(site)/assistance.html")!

    private static var version: String {
        let marketing = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(marketing) (\(build))"
    }
}
