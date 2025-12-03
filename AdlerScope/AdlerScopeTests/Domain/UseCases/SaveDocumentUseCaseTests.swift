//
//  SaveDocumentUseCaseTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for SaveDocumentUseCase
//

import Testing
import Foundation
import UniformTypeIdentifiers
@testable import AdlerScope

@Suite("SaveDocumentUseCase Tests")
@MainActor
struct SaveDocumentUseCaseTests {

    // MARK: - Tests

    @Test("Save document writes content to file")
    func testSaveDocumentSuccess() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withSuccessfulOperations()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: false)
        let content = "# Test Document\n\nContent here."
        let url = URL(fileURLWithPath: "/tmp/test.md")

        // Act
        try await useCase.execute(content: content, to: url)

        // Assert
        #expect(mockRepo.writeCallCount == 1)
        #expect(mockRepo.lastWrittenContent == content)
        #expect(mockRepo.lastWrittenURL == url)
    }

    @Test("Save document with backup enabled creates backup")
    func testSaveDocumentWithBackup() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withExistingFile()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: true)
        let content = "# Test Document"
        let url = URL(fileURLWithPath: "/tmp/test.md")

        // Act
        try await useCase.execute(content: content, to: url)

        // Assert
        #expect(mockRepo.fileExistsCallCount == 1)
        #expect(mockRepo.createBackupCallCount == 1)
        #expect(mockRepo.writeCallCount == 1)
    }

    @Test("Save document without backup skips backup creation")
    func testSaveDocumentWithoutBackup() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withExistingFile()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: false)
        let content = "# Test Document"
        let url = URL(fileURLWithPath: "/tmp/test.md")

        // Act
        try await useCase.execute(content: content, to: url)

        // Assert
        #expect(mockRepo.createBackupCallCount == 0)
        #expect(mockRepo.writeCallCount == 1)
    }

    @Test("Save document throws error when write fails")
    func testSaveDocumentWriteFailure() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withWriteError()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: false)
        let content = "# Test Document"
        let url = URL(fileURLWithPath: "/tmp/test.md")

        // Act & Assert
        await #expect(throws: DocumentError.self) {
            try await useCase.execute(content: content, to: url)
        }
    }

    @Test("Save continues when backup fails but write succeeds")
    func testSaveDocumentContinuesAfterBackupFailure() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withBackupError()
        mockRepo.fileExistsResult = true  // File exists so backup is attempted
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: true)
        let content = "# Test Document"
        let url = URL(fileURLWithPath: "/tmp/test.md")

        // Act - should NOT throw (write succeeds despite backup failure)
        try await useCase.execute(content: content, to: url)

        // Assert - backup was attempted but failed, write succeeded
        #expect(mockRepo.createBackupCallCount == 1)
        #expect(mockRepo.writeCallCount == 1)
        #expect(mockRepo.lastWrittenContent == content)
    }

    @Test("Can write to URL returns true for writable directory")
    func testCanWriteToURL() async {
        // Arrange
        let mockRepo = MockDocumentRepository()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: false)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.md")

        // Act
        let canWrite = await useCase.canWrite(to: url)

        // Assert
        #expect(canWrite == true)
    }

    @Test("Save document for new file skips backup")
    func testSaveNewFileSkipsBackup() async throws {
        // Arrange
        let mockRepo = MockDocumentRepository.withNewFile()
        let useCase = SaveDocumentUseCase(documentRepository: mockRepo, createBackups: true)
        let content = "# New Document"
        let url = URL(fileURLWithPath: "/tmp/new.md")

        // Act
        try await useCase.execute(content: content, to: url)

        // Assert
        #expect(mockRepo.createBackupCallCount == 0)
        #expect(mockRepo.writeCallCount == 1)
    }
}
