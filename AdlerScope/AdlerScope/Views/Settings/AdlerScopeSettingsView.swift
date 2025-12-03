//
//  AdlerScopeSettingsView.swift
//  AdlerScope
//
//  Created by adlerflow on 31/10/25.
//

import SwiftUI

/// Pure SwiftUI Settings Window with Clean Architecture
struct AdlerScopeSettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case advanced = "Advanced"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .advanced: return "gearshape.2"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                }
            }
            .padding(12)
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemGray6))
            #endif

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
        }
        .frame(width: 650, height: 550)
        .task {
            // Ensure settings are loaded when view appears
            // This is defensive - normally SettingsWindowContent loads before showing this view
            await settingsViewModel.loadSettingsIfNeeded()
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

    AdlerScopeSettingsView()
        .environment(viewModel)
        .frame(width: 650, height: 550)
}
