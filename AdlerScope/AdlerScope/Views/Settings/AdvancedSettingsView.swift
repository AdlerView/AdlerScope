//
//  AdvancedSettingsView.swift
//  AdlerScope
//
//  Created by adlerflow on 31/10/25.
//

import SwiftUI
import SwiftData

struct AdvancedSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        Form {
            Section("Reset") {
                Button("Reset All Settings to Factory Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)

                Text("This will reset all settings to their default values. Changes are auto-saved after 1 second.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
    }

    private func resetToDefaults() {
        Task {
            await settingsViewModel.resetToDefaults()
        }
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

    AdvancedSettingsView()
        .environment(viewModel)
        .frame(width: 600, height: 500)
}
