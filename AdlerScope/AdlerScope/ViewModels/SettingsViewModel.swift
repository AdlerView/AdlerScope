import SwiftUI
import Observation
import OSLog

/// ViewModel for all settings views (General, Extensions, Syntax, Advanced)
/// Uses @MainActor to ensure all UI-bound properties are accessed on the main thread
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Properties

    var settings: AppSettings {
        didSet {
            scheduleAutoSave()
        }
    }

    /// Indicates if settings are currently being loaded
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let loadSettingsUseCase: LoadSettingsUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let validateSettingsUseCase: ValidateSettingsUseCase

    // MARK: - Auto-save

    @ObservationIgnored private var autoSaveTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        loadSettingsUseCase: LoadSettingsUseCase,
        saveSettingsUseCase: SaveSettingsUseCase,
        validateSettingsUseCase: ValidateSettingsUseCase
    ) {
        self.loadSettingsUseCase = loadSettingsUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        self.validateSettingsUseCase = validateSettingsUseCase

        // Initialize with defaults - actual loading happens via .task modifier in views
        self.settings = .default
        // NO Task {} here! Loading is triggered by views using .task modifier
        // This ensures structured concurrency tied to view lifecycle
    }

    // MARK: - Settings Management

    /// Loads settings if not already loading. Call this from views using .task modifier.
    func loadSettingsIfNeeded() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        settings = await loadSettingsUseCase.execute()
    }

    /// Legacy method for compatibility - prefer loadSettingsIfNeeded()
    func loadSettings() async {
        await loadSettingsIfNeeded()
    }

    func saveSettings() async {
        do {
            try await saveSettingsUseCase.execute(settings)
        } catch {
            os_log("Failed to save settings: %{public}@", log: .settings, type: .error, String(describing: error))
        }
    }

    func resetToDefaults() async {
        do {
            try await saveSettingsUseCase.resetToDefaults()
            settings = .default
        } catch {
            os_log("Failed to reset settings: %{public}@", log: .settings, type: .error, String(describing: error))
        }
    }

    func validateSettings() async -> [ValidationIssue] {
        await validateSettingsUseCase.validate(settings)
    }

    // MARK: - Convenience Accessors

    var editor: EditorSettings {
        get { settings.editor ?? EditorSettings.default }
        set {
            settings = AppSettings(
                id: settings.id,
                editor: newValue
            )
        }
    }

    // MARK: - Bindings for Settings Properties

    var openInlineLinkBinding: Binding<Bool> {
        Binding(
            get: { self.editor.openInlineLink },
            set: { newValue in
                var updatedEditor = self.editor
                updatedEditor.openInlineLink = newValue
                self.editor = updatedEditor
            }
        )
    }

    var debugBinding: Binding<Bool> {
        Binding(
            get: { self.editor.debug },
            set: { newValue in
                var updatedEditor = self.editor
                updatedEditor.debug = newValue
                self.editor = updatedEditor
            }
        )
    }

    // MARK: - Auto-Save

    private func scheduleAutoSave() {
        // Cancel any pending save task
        autoSaveTask?.cancel()

        // Schedule new save with 1 second debounce
        // Note: @MainActor on class ensures this runs on main thread
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(1))

            guard !Task.isCancelled else { return }

            await saveSettings()
        }
    }

    // MARK: - Cleanup

    deinit {
        autoSaveTask?.cancel()
    }
}

