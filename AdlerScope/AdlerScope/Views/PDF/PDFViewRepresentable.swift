//
//  PDFViewRepresentable.swift
//  AdlerScope
//
//  NSViewRepresentable wrapper for PDFKit's PDFView
//

import PDFKit
import SwiftUI

#if os(macOS)
/// SwiftUI wrapper for PDFKit's PDFView
struct PDFViewRepresentable: NSViewRepresentable {
    // MARK: - Properties

    let pdfDocument: PDFDocument?

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Display settings
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .textBackgroundColor

        // Accessibility
        pdfView.setAccessibilityLabel("PDF Document Viewer")
        pdfView.setAccessibilityRole(.group)

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Only update if document changed (identity check)
        if pdfView.document !== pdfDocument {
            pdfView.document = pdfDocument
        }
    }
}

// MARK: - Preview

#Preview("PDF View") {
    PDFViewRepresentable(pdfDocument: PreviewPDFGenerator.sampleDocument)
        .frame(width: 600, height: 800)
}

#Preview("PDF View - No Document") {
    PDFViewRepresentable(pdfDocument: nil)
        .frame(width: 600, height: 800)
}

/// Helper to generate sample PDF for previews
private enum PreviewPDFGenerator {
    static var sampleDocument: PDFDocument? {
        // Create a simple PDF with text
        let pdfData = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter

        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        // Page 1
        context.beginPDFPage(nil)

        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        let title = "PDF Viewer Preview"
        title.draw(at: CGPoint(x: 72, y: 700), withAttributes: titleAttributes)

        // Draw body text
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.darkGray
        ]
        let body = """
        This is a sample PDF document generated for the
        Xcode Canvas preview.

        The PDFViewRepresentable wraps PDFKit's PDFView
        for use in SwiftUI on macOS.

        Features:
        • Auto-scaling
        • Continuous scrolling
        • Accessibility support
        """
        body.draw(in: CGRect(x: 72, y: 500, width: 468, height: 180), withAttributes: bodyAttributes)

        context.endPDFPage()
        context.closePDF()

        return PDFDocument(data: pdfData as Data)
    }
}
#endif
