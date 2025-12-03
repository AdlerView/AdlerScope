//
//  ColorTests.swift
//  AdlerScopeTests
//
//  Tests for Color extensions
//

import Testing
import SwiftUI
@testable import AdlerScope

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Suite("Color Tests")
struct ColorTests {

    // MARK: - Test Helpers

    /// Helper to convert SwiftUI Color to CGColor for component inspection
    private func cgColor(from color: Color) -> CGColor {
        #if os(macOS)
        return NSColor(color).cgColor
        #else
        return UIColor(color).cgColor
        #endif
    }

    /// Helper to get RGBA components from CGColor
    private func components(from cgColor: CGColor) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let red = Double(components[0])
        let green = Double(components[1])
        let blue = Double(components[2])
        let alpha = components.count >= 4 ? Double(components[3]) : Double(cgColor.alpha)

        return (red: red, green: green, blue: blue, alpha: alpha)
    }

    // MARK: - Hex Parsing Tests

    @Test("Hex color parsing with # prefix produces correct red")
    func testHexColorWithPrefix() {
        // Arrange & Act
        let color = Color(hex: "#FF0000")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert
        #expect(rgba.red == 1.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 0.0)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing without # prefix produces correct blue")
    func testHexColorWithoutPrefix() {
        // Arrange & Act
        let color = Color(hex: "0000FF")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert
        #expect(rgba.red == 0.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 1.0)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing short form RGB expands correctly")
    func testHexColorShortFormRGB() {
        // Arrange & Act - #F00 should expand to #FF0000
        let color = Color(hex: "#F00")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert - Should be red (1.0, 0.0, 0.0)
        #expect(rgba.red == 1.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 0.0)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing short form RGBA expands correctly")
    func testHexColorShortFormRGBA() {
        // Arrange & Act - #F00F should expand to #FF0000FF (red with full alpha)
        let color = Color(hex: "#F00F")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert
        #expect(rgba.red == 1.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 0.0)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing with alpha channel extracts correctly")
    func testHexColorWithAlpha() {
        // Arrange & Act - #FF000080: red with alpha = 0x80 = 128/255 ≈ 0.502
        let color = Color(hex: "#FF000080")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert
        #expect(rgba.red == 1.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 0.0)
        #expect(abs(rgba.alpha - 0.502) < 0.01)  // Allow small rounding error
    }

    @Test("Hex color parsing handles green correctly")
    func testHexColorGreen() {
        // Arrange & Act
        let color = Color(hex: "#00FF00")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert
        #expect(rgba.red == 0.0)
        #expect(rgba.green == 1.0)
        #expect(rgba.blue == 0.0)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing handles mixed RGB values")
    func testHexColorMixedRGB() {
        // Arrange & Act - #FF5733 (orange-ish)
        let color = Color(hex: "#FF5733")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert - 0xFF = 255/255 = 1.0, 0x57 = 87/255 ≈ 0.341, 0x33 = 51/255 = 0.2
        #expect(abs(rgba.red - 1.0) < 0.01)
        #expect(abs(rgba.green - 0.341) < 0.01)
        #expect(abs(rgba.blue - 0.2) < 0.01)
        #expect(rgba.alpha == 1.0)
    }

    @Test("Hex color parsing with whitespace trims correctly")
    func testHexColorWithWhitespace() {
        // Arrange & Act
        let color = Color(hex: "  #0000FF  ")!
        let cgColor = cgColor(from: color)
        let rgba = components(from: cgColor)!

        // Assert - Should be blue
        #expect(rgba.red == 0.0)
        #expect(rgba.green == 0.0)
        #expect(rgba.blue == 1.0)
    }

    // MARK: - Error Handling Tests

    @Test("Hex color parsing invalid format returns nil")
    func testHexColorInvalidFormat() {
        // Arrange & Act
        let color = Color(hex: "invalid")

        // Assert
        #expect(color == nil)
    }

    @Test("Hex color parsing too short returns nil")
    func testHexColorTooShort() {
        // Arrange & Act
        let color = Color(hex: "#FF")

        // Assert
        #expect(color == nil)
    }

    @Test("Hex color parsing too long returns nil")
    func testHexColorTooLong() {
        // Arrange & Act
        let color = Color(hex: "#FF00000000")

        // Assert
        #expect(color == nil)
    }

    @Test("Hex color parsing empty string returns nil")
    func testHexColorEmptyString() {
        // Arrange & Act
        let color = Color(hex: "")

        // Assert
        #expect(color == nil)
    }

    @Test("Hex color parsing invalid hex characters returns nil")
    func testHexColorInvalidHexCharacters() {
        // Arrange & Act
        let color = Color(hex: "#GGGGGG")

        // Assert
        #expect(color == nil)
    }
}
