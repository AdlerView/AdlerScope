import Foundation

/// Domain errors for settings validation
/// Used with typed throws for exhaustive error handling
enum ValidationError: Error, Sendable, Equatable {
    // MARK: - Settings Validation

    /// A required property is missing
    case missingProperty(String)

    /// Property value is out of valid range
    case valueOutOfRange(property: String, value: String, validRange: String)

    /// Property has invalid format
    case invalidFormat(property: String, value: String, expectedFormat: String)

    /// Conflicting property values
    case conflictingProperties(property1: String, property2: String, message: String)

    /// Unknown enum value
    case unknownEnumValue(property: String, value: String, validValues: [String])

    // MARK: - Theme Validation

    /// Theme name is not recognized
    case unknownTheme(String)

    /// Theme file is missing or corrupted
    case themeNotAvailable(String)

    // MARK: - File Validation

    /// URL is invalid
    case invalidURL(String)

    /// File path is not accessible
    case inaccessiblePath(String)

    // MARK: - Equatable Conformance

    static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.missingProperty(let a), .missingProperty(let b)):
            return a == b
        case (.valueOutOfRange(let a1, let a2, let a3), .valueOutOfRange(let b1, let b2, let b3)):
            return a1 == b1 && a2 == b2 && a3 == b3
        case (.invalidFormat(let a1, let a2, let a3), .invalidFormat(let b1, let b2, let b3)):
            return a1 == b1 && a2 == b2 && a3 == b3
        case (.conflictingProperties(let a1, let a2, let a3), .conflictingProperties(let b1, let b2, let b3)):
            return a1 == b1 && a2 == b2 && a3 == b3
        case (.unknownEnumValue(let a1, let a2, let a3), .unknownEnumValue(let b1, let b2, let b3)):
            return a1 == b1 && a2 == b2 && a3 == b3
        case (.unknownTheme(let a), .unknownTheme(let b)):
            return a == b
        case (.themeNotAvailable(let a), .themeNotAvailable(let b)):
            return a == b
        case (.invalidURL(let a), .invalidURL(let b)):
            return a == b
        case (.inaccessiblePath(let a), .inaccessiblePath(let b)):
            return a == b
        default:
            return false
        }
    }

    // MARK: - User-Friendly Messages

    var localizedDescription: String {
        switch self {
        case .missingProperty(let property):
            return "Missing required property: \(property)"
        case .valueOutOfRange(let property, let value, let range):
            return "\(property) value '\(value)' is out of range. Valid range: \(range)"
        case .invalidFormat(let property, let value, let format):
            return "\(property) value '\(value)' has invalid format. Expected: \(format)"
        case .conflictingProperties(let prop1, let prop2, let message):
            return "Conflicting properties \(prop1) and \(prop2): \(message)"
        case .unknownEnumValue(let property, let value, let validValues):
            return "\(property) has unknown value '\(value)'. Valid values: \(validValues.joined(separator: ", "))"
        case .unknownTheme(let theme):
            return "Unknown theme: \(theme)"
        case .themeNotAvailable(let theme):
            return "Theme not available: \(theme)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .inaccessiblePath(let path):
            return "Path is not accessible: \(path)"
        }
    }
}
