//
//  AccessibilityHelpers.swift
//  AdlerScope
//
//  Provides accessibility utilities for checking system settings.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Accessibility helper utilities
enum AccessibilityHelpers {
    /// Whether the Reduce Motion accessibility setting is enabled
    ///
    /// When true, animations should be disabled or simplified to reduce
    /// motion sickness and discomfort for users with vestibular disorders.
    static var shouldReduceMotion: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return UIAccessibility.isReduceMotionEnabled
        #endif
    }
}
