//
//  BundleExtensions.swift
//  AdlerScope
//
//  Shared utility extensions for Bundle
//

import Foundation

// MARK: - Bundle Extensions

extension Bundle {
    /// App version string from CFBundleShortVersionString
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Build number from CFBundleVersion
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
