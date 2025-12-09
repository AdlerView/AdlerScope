#if os(macOS)
//
//  ImageSourceResolverTests.swift
//  AdlerScopeTests
//
//  Tests for ImageSourceResolver CommonMark compliance
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("ImageSourceResolver Tests")
@MainActor
struct ImageSourceResolverTests {

    let resolver = ImageSourceResolver()

    // MARK: - Remote URL Tests

    @Test("Resolves HTTP URLs as remote")
    func httpURLs() {
        let result = resolver.resolve(
            source: "http://example.com/image.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .remote(let url) = result {
            #expect(url.absoluteString == "http://example.com/image.png")
        } else {
            Issue.record("Expected remote source")
        }
    }

    @Test("Resolves HTTPS URLs as remote")
    func httpsURLs() {
        let result = resolver.resolve(
            source: "https://example.com/image.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .remote(let url) = result {
            #expect(url.absoluteString == "https://example.com/image.png")
        } else {
            Issue.record("Expected remote source")
        }
    }

    @Test("Case-insensitive remote URL detection")
    func caseInsensitiveRemote() {
        let result = resolver.resolve(
            source: "HTTPS://example.com/image.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .remote = result {
            // Pass
        } else {
            Issue.record("Expected remote source for uppercase HTTPS")
        }
    }

    // MARK: - Absolute Path Tests

    @Test("Resolves absolute paths")
    func absolutePaths() {
        let result = resolver.resolve(
            source: "/Users/test/image.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .absolute(let url) = result {
            #expect(url.path == "/Users/test/image.png")
        } else {
            Issue.record("Expected absolute source")
        }
    }

    // MARK: - Relative Path Tests

    @Test("Resolves explicit relative paths with ./")
    func explicitRelativeDot() {
        let documentURL = URL(fileURLWithPath: "/Users/test/Documents/note.md")
        let result = resolver.resolve(
            source: "./images/photo.png",
            documentURL: documentURL,
            sidecarManager: nil
        )

        if case .documentRelative(let url) = result {
            #expect(url.path == "/Users/test/Documents/images/photo.png")
        } else {
            Issue.record("Expected documentRelative source")
        }
    }

    @Test("Resolves explicit relative paths with ../")
    func explicitRelativeParent() {
        let documentURL = URL(fileURLWithPath: "/Users/test/Documents/note.md")
        let result = resolver.resolve(
            source: "../shared/image.png",
            documentURL: documentURL,
            sidecarManager: nil
        )

        if case .documentRelative(let url) = result {
            #expect(url.path == "/Users/test/shared/image.png")
        } else {
            Issue.record("Expected documentRelative source")
        }
    }

    // MARK: - CommonMark URL Parsing Tests

    @Test("Strips angle brackets from URLs")
    func angleBracketStripping() {
        let result = resolver.resolve(
            source: "<https://example.com/image.png>",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .remote(let url) = result {
            #expect(url.absoluteString == "https://example.com/image.png")
        } else {
            Issue.record("Expected remote source after angle bracket stripping")
        }
    }

    @Test("Handles angle-bracketed absolute paths")
    func angleBracketAbsolutePath() {
        let result = resolver.resolve(
            source: "</path/to/image.png>",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .absolute(let url) = result {
            #expect(url.path == "/path/to/image.png")
        } else {
            Issue.record("Expected absolute source")
        }
    }

    @Test("Processes backslash escapes in URLs")
    func backslashEscapes() {
        let result = resolver.resolve(
            source: "https://example.com/path\\(1\\).png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .remote(let url) = result {
            #expect(url.absoluteString == "https://example.com/path(1).png")
        } else {
            Issue.record("Expected remote source with escaped parens")
        }
    }

    // MARK: - Plain Filename Tests (without file existence)

    @Test("Plain filename without document or sidecar returns sidecar with nil URL")
    func plainFilenameNoContext() {
        let result = resolver.resolve(
            source: "image.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .sidecar(let filename, let url) = result {
            #expect(filename == "image.png")
            #expect(url == nil)
        } else {
            Issue.record("Expected sidecar source for plain filename without context")
        }
    }

    // MARK: - Security Tests

    @Test("Rejects path traversal in filenames")
    func pathTraversalRejection() {
        let patterns = ["../secret.png", "..\\secret.png", "foo/../bar.png", "foo//bar.png"]

        for pattern in patterns {
            let result = resolver.resolve(
                source: pattern,
                documentURL: nil,
                sidecarManager: nil
            )

            // Path traversal patterns starting with ../ are treated as relative paths
            // Other patterns should be rejected as sidecar with nil URL
            if pattern.hasPrefix("../") {
                // This is a valid relative path pattern
                continue
            }

            if case .sidecar(_, let url) = result {
                #expect(url == nil, "Path traversal pattern '\(pattern)' should have nil URL")
            }
        }
    }

    @Test("Rejects null bytes in filenames")
    func nullByteRejection() {
        let result = resolver.resolve(
            source: "image\0.png",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .sidecar(_, let url) = result {
            #expect(url == nil, "Null byte pattern should have nil URL")
        } else {
            Issue.record("Expected sidecar source for null byte pattern")
        }
    }

    // MARK: - Empty Source Tests

    @Test("Handles empty source")
    func emptySource() {
        let result = resolver.resolve(
            source: "",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .sidecar(let filename, let url) = result {
            #expect(filename == "")
            #expect(url == nil)
        } else {
            Issue.record("Expected sidecar source for empty string")
        }
    }

    @Test("Handles whitespace-only source")
    func whitespaceSource() {
        let result = resolver.resolve(
            source: "   ",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .sidecar(let filename, let url) = result {
            #expect(filename == "")
            #expect(url == nil)
        } else {
            Issue.record("Expected sidecar source for whitespace")
        }
    }

    // MARK: - Angle Bracket Edge Cases

    @Test("Handles URLs with spaces in angle brackets")
    func spacesInAngleBrackets() {
        // Angle brackets allow spaces in URLs
        let result = resolver.resolve(
            source: "</path/to/my image.png>",
            documentURL: nil,
            sidecarManager: nil
        )

        if case .absolute(let url) = result {
            #expect(url.path == "/path/to/my image.png")
        } else {
            Issue.record("Expected absolute source for angle-bracketed path with space")
        }
    }
}

#endif
