import Foundation

/// Use case for validating app settings consistency
/// Thread-safe actor that checks for conflicts and invalid values
actor ValidateSettingsUseCase {
    // MARK: - Initialization

    init() {}

    // MARK: - Business Logic

    /// Validates settings and returns corrected version
    /// - Parameter settings: Settings to validate
    /// - Returns: Validated settings with corrections applied
    func execute(_ settings: AppSettings) async -> AppSettings {
        settings.validated()
    }

    /// Validates settings and returns list of issues found
    /// - Parameter settings: Settings to validate
    /// - Returns: Array of validation issue descriptions
    func validate(_ settings: AppSettings) async -> [ValidationIssue] {
        // No validation issues to check currently
        return []
    }

    /// Checks if settings have any validation errors
    /// - Parameter settings: Settings to check
    /// - Returns: True if settings are valid
    func isValid(_ settings: AppSettings) async -> Bool {
        let issues = await validate(settings)
        return issues.filter { $0.severity == .error }.isEmpty
    }
}

// MARK: - Validation Issue Model

/// Represents a settings validation issue
struct ValidationIssue: Sendable {
    enum Severity: String, Sendable {
        case error = "ERROR"
        case warning = "WARNING"
        case info = "INFO"
    }

    let severity: Severity
    let property: String
    let message: String
}
