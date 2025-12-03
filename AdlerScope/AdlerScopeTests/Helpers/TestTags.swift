//
//  TestTags.swift
//  AdlerScopeTests
//
//  Centralized test tags for organizing and filtering tests
//  Use with @Suite("...", .tags(...)) to categorize tests
//

import Testing

extension Tag {
    // MARK: - Mock-related tags

    /// Tests that use mock implementations
    @Tag static var mock: Self

    /// Tests that involve repository layer
    @Tag static var repository: Self

    // MARK: - Test type tags

    /// Unit tests (isolated, fast)
    @Tag static var unit: Self

    /// Integration tests (multiple components)
    @Tag static var integration: Self

    // MARK: - Architecture layer tags

    /// Tests for ViewModels
    @Tag static var viewModel: Self

    /// Tests for Use Cases
    @Tag static var useCase: Self

    /// Tests for Domain layer
    @Tag static var domain: Self
}
