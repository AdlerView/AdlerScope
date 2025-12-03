//
//  BundleExtensionsTests.swift
//  AdlerScopeTests
//
//  Comprehensive tests for Bundle extensions
//

import Testing
import Foundation
@testable import AdlerScope

@Suite("Bundle Extensions Tests")
struct BundleExtensionsTests {

    @Test("appVersion returns non-empty string")
    func testAppVersion() {
        let version = Bundle.main.appVersion

        #expect(!version.isEmpty)
    }

    @Test("buildNumber returns non-empty string")
    func testBuildNumber() {
        let build = Bundle.main.buildNumber

        #expect(!build.isEmpty)
    }

    @Test("appVersion is accessible from Bundle.main")
    func testAppVersionFromMainBundle() {
        let version = Bundle.main.appVersion

        // Should be a non-empty string
        #expect(!version.isEmpty)
    }

    @Test("buildNumber is accessible from Bundle.main")
    func testBuildNumberFromMainBundle() {
        let build = Bundle.main.buildNumber

        // Should be a non-empty string
        #expect(!build.isEmpty)
    }
}

@Suite("Bundle Extensions Integration Tests")
struct BundleExtensionsIntegrationTests {

    @Test("appVersion and buildNumber are consistent across calls")
    func testConsistentValues() {
        let version1 = Bundle.main.appVersion
        let version2 = Bundle.main.appVersion

        let build1 = Bundle.main.buildNumber
        let build2 = Bundle.main.buildNumber

        #expect(version1 == version2)
        #expect(build1 == build2)
    }

    @Test("appVersion and buildNumber can be used together")
    func testVersionAndBuildTogether() {
        let version = Bundle.main.appVersion
        let build = Bundle.main.buildNumber

        // Both should be non-empty
        #expect(!version.isEmpty)
        #expect(!build.isEmpty)

        // They can be combined to form a version string
        let fullVersion = "\(version) (\(build))"
        #expect(!fullVersion.isEmpty)
    }
}
