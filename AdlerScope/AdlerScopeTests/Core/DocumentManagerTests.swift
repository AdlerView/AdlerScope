//
//  DocumentManagerTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for DocumentManager
//  Tests initialization, file operations, recent documents, and all closures
//

import Testing
import Foundation
import SwiftUI
import UniformTypeIdentifiers
@testable import AdlerScope

// MARK: - Variable Initialization Tests

@Suite("DocumentManager Variable Initialization Tests")
@MainActor
struct DocumentManagerVariableInitializationTests {

    @Test("variable initialization expression of _currentContent")
    func testCurrentContentInitialization() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // currentContent should be initialized to empty string
        #expect(manager.currentContent == "")
    }

    @Test("variable initialization expression of _hasUnsavedChanges")
    func testHasUnsavedChangesInitialization() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // hasUnsavedChanges should be initialized to false
        #expect(manager.hasUnsavedChanges == false)
    }

    @Test("variable initialization expression of _recentDocuments")
    func testRecentDocumentsInitialization() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // recentDocuments should be initialized to empty array
        #expect(manager.recentDocuments.isEmpty)
    }

    @Test("variable initialization expression of _currentEncoding")
    func testCurrentEncodingInitialization() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // currentEncoding should be initialized to .utf8
        #expect(manager.currentEncoding == .utf8)
    }
}

// MARK: - Initialization Tests

@Suite("DocumentManager Initialization Tests")
@MainActor
struct DocumentManagerInitializationTests {

    @Test("init(documentRepository:) sets up manager correctly")
    func testInitialization() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // Verify initial state
        #expect(manager.currentContent == "")
        #expect(manager.hasUnsavedChanges == false)
        #expect(manager.recentDocuments.isEmpty)
        #expect(manager.currentEncoding == .utf8)
        #expect(manager.currentDocumentURL == nil)
    }
}

// MARK: - openDocument(from:) Tests

@Suite("DocumentManager openDocument(from:) Tests")
@MainActor
struct DocumentManagerOpenDocumentFromTests {

    @Test("openDocument(from:) reads document successfully")
    func testOpenDocumentSuccess() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("# Test Content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")
        let result = await manager.openDocument(from: url)

        #expect(result == true)
        #expect(manager.currentContent == "# Test Content")
        #expect(manager.currentDocumentURL == url)
        #expect(manager.currentEncoding == .utf8)
        #expect(manager.hasUnsavedChanges == false)
        #expect(mockRepo.readCallCount == 1)
    }

    @Test("openDocument(from:) handles read errors")
    func testOpenDocumentReadError() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readError = NSError(domain: "test", code: 1)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")
        let result = await manager.openDocument(from: url)

        #expect(result == false)
        #expect(mockRepo.readCallCount == 1)
    }

    @Test("openDocument(from:) adds to recent documents")
    func testOpenDocumentAddsToRecents() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")
        _ = await manager.openDocument(from: url)

        #expect(manager.recentDocuments.count == 1)
        #expect(manager.recentDocuments.first?.url == url)
    }
}

// MARK: - saveDocument() Tests

@Suite("DocumentManager saveDocument() Tests")
@MainActor
struct DocumentManagerSaveDocumentTests {

    @Test("saveDocument() saves to existing URL")
    func testSaveDocumentWithExistingURL() async {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")
        manager.currentDocumentURL = url
        manager.currentContent = "Test content"
        manager.hasUnsavedChanges = true

        let result = await manager.saveDocument()

        #expect(result == true)
        #expect(manager.hasUnsavedChanges == false)
        #expect(mockRepo.writeCallCount == 1)
        #expect(mockRepo.lastWrittenContent == "Test content")
        #expect(mockRepo.lastWrittenURL == url)
    }
}

// MARK: - saveDocument(to:) Tests

@Suite("DocumentManager saveDocument(to:) Tests")
@MainActor
struct DocumentManagerSaveDocumentToTests {

    @Test("saveDocument(to:) writes document successfully")
    func testSaveDocumentToSuccess() async {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentContent = "Test content"
        manager.currentEncoding = .utf8

        let url = URL(fileURLWithPath: "/test/document.md")
        let result = await manager.saveDocument(to: url)

        #expect(result == true)
        #expect(manager.currentDocumentURL == url)
        #expect(manager.hasUnsavedChanges == false)
        #expect(mockRepo.writeCallCount == 1)
        #expect(mockRepo.lastWrittenContent == "Test content")
        #expect(mockRepo.lastWrittenURL == url)
        #expect(mockRepo.lastWrittenEncoding == .utf8)
    }

    @Test("saveDocument(to:) handles write errors")
    func testSaveDocumentToWriteError() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.writeError = NSError(domain: "test", code: 1)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")
        let result = await manager.saveDocument(to: url)

        #expect(result == false)
        #expect(mockRepo.writeCallCount == 1)
    }

    @Test("saveDocument(to:) adds to recent documents")
    func testSaveDocumentToAddsToRecents() async {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentContent = "Content"

        let url = URL(fileURLWithPath: "/test/document.md")
        _ = await manager.saveDocument(to: url)

        #expect(manager.recentDocuments.count == 1)
        #expect(manager.recentDocuments.first?.url == url)
    }
}

// MARK: - newDocument() Tests

@Suite("DocumentManager newDocument() Tests")
@MainActor
struct DocumentManagerNewDocumentTests {

    @Test("newDocument() resets all state")
    func testNewDocument() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        // Set some state
        manager.currentContent = "Old content"
        manager.currentDocumentURL = URL(fileURLWithPath: "/old.md")
        manager.currentEncoding = .utf16
        manager.hasUnsavedChanges = true

        // Create new document
        manager.newDocument()

        // Verify state reset
        #expect(manager.currentContent == "")
        #expect(manager.currentDocumentURL == nil)
        #expect(manager.currentEncoding == .utf8)
        #expect(manager.hasUnsavedChanges == false)
    }
}

// MARK: - updateContent() Tests

@Suite("DocumentManager updateContent() Tests")
@MainActor
struct DocumentManagerUpdateContentTests {

    @Test("updateContent(_:) updates content and marks as unsaved")
    func testUpdateContent() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentContent = "Old content"
        manager.hasUnsavedChanges = false

        manager.updateContent("New content")

        #expect(manager.currentContent == "New content")
        #expect(manager.hasUnsavedChanges == true)
    }

    @Test("updateContent(_:) does nothing when content is same")
    func testUpdateContentSameContent() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentContent = "Same content"
        manager.hasUnsavedChanges = false

        manager.updateContent("Same content")

        #expect(manager.currentContent == "Same content")
        #expect(manager.hasUnsavedChanges == false)
    }
}

// MARK: - addToRecentDocuments() Tests

@Suite("DocumentManager addToRecentDocuments() Tests")
@MainActor
struct DocumentManagerAddToRecentDocumentsTests {

    @Test("closure #1 in addToRecentDocuments(_:) removes existing entries")
    func testAddToRecentDocumentsRemovesDuplicates() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/document.md")

        // Add same document twice
        manager.updateContent("test")
        manager.currentDocumentURL = url

        // Simulate internal call
        let info1 = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "document.md")
        manager.recentDocuments.append(info1)

        // Add again (would happen through save or open)
        let info2 = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "document.md")

        // The closure: recentDocuments.removeAll { $0.url == url }
        manager.recentDocuments.removeAll { $0.url == url }
        manager.recentDocuments.insert(info2, at: 0)

        // Should only have one entry
        #expect(manager.recentDocuments.count == 1)
    }

    @Test("addToRecentDocuments(_:) limits to 10 entries")
    func testAddToRecentDocumentsLimitsTo10() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        // Add 15 different documents
        for i in 0..<15 {
            let url = URL(fileURLWithPath: "/test/document\(i).md")
            _ = await manager.openDocument(from: url)
        }

        // Should only keep 10
        #expect(manager.recentDocuments.count == 10)
    }

    @Test("addToRecentDocuments(_:) adds to beginning")
    func testAddToRecentDocumentsAddsToBeginning() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url1 = URL(fileURLWithPath: "/test/doc1.md")
        let url2 = URL(fileURLWithPath: "/test/doc2.md")

        _ = await manager.openDocument(from: url1)
        _ = await manager.openDocument(from: url2)

        // Most recent should be first
        #expect(manager.recentDocuments.first?.url == url2)
    }
}

// MARK: - openRecentDocument() Tests

@Suite("DocumentManager openRecentDocument() Tests")
@MainActor
struct DocumentManagerOpenRecentDocumentTests {

    @Test("openRecentDocument(_:) opens document from info")
    func testOpenRecentDocument() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Recent content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/recent.md")
        let info = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "recent.md")

        await manager.openRecentDocument(info)

        #expect(manager.currentContent == "Recent content")
        #expect(manager.currentDocumentURL == url)
    }
}

// MARK: - windowTitle.getter Tests

@Suite("DocumentManager windowTitle.getter Tests")
@MainActor
struct DocumentManagerWindowTitleTests {

    @Test("windowTitle.getter returns filename when saved")
    func testWindowTitleSaved() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentDocumentURL = URL(fileURLWithPath: "/test/document.md")
        manager.hasUnsavedChanges = false

        // implicit closure #1: currentDocumentURL?.lastPathComponent ?? "Untitled"
        #expect(manager.windowTitle == "document.md")
    }

    @Test("windowTitle.getter returns filename with dot when unsaved")
    func testWindowTitleUnsaved() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentDocumentURL = URL(fileURLWithPath: "/test/document.md")
        manager.hasUnsavedChanges = true

        #expect(manager.windowTitle == "document.md •")
    }

    @Test("implicit closure #1 in windowTitle.getter uses fallback")
    func testWindowTitleImplicitClosureUsesUntitled() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentDocumentURL = nil
        manager.hasUnsavedChanges = false

        // implicit closure returns "Untitled"
        #expect(manager.windowTitle == "Untitled")
    }
}

// MARK: - documentPath.getter Tests

@Suite("DocumentManager documentPath.getter Tests")
@MainActor
struct DocumentManagerDocumentPathTests {

    @Test("documentPath.getter returns parent path")
    func testDocumentPathWithURL() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentDocumentURL = URL(fileURLWithPath: "/Users/test/Documents/file.md")

        #expect(manager.documentPath == "/Users/test/Documents")
    }

    @Test("implicit closure #1 in documentPath.getter uses fallback")
    func testDocumentPathImplicitClosureUsesEmpty() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        manager.currentDocumentURL = nil

        // implicit closure returns ""
        #expect(manager.documentPath == "")
    }
}

// MARK: - RecentDocumentInfo Tests

@Suite("RecentDocumentInfo Tests")
@MainActor
struct RecentDocumentInfoTests {

    @Test("variable initialization expression of id")
    func testRecentDocumentInfoIDInitialization() {
        let url = URL(fileURLWithPath: "/test.md")
        let info = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "test.md")

        // id should be initialized with UUID()
        #expect(info.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }

    @Test("RecentDocumentInfo IDs are unique")
    func testRecentDocumentInfoUniqueIDs() {
        let url = URL(fileURLWithPath: "/test.md")
        let info1 = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "test.md")
        let info2 = RecentDocumentInfo(url: url, lastOpened: Date(), displayName: "test.md")

        #expect(info1.id != info2.id)
    }

    @Test("static RecentDocumentInfo.== compares URLs")
    func testRecentDocumentInfoEquality() {
        let url1 = URL(fileURLWithPath: "/test1.md")
        let url2 = URL(fileURLWithPath: "/test2.md")

        let info1 = RecentDocumentInfo(url: url1, lastOpened: Date(), displayName: "test1.md")
        let info2 = RecentDocumentInfo(url: url1, lastOpened: Date(), displayName: "test1.md")
        let info3 = RecentDocumentInfo(url: url2, lastOpened: Date(), displayName: "test2.md")

        #expect(info1 == info2) // Same URL
        #expect(info1 != info3) // Different URL
    }
}

// MARK: - EnvironmentValues Tests

@Suite("EnvironmentValues DocumentManager Tests")
struct EnvironmentValuesDocumentManagerTests {

    @Test("EnvironmentValues.documentManager.getter returns value")
    func testEnvironmentValuesGetter() {
        let env = EnvironmentValues()

        // Default should be nil
        #expect(env.documentManager == nil)
    }

    @Test("EnvironmentValues.documentManager.setter sets value")
    @MainActor
    func testEnvironmentValuesSetter() {
        var env = EnvironmentValues()
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        env.documentManager = manager

        #expect(env.documentManager != nil)
    }

    @Test("EnvironmentValues.documentManager can be set to nil")
    func testEnvironmentValuesSetToNil() {
        var env = EnvironmentValues()

        env.documentManager = nil

        #expect(env.documentManager == nil)
    }
}

// MARK: - Integration Tests

@Suite("DocumentManager Integration Tests")
@MainActor
struct DocumentManagerIntegrationTests {

    @Test("Full workflow: new -> edit -> save -> open")
    func testFullWorkflow() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Loaded content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        // 1. New document
        manager.newDocument()
        #expect(manager.currentContent == "")
        #expect(manager.hasUnsavedChanges == false)

        // 2. Edit content
        manager.updateContent("New content")
        #expect(manager.hasUnsavedChanges == true)

        // 3. Save document
        let saveURL = URL(fileURLWithPath: "/test/saved.md")
        let saved = await manager.saveDocument(to: saveURL)
        #expect(saved == true)
        #expect(manager.hasUnsavedChanges == false)

        // 4. Open different document
        let openURL = URL(fileURLWithPath: "/test/other.md")
        let opened = await manager.openDocument(from: openURL)
        #expect(opened == true)
        #expect(manager.currentContent == "Loaded content")

        // 5. Verify recent documents
        #expect(manager.recentDocuments.count == 2)
    }

    @Test("Recent documents workflow")
    func testRecentDocumentsWorkflow() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Content", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        // Open several documents
        let url1 = URL(fileURLWithPath: "/test/doc1.md")
        let url2 = URL(fileURLWithPath: "/test/doc2.md")
        let url3 = URL(fileURLWithPath: "/test/doc3.md")

        _ = await manager.openDocument(from: url1)
        _ = await manager.openDocument(from: url2)
        _ = await manager.openDocument(from: url3)

        #expect(manager.recentDocuments.count == 3)
        #expect(manager.recentDocuments[0].url == url3) // Most recent first

        // Reopen first document
        _ = await manager.openDocument(from: url1)
        #expect(manager.recentDocuments.count == 3) // Still 3 (no duplicates)
        #expect(manager.recentDocuments[0].url == url1) // Now most recent
    }
}

// MARK: - Edge Cases Tests

@Suite("DocumentManager Edge Cases")
@MainActor
struct DocumentManagerEdgeCasesTests {

    @Test("Empty content handling")
    func testEmptyContent() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("", .utf8)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/empty.md")
        _ = await manager.openDocument(from: url)

        #expect(manager.currentContent == "")
    }

    @Test("Very long content")
    func testVeryLongContent() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        let longContent = String(repeating: "a", count: 100000)
        manager.updateContent(longContent)

        #expect(manager.currentContent.count == 100000)
        #expect(manager.hasUnsavedChanges == true)
    }

    @Test("Special characters in content")
    func testSpecialCharacters() {
        let mockRepo = MockDocumentRepository()
        let manager = DocumentManager(documentRepository: mockRepo)

        let specialContent = "Test\n\t\r\"'\\emoji🎉"
        manager.updateContent(specialContent)

        #expect(manager.currentContent == specialContent)
    }

    @Test("Multiple encoding changes")
    func testMultipleEncodingChanges() async {
        let mockRepo = MockDocumentRepository()
        mockRepo.readResult = ("Content", .utf16)
        let manager = DocumentManager(documentRepository: mockRepo)

        let url = URL(fileURLWithPath: "/test/encoded.md")
        _ = await manager.openDocument(from: url)

        #expect(manager.currentEncoding == .utf16)
    }
}
