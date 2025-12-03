//
//  GeneralSettingsView.swift
//  AdlerScope
//
//  Created by adlerflow on 31/10/25.
//

import SwiftUI
import SwiftData

struct GeneralSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        Form {
            Section("Preview") {
                Toggle("Open inline links in preview", isOn: settingsViewModel.openInlineLinkBinding)
                    .help("When enabled, links in the preview pane are clickable and open in your default browser")

                Text("Toggle whether markdown links ([text](url)) in the preview should be clickable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Diagnostics") {
                Toggle("Debug mode", isOn: settingsViewModel.debugBinding)
                    .help("Enable detailed logging for troubleshooting")

                Text("When enabled, detailed rendering logs appear in Console.app (⌘+Space → 'Console')")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
    }
}

@MainActor
private final class MockSettingsRepository: SettingsRepository {
    func load() async throws -> AppSettings? { return .default }
    func save(_ settings: AppSettings) async throws {}
    func resetToDefaults() async throws {}
    func hasSettings() async -> Bool { return true }
}

#Preview {
    let mockRepo = MockSettingsRepository()
    let viewModel = SettingsViewModel(
        loadSettingsUseCase: LoadSettingsUseCase(settingsRepository: mockRepo),
        saveSettingsUseCase: SaveSettingsUseCase(settingsRepository: mockRepo),
        validateSettingsUseCase: ValidateSettingsUseCase()
    )

    GeneralSettingsView()
        .environment(viewModel)
        .frame(width: 600, height: 500)
}
