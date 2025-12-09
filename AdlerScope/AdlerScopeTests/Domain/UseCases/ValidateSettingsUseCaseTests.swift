//
//  ValidateSettingsUseCaseTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for ValidateSettingsUseCase functionality
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("ValidateSettingsUseCase Tests")
@MainActor
struct ValidateSettingsUseCaseTests {

    @Test("Execute returns validated settings")
    func testExecuteReturnsValidatedSettings() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )

        let validated = await useCase.execute(settings)

        #expect(validated.editor?.openInlineLink == true)
        #expect(validated.editor?.debug == false)
    }

    @Test("Execute preserves valid settings")
    func testExecutePreservesValidSettings() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: false,
                debug: true
            )
        )

        let validated = await useCase.execute(settings)

        #expect(validated.editor?.openInlineLink == false)
        #expect(validated.editor?.debug == true)
    }

    @Test("Validate returns empty array for valid settings")
    func testValidateReturnsEmptyForValidSettings() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let issues = await useCase.validate(settings)

        #expect(issues.isEmpty)
    }

    @Test("isValid returns true for valid settings")
    func testIsValidReturnsTrue() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )

        let isValid = await useCase.isValid(settings)

        #expect(isValid == true)
    }

    @Test("isValid filters only error severity issues")
    func testIsValidFiltersErrors() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let isValid = await useCase.isValid(settings)

        // Should be valid since no errors are returned
        #expect(isValid == true)
    }
}

@Suite("ValidateSettingsUseCase Edge Cases")
@MainActor
struct ValidateSettingsUseCaseEdgeCaseTests {

    @Test("Execute with default settings")
    func testExecuteWithDefaultSettings() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let validated = await useCase.execute(settings)

        #expect(validated.id == AppSettings.singletonID)
    }

    @Test("Execute preserves settings ID")
    func testExecutePreservesID() async {
        let useCase = ValidateSettingsUseCase()
        let customID = UUID()
        let settings = AppSettings(
            id: customID,
            editor: EditorSettings.default
        )

        let validated = await useCase.execute(settings)

        #expect(validated.id == customID)
    }

    @Test("Multiple validate calls are consistent")
    func testMultipleValidateCalls() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let issues1 = await useCase.validate(settings)
        let issues2 = await useCase.validate(settings)

        #expect(issues1.count == issues2.count)
    }

    @Test("Multiple isValid calls are consistent")
    func testMultipleIsValidCalls() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings.default

        let isValid1 = await useCase.isValid(settings)
        let isValid2 = await useCase.isValid(settings)

        #expect(isValid1 == isValid2)
    }
}

@Suite("ValidationIssue Tests")
@MainActor
struct ValidationIssueTests {

    @Test("ValidationIssue initialization")
    func testValidationIssueInit() {
        let issue = ValidationIssue(
            severity: .error,
            property: "fontSize",
            message: "Font size is invalid"
        )

        #expect(issue.severity == .error)
        #expect(issue.property == "fontSize")
        #expect(issue.message == "Font size is invalid")
    }

    @Test("ValidationIssue severity levels")
    func testValidationIssueSeverityLevels() {
        let error = ValidationIssue(severity: .error, property: "test", message: "test")
        let warning = ValidationIssue(severity: .warning, property: "test", message: "test")
        let info = ValidationIssue(severity: .info, property: "test", message: "test")

        #expect(error.severity == .error)
        #expect(warning.severity == .warning)
        #expect(info.severity == .info)
    }

    @Test("ValidationIssue Severity raw values")
    func testSeverityRawValues() {
        #expect(ValidationIssue.Severity.error.rawValue == "ERROR")
        #expect(ValidationIssue.Severity.warning.rawValue == "WARNING")
        #expect(ValidationIssue.Severity.info.rawValue == "INFO")
    }

    @Test("ValidationIssue is Sendable")
    func testValidationIssueIsSendable() {
        let issue = ValidationIssue(severity: .error, property: "test", message: "test")

        // Should compile without error as ValidationIssue conforms to Sendable
        let _: any Sendable = issue
        #expect(true)
    }

    @Test("ValidationIssue Severity is Sendable")
    func testValidationIssueSeverityIsSendable() {
        let severity = ValidationIssue.Severity.error

        // Should compile without error as Severity conforms to Sendable
        let _: any Sendable = severity
        #expect(true)
    }
}

@Suite("ValidateSettingsUseCase Integration Tests")
@MainActor
struct ValidateSettingsUseCaseIntegrationTests {

    @Test("Execute, validate, and isValid are consistent")
    func testMethodsAreConsistent() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: false,
                debug: true
            )
        )

        let validated = await useCase.execute(settings)
        let issues = await useCase.validate(settings)
        let isValid = await useCase.isValid(settings)

        // If settings are valid, should have no error issues
        if isValid {
            let errorIssues = issues.filter { $0.severity == .error }
            #expect(errorIssues.isEmpty)
        }

        // Validated settings should also be valid
        let validatedIsValid = await useCase.isValid(validated)
        #expect(validatedIsValid == true)
    }

    @Test("Validating already validated settings")
    func testValidatingValidatedSettings() async {
        let useCase = ValidateSettingsUseCase()
        let settings = AppSettings(
            editor: EditorSettings(
                openInlineLink: true,
                debug: false
            )
        )

        let validated1 = await useCase.execute(settings)
        let validated2 = await useCase.execute(validated1)

        // Both should produce the same validated result
        #expect(validated1.editor?.openInlineLink == validated2.editor?.openInlineLink)
        #expect(validated1.editor?.debug == validated2.editor?.debug)
    }
}
