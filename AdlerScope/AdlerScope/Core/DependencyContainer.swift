//
//  DependencyContainer.swift
//  AdlerScope
//
//  Centralized dependency injection container
//  Manages lifecycle and dependencies of all app components
//

import Foundation
import SwiftUI
import SwiftData
import Observation

/// Singleton dependency injection container
/// Provides lazy initialization of repositories, use cases, and view models
@Observable
class DependencyContainer {
    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - SwiftData Context

    private var modelContext: ModelContext?

    /// Configures the container with ModelContext (must be called at app startup)
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settingsRepositoryProvider = { SettingsRepositoryImpl(modelContext: modelContext) }
    }

    // MARK: - Services

    private var _photoLibraryService: PhotoLibraryService?
    private var _cloudKitService: CloudKitService?
    private var _iCloudDocumentManager: ICloudDocumentManager?

    var photoLibraryService: PhotoLibraryService {
        if _photoLibraryService == nil {
            _photoLibraryService = PhotoLibraryService()
        }
        return _photoLibraryService!
    }

    var cloudKitService: CloudKitService {
        if _cloudKitService == nil {
            _cloudKitService = CloudKitService()
        }
        return _cloudKitService!
    }

    var iCloudDocumentManager: ICloudDocumentManager {
        if _iCloudDocumentManager == nil {
            _iCloudDocumentManager = ICloudDocumentManager()
        }
        return _iCloudDocumentManager!
    }

    @MainActor
    var notificationService: NotificationService {
        return NotificationService.shared
    }

    @MainActor
    var navigationService: NavigationService {
        return NavigationService.shared
    }

    // MARK: - Repositories (Data Layer)

    private(set) var documentRepository: DocumentRepository = DocumentRepositoryImpl()

    private(set) var settingsRepositoryProvider: () -> SettingsRepository = { fatalError("DependencyContainer must be configured with ModelContext before accessing settingsRepository") }

    var settingsRepository: SettingsRepository {
        get { settingsRepositoryProvider() }
    }

    private(set) var markdownParserRepository: MarkdownParserRepository = MarkdownParserRepositoryImpl()

    // MARK: - Use Cases (Domain Layer)

    var parseMarkdownUseCase: ParseMarkdownUseCase {
        ParseMarkdownUseCase(parserRepository: markdownParserRepository)
    }

    var loadSettingsUseCase: LoadSettingsUseCase {
        LoadSettingsUseCase(settingsRepository: settingsRepository)
    }

    var saveSettingsUseCase: SaveSettingsUseCase {
        SaveSettingsUseCase(settingsRepository: settingsRepository)
    }

    var validateSettingsUseCase: ValidateSettingsUseCase {
        ValidateSettingsUseCase()
    }

    var saveDocumentUseCase: SaveDocumentUseCase {
        SaveDocumentUseCase(documentRepository: documentRepository, createBackups: true)
    }

    // MARK: - View Models (Presentation Layer)

    /// Creates a new SettingsViewModel instance.
    /// NOTE: Do NOT call this multiple times - use @State in App to store the instance.
    /// This factory method exists to support proper SwiftUI lifecycle management.
    /// The old computed property was causing EXC_BAD_ACCESS crashes because each access
    /// created a new instance, and FocusedValue closures held references to deallocated instances.
    @MainActor
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            loadSettingsUseCase: loadSettingsUseCase,
            saveSettingsUseCase: saveSettingsUseCase,
            validateSettingsUseCase: validateSettingsUseCase
        )
    }

    // MARK: - Initialization

    private init() {
        // Private init to enforce singleton pattern
    }

    // MARK: - Factory Methods

    /// Creates a new DocumentManager for document operations
    /// - Returns: Configured DocumentManager
    func makeDocumentManager() -> DocumentManager {
        DocumentManager(documentRepository: documentRepository)
    }

    /// Creates a new SplitEditorViewModel for a document window
    /// - Parameter settingsViewModel: The SettingsViewModel instance to use (should be the @State managed one from App)
    /// - Returns: Configured SplitEditorViewModel
    @MainActor
    func makeSplitEditorViewModel(settingsViewModel: SettingsViewModel) -> SplitEditorViewModel {
        SplitEditorViewModel(
            parseMarkdownUseCase: parseMarkdownUseCase,
            settingsViewModel: settingsViewModel
        )
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    /// Resets all lazy dependencies (for testing purposes)
    func reset() {
        // Force re-initialization on next access
        // Note: This is a simplified version - in production you'd need more sophisticated reset logic
    }
    #endif
}

// MARK: - Environment Key

/// Environment key for dependency container
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = .shared
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Injects the dependency container into the environment
    func withDependencyContainer() -> some View {
        self.environment(\.dependencyContainer, DependencyContainer.shared)
    }
}

