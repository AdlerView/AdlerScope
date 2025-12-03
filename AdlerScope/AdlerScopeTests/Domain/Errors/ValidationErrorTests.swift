//
//  ValidationErrorTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for ValidationError
//

import Testing
@testable import AdlerScope

@Suite("ValidationError Tests")
struct ValidationErrorTests {

    @Test("Missing property error")
    func testMissingProperty() {
        // Arrange & Act
        let error = ValidationError.missingProperty("requiredField")

        // Assert
        #expect(error.localizedDescription.contains("Missing required property"))
        #expect(error.localizedDescription.contains("requiredField"))
    }

    @Test("Value out of range error")
    func testValueOutOfRange() {
        // Arrange & Act
        let error = ValidationError.valueOutOfRange(
            property: "tabWidth",
            value: "20",
            validRange: "1-16"
        )

        // Assert
        #expect(error.localizedDescription.contains("out of range"))
        #expect(error.localizedDescription.contains("tabWidth"))
        #expect(error.localizedDescription.contains("1-16"))
    }

    @Test("Invalid format error")
    func testInvalidFormat() {
        // Arrange & Act
        let error = ValidationError.invalidFormat(
            property: "url",
            value: "not-a-url",
            expectedFormat: "https://..."
        )

        // Assert
        #expect(error.localizedDescription.contains("invalid format"))
        #expect(error.localizedDescription.contains("url"))
    }

    @Test("Conflicting properties error")
    func testConflictingProperties() {
        // Arrange & Act
        let error = ValidationError.conflictingProperties(
            property1: "enableHardBreaks",
            property2: "disableSoftBreaks",
            message: "Cannot enable both"
        )

        // Assert
        #expect(error.localizedDescription.contains("Conflicting"))
        #expect(error.localizedDescription.contains("enableHardBreaks"))
        #expect(error.localizedDescription.contains("disableSoftBreaks"))
    }

    @Test("Unknown enum value error")
    func testUnknownEnumValue() {
        // Arrange & Act
        let error = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid-theme",
            validValues: ["github", "github-dark"]
        )

        // Assert
        #expect(error.localizedDescription.contains("unknown value"))
        #expect(error.localizedDescription.contains("theme"))
        #expect(error.localizedDescription.contains("github"))
    }

    @Test("Unknown theme error")
    func testUnknownTheme() {
        // Arrange & Act
        let error = ValidationError.unknownTheme("custom-theme")

        // Assert
        #expect(error.localizedDescription.contains("Unknown theme"))
        #expect(error.localizedDescription.contains("custom-theme"))
    }

    @Test("Theme not available error")
    func testThemeNotAvailable() {
        // Arrange & Act
        let error = ValidationError.themeNotAvailable("solarized")

        // Assert
        #expect(error.localizedDescription.contains("not available"))
        #expect(error.localizedDescription.contains("solarized"))
    }

    @Test("Invalid URL error")
    func testInvalidURL() {
        // Arrange & Act
        let error = ValidationError.invalidURL("not a valid url")

        // Assert
        #expect(error.localizedDescription.contains("Invalid URL"))
    }

    @Test("Inaccessible path error")
    func testInaccessiblePath() {
        // Arrange & Act
        let error = ValidationError.inaccessiblePath("/protected/path")

        // Assert
        #expect(error.localizedDescription.contains("not accessible"))
        #expect(error.localizedDescription.contains("/protected/path"))
    }

    @Test("Error equality with simple cases")
    func testErrorEqualitySimple() {
        // Arrange - Simple 1-parameter cases
        let error1 = ValidationError.missingProperty("field")
        let error2 = ValidationError.missingProperty("field")
        let error3 = ValidationError.missingProperty("otherField")

        // Assert
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Error equality with same associated values")
    func testErrorEqualitySameValues() {
        // Arrange - valueOutOfRange with all 3 parameters same
        let error1 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-16")
        let error2 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-16")
        #expect(error1 == error2)

        // Arrange - invalidFormat with all 3 parameters same
        let error3 = ValidationError.invalidFormat(property: "url", value: "x", expectedFormat: "https://...")
        let error4 = ValidationError.invalidFormat(property: "url", value: "x", expectedFormat: "https://...")
        #expect(error3 == error4)

        // Arrange - conflictingProperties with all 3 parameters same
        let error5 = ValidationError.conflictingProperties(property1: "p1", property2: "p2", message: "msg")
        let error6 = ValidationError.conflictingProperties(property1: "p1", property2: "p2", message: "msg")
        #expect(error5 == error6)

        // Arrange - unknownEnumValue with all 3 parameters same (including Array)
        let error7 = ValidationError.unknownEnumValue(property: "theme", value: "invalid", validValues: ["a", "b"])
        let error8 = ValidationError.unknownEnumValue(property: "theme", value: "invalid", validValues: ["a", "b"])
        #expect(error7 == error8)
    }

    @Test("Error equality with different associated values")
    func testErrorEqualityDifferentValues() {
        // Arrange - Different property (first parameter)
        let error1 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-16")
        let error2 = ValidationError.valueOutOfRange(property: "fontSize", value: "20", validRange: "1-16")
        #expect(error1 != error2)

        // Arrange - Different value (second parameter)
        let error3 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-16")
        let error4 = ValidationError.valueOutOfRange(property: "tabWidth", value: "99", validRange: "1-16")
        #expect(error3 != error4)

        // Arrange - Different validRange (third parameter)
        let error5 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-16")
        let error6 = ValidationError.valueOutOfRange(property: "tabWidth", value: "20", validRange: "1-32")
        #expect(error5 != error6)

        // Arrange - invalidFormat with different parameters
        let error7 = ValidationError.invalidFormat(property: "url", value: "x", expectedFormat: "https://...")
        let error8 = ValidationError.invalidFormat(property: "email", value: "x", expectedFormat: "https://...")
        #expect(error7 != error8)

        // Arrange - conflictingProperties with different parameters
        let error9 = ValidationError.conflictingProperties(property1: "p1", property2: "p2", message: "msg1")
        let error10 = ValidationError.conflictingProperties(property1: "p1", property2: "p2", message: "msg2")
        #expect(error9 != error10)
    }

    @Test("Error equality with Array associated values")
    func testErrorEqualityArrayValues() {
        // Arrange - Same arrays (same values, same order)
        let error1 = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid",
            validValues: ["github", "github-dark"]
        )
        let error2 = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid",
            validValues: ["github", "github-dark"]
        )
        #expect(error1 == error2)

        // Arrange - Different arrays (different values)
        let error3 = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid",
            validValues: ["solarized", "monokai"]
        )
        #expect(error1 != error3)

        // Arrange - Different array order (should NOT be equal - Arrays are order-sensitive)
        let error4 = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid",
            validValues: ["github-dark", "github"]
        )
        #expect(error1 != error4)

        // Arrange - Different array length
        let error5 = ValidationError.unknownEnumValue(
            property: "theme",
            value: "invalid",
            validValues: ["github", "github-dark", "solarized"]
        )
        #expect(error1 != error5)
    }

    @Test("Error equality with different cases")
    func testErrorEqualityDifferentCases() {
        // Arrange - Different error cases with same String value
        let error1 = ValidationError.missingProperty("field")
        let error2 = ValidationError.invalidURL("field")
        let error3 = ValidationError.unknownTheme("field")
        let error4 = ValidationError.inaccessiblePath("field")

        // Assert - All should be different (different cases)
        #expect(error1 != error2)
        #expect(error1 != error3)
        #expect(error1 != error4)
        #expect(error2 != error3)
        #expect(error2 != error4)
        #expect(error3 != error4)
    }
}
