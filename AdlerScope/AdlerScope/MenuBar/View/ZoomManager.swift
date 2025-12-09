//
//  ZoomManager.swift
//  AdlerScope
//
//  Manages editor zoom state and trackpad pinch-to-zoom gestures.
//  Uses text-level zoom (font scaling) for proper text reflow.
//

#if os(macOS)
import SwiftUI
import AppKit
import Observation

/// Manages zoom state and trackpad pinch-to-zoom gestures
@Observable
@MainActor
final class ZoomManager {
    // MARK: - Zoom State

    /// Current zoom level (1.0 = 100%)
    private(set) var currentZoomLevel: CGFloat = 1.0

    /// Visual zoom level during gesture (for smooth preview)
    private(set) var visualZoomLevel: CGFloat = 1.0

    /// Base zoom level when gesture began (for relative calculations)
    private var gestureBaseZoom: CGFloat = 1.0

    /// Accumulated magnification during current gesture
    private var gestureMagnification: CGFloat = 0.0

    /// Whether a gesture is currently in progress
    private(set) var isGestureInProgress: Bool = false

    // MARK: - Constraints

    /// Minimum zoom level (50%)
    let minimumZoomLevel: CGFloat = 0.5

    /// Maximum zoom level (300%)
    let maximumZoomLevel: CGFloat = 3.0

    /// Step factor for menu commands (25% per step)
    let zoomStepFactor: CGFloat = 1.25

    /// Menu step increment (10% per command)
    let menuStepIncrement: CGFloat = 0.1

    // MARK: - Base Font Size

    /// Base font size from editor settings (default 14pt)
    var basePointSize: CGFloat = 14.0

    // MARK: - Pending Updates

    /// Pending zoom level for NSTextView to apply
    /// Consumed by AppKitTextEditor.updateNSView()
    var pendingZoomUpdate: CGFloat?

    // MARK: - Gesture Handling

    /// Handles trackpad magnification gesture
    /// - Parameters:
    ///   - phase: Gesture phase (began, changed, ended, cancelled)
    ///   - magnification: Cumulative magnification value from gesture
    func handleMagnifyGesture(phase: NSEvent.Phase, magnification: CGFloat) {
        switch phase {
        case .began:
            // Store current zoom as base for this gesture
            gestureBaseZoom = currentZoomLevel
            gestureMagnification = 0.0
            isGestureInProgress = true

        case .changed:
            // Calculate new zoom based on gesture magnification
            // magnification is cumulative from gesture start
            let proposedZoom = gestureBaseZoom * (1.0 + magnification)
            let clampedZoom = min(max(proposedZoom, minimumZoomLevel), maximumZoomLevel)

            // Update visual zoom immediately for smooth feedback
            visualZoomLevel = clampedZoom
            currentZoomLevel = clampedZoom
            gestureMagnification = magnification

            // DO NOT set pendingZoomUpdate here - wait for gesture end

        case .ended, .cancelled:
            // Finalize zoom at current level
            isGestureInProgress = false
            finalizeZoom()

        default:
            break
        }
    }

    /// Handles smart magnify gesture (two-finger double-tap)
    /// Toggles between 100% and 150%
    func handleSmartMagnify() {
        let targetZoom: CGFloat = (currentZoomLevel < 1.25) ? 1.5 : 1.0
        setZoomLevel(targetZoom, animated: true)
    }

    // MARK: - Menu Commands

    /// Increases zoom level by menu step (10%)
    func zoomIn() {
        let newZoom = currentZoomLevel + menuStepIncrement
        setZoomLevel(newZoom, animated: false)
    }

    /// Decreases zoom level by menu step (10%)
    func zoomOut() {
        let newZoom = currentZoomLevel - menuStepIncrement
        setZoomLevel(newZoom, animated: false)
    }

    /// Resets zoom to 100%
    func resetZoom() {
        setZoomLevel(1.0, animated: false)
    }

    // MARK: - Zoom Level Management

    /// Sets zoom level with clamping
    /// - Parameters:
    ///   - level: Target zoom level
    ///   - animated: Whether to animate the transition (reserved for future use)
    func setZoomLevel(_ level: CGFloat, animated: Bool) {
        // Clamp to valid range
        let clampedLevel = min(max(level, minimumZoomLevel), maximumZoomLevel)

        // Only update if changed
        guard clampedLevel != currentZoomLevel else { return }

        currentZoomLevel = clampedLevel
        visualZoomLevel = clampedLevel
        pendingZoomUpdate = clampedLevel

        // Announce change to VoiceOver
        announceZoomChange()
    }

    /// Finalizes zoom after gesture completes
    private func finalizeZoom() {
        // Round to nearest 5% for cleaner final values
        let rounded = round(currentZoomLevel * 20.0) / 20.0  // Rounds to 0.05 increments
        let finalZoom = abs(rounded - currentZoomLevel) < 0.05 ? rounded : currentZoomLevel

        currentZoomLevel = finalZoom
        visualZoomLevel = finalZoom

        // Now apply the font scaling (expensive operation, only once at end)
        pendingZoomUpdate = finalZoom

        // Announce change to VoiceOver
        announceZoomChange()
    }

    // MARK: - Computed Properties

    /// Current zoom as percentage (e.g., 150 for 150%)
    var zoomPercentage: Int {
        Int(currentZoomLevel * 100)
    }

    /// Whether zoom is at minimum
    var isAtMinimum: Bool {
        currentZoomLevel <= minimumZoomLevel
    }

    /// Whether zoom is at maximum
    var isAtMaximum: Bool {
        currentZoomLevel >= maximumZoomLevel
    }

    // MARK: - Accessibility

    /// Announces zoom level change to VoiceOver
    private func announceZoomChange() {
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else { return }

        NSAccessibility.post(
            element: contentView,
            notification: .announcementRequested,
            userInfo: [
                .announcement: "Zoom level: \(zoomPercentage) percent",
                .priority: NSAccessibilityPriorityLevel.low.rawValue
            ]
        )
    }
}

#endif
