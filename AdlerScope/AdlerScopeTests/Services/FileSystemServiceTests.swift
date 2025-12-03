//
//  FileSystemServiceTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for FileSystemService functionality
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("FileSystemService Tests")
@MainActor
struct FileSystemServiceTests {

    @Test("Shared instance is singleton")
    func testSharedInstanceIsSingleton() {
        let instance1 = FileSystemService.shared
        let instance2 = FileSystemService.shared

        // Both should refer to the same instance
        #expect(instance1 === instance2)
    }

    @Test("validateMarkdownFile returns true for .md extension")
    func testValidateMarkdownFileMD() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.md")

        // Create the file
        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile returns true for .markdown extension")
    func testValidateMarkdownFileMarkdown() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.markdown")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile returns true for .txt extension")
    func testValidateMarkdownFileTxt() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile returns false for non-markdown extension")
    func testValidateMarkdownFileInvalid() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == false)
    }

    @Test("validateMarkdownFile returns false for non-existent file")
    func testValidateMarkdownFileNonExistent() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.md")

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == false)
    }

    @Test("validateMarkdownFile supports all markdown extensions")
    func testValidateMarkdownFileAllExtensions() {
        let service = FileSystemService.shared
        let extensions = ["md", "markdown", "txt", "rmd", "qmd"]

        for ext in extensions {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.\(ext)")
            try? "test".write(to: tempURL, atomically: true, encoding: .utf8)

            let isValid = service.validateMarkdownFile(at: tempURL)
            #expect(isValid == true)

            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    @Test("validateMarkdownFile is case insensitive")
    func testValidateMarkdownFileCaseInsensitive() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.MD")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }
}

@Suite("FileMetadata Tests")
struct FileMetadataTests {

    @Test("FileMetadata initialization")
    func testFileMetadataInit() {
        let now = Date()
        let metadata = FileMetadata(
            fileSize: 1024,
            modifiedDate: now,
            createdDate: now
        )

        #expect(metadata.fileSize == 1024)
        #expect(metadata.modifiedDate == now)
        #expect(metadata.createdDate == now)
    }

    @Test("fileSizeFormatted returns formatted string")
    func testFileSizeFormatted() {
        let metadata = FileMetadata(
            fileSize: 1024,
            modifiedDate: Date(),
            createdDate: Date()
        )

        let formatted = metadata.fileSizeFormatted

        #expect(!formatted.isEmpty)
        #expect(formatted.contains("KB") || formatted.contains("bytes"))
    }

    @Test("fileSizeFormatted for various sizes")
    func testFileSizeFormattedVariousSizes() {
        let sizes: [Int64] = [0, 100, 1024, 1024 * 1024, 1024 * 1024 * 1024]

        for size in sizes {
            let metadata = FileMetadata(
                fileSize: size,
                modifiedDate: Date(),
                createdDate: Date()
            )

            let formatted = metadata.fileSizeFormatted
            #expect(!formatted.isEmpty)
        }
    }

    @Test("FileMetadata with zero size")
    func testFileMetadataZeroSize() {
        let metadata = FileMetadata(
            fileSize: 0,
            modifiedDate: Date(),
            createdDate: Date()
        )

        #expect(metadata.fileSize == 0)
        #expect(!metadata.fileSizeFormatted.isEmpty)
    }

    @Test("FileMetadata with large size")
    func testFileMetadataLargeSize() {
        let largeSize: Int64 = 1024 * 1024 * 1024 * 10 // 10 GB
        let metadata = FileMetadata(
            fileSize: largeSize,
            modifiedDate: Date(),
            createdDate: Date()
        )

        #expect(metadata.fileSize == largeSize)
        #expect(!metadata.fileSizeFormatted.isEmpty)
    }

    @Test("FileMetadata dates are preserved")
    func testFileMetadataDatesPreserved() {
        let modifiedDate = Date(timeIntervalSince1970: 1000000)
        let createdDate = Date(timeIntervalSince1970: 900000)

        let metadata = FileMetadata(
            fileSize: 100,
            modifiedDate: modifiedDate,
            createdDate: createdDate
        )

        #expect(metadata.modifiedDate == modifiedDate)
        #expect(metadata.createdDate == createdDate)
    }
}

@Suite("FileSystemService Edge Cases")
@MainActor
struct FileSystemServiceEdgeCaseTests {

    @Test("validateMarkdownFile with special characters in path")
    func testValidateMarkdownFileSpecialPath() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test file with spaces.md")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile with unicode filename")
    func testValidateMarkdownFileUnicode() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("测试文件.md")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile with multiple dots in filename")
    func testValidateMarkdownFileMultipleDots() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("file.name.with.dots.md")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        #expect(isValid == true)
    }

    @Test("validateMarkdownFile with empty filename")
    func testValidateMarkdownFileEmptyFilename() {
        let service = FileSystemService.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(".md")

        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let isValid = service.validateMarkdownFile(at: tempURL)

        // A file named ".md" is a hidden file with no extension, so it's not valid
        #expect(isValid == false)
    }
}
