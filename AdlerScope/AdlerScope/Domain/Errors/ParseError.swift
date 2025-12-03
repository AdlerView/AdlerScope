import Foundation

/// Domain errors for markdown parsing operations
/// Used with typed throws for exhaustive error handling
enum ParseError: Error, Sendable, Equatable {
    // MARK: - Parsing Errors

    /// Markdown syntax is invalid
    case invalidSyntax(line: Int?, message: String)

    /// Parser encountered an internal error
    case parserInternalError(String)

    /// Parsing timed out (content too complex)
    case timeout(estimatedTime: Int)

    /// Unsupported markdown extension requested
    case unsupportedExtension(String)

    // MARK: - Content Errors

    /// Markdown content is empty
    case emptyInput

    /// Markdown content exceeds complexity limit
    case complexityLimitExceeded(complexity: Int, limit: Int)

    /// Invalid YAML front matter
    case invalidYAMLFrontMatter(String)

    /// Math syntax error (LaTeX)
    case invalidMathSyntax(line: Int?, message: String)

    // MARK: - Configuration Errors

    /// Invalid parser settings
    case invalidSettings(String)

    /// Conflicting parser options
    case conflictingOptions(String)

    // MARK: - User-Friendly Messages

    var localizedDescription: String {
        switch self {
        case .invalidSyntax(let line, let message):
            if let line = line {
                return "Syntax error at line \(line): \(message)"
            } else {
                return "Syntax error: \(message)"
            }
        case .parserInternalError(let message):
            return "Parser error: \(message)"
        case .timeout(let estimatedTime):
            return "Parsing timed out (estimated \(estimatedTime)ms). Document may be too complex."
        case .unsupportedExtension(let ext):
            return "Unsupported markdown extension: \(ext)"
        case .emptyInput:
            return "Cannot parse empty markdown content"
        case .complexityLimitExceeded(let complexity, let limit):
            return "Document complexity (\(complexity)) exceeds limit (\(limit))"
        case .invalidYAMLFrontMatter(let message):
            return "Invalid YAML front matter: \(message)"
        case .invalidMathSyntax(let line, let message):
            if let line = line {
                return "Math syntax error at line \(line): \(message)"
            } else {
                return "Math syntax error: \(message)"
            }
        case .invalidSettings(let message):
            return "Invalid parser settings: \(message)"
        case .conflictingOptions(let message):
            return "Conflicting parser options: \(message)"
        }
    }
}
