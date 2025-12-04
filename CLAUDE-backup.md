# AdlerScope – Codebase Overview

## Project Summary

**Type:** Cross-platform Markdown Editor (macOS primary, iOS secondary)

**Stack:**
- Swift 5.9+ / SwiftUI / SwiftData
- Apple's swift-markdown (0.5.0+)
- PDFKit, AppIntents

**Architecture:** Clean Architecture (MVVM + Repository Pattern)

---

## Project Structure

```
AdlerScope/
├── Core/                    # DI, Services (Document, iCloud, CloudKit)
├── Domain/
│   ├── Entities/            # AppSettings, EditorSettings, RecentDocument
│   ├── Repositories/        # Protocol interfaces
│   ├── UseCases/            # ParseMarkdown, LoadSettings, SaveSettings, etc.
│   └── Errors/              # Custom error types
├── Data/Repositories/       # Concrete implementations
├── Presentation/
│   ├── ViewModels/          # SplitEditorViewModel, SettingsViewModel
│   └── Views/
│       ├── Editor/          # AppKitTextEditor, SplitEditorView
│       ├── Preview/         # HeadingView, CodeBlockView, TableView, etc.
│       ├── Sidebar/         # RecentDocumentsSidebarView
│       └── Settings/        # AdlerScopeSettingsView
├── MenuBar/
│   ├── Commands.swift       # Main command definitions
│   ├── Core/RenderingManager.swift
│   ├── Edit/EditMenuActions.swift
│   ├── Format/FormatMenuActions.swift
│   └── View/ViewMenuActions.swift
├── AppIntents/              # Siri & Shortcuts integration
├── Document/                # MarkdownFileDocument
└── Extensions/              # FocusedValues, Bundle, Queries
```

---

## Key Patterns

### 1. App Entry & Document Handling

```swift
// AdlerScopeApp.swift
@main struct AdlerScopeApp: App {
    @State private var settingsViewModel: SettingsViewModel  // Prevents EXC_BAD_ACCESS
    
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFileDocument()) { config in
            DocumentEditorView(document: config.$document)
        }
    }
}
```

**Supported Types:** `.markdown`, `.plainText`, `.rMarkdown`, `.quarto`, `.pdf` (read-only), `.image` (read-only)

### 2. Editor (AppKitTextEditor.swift)

NSTextView wrapped in `NSViewRepresentable` for cursor tracking.

**Key Pattern – Pending Insertion:**
```swift
// FormatMenuActions sets pendingInsertion
formatActions.pendingInsertion = "**"

// updateNSView checks and applies
if let text = formatActions.pendingInsertion {
    insertTextAtCursor(textView, text)
    formatActions.pendingInsertion = nil
}
```

**Recursive Update Guard:**
```swift
var isUpdatingFromBinding = false

func textDidChange(_ notification: Notification) {
    guard !isUpdatingFromBinding else { return }
    parent.text = textView.string
}
```

### 3. State Management (Composition Pattern)

```swift
@Observable
final class SplitEditorViewModel {
    private let renderingManager: RenderingManager
    let viewActions: ViewMenuActions
    let formatActions: FormatMenuActions
    let editActions: EditMenuActions
    
    var renderedDocument: Document? { renderingManager.renderedDocument }
    var viewMode: ViewMode { viewActions.viewMode }
}
```

### 4. Rendering (500ms Debounce)

```swift
// RenderingManager.swift
func debounceRender(content: String) {
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await render(content: content)
    }
}
```

### 5. Preview (AST Dispatcher)

```swift
// PreviewView.swift – Type-based dispatch
if let heading = markup as? Heading {
    HeadingView(heading: heading)
} else if let codeBlock = markup as? CodeBlock {
    CodeBlockView(codeBlock: codeBlock)
} else if let table = markup as? Markdown.Table {
    TableView(table: table)
}
// ...
```

### 6. Settings (Singleton via Fixed UUID)

```swift
@Model final class AppSettings {
    static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    var id: UUID = AppSettings.singletonID
}
```

### 7. FocusedValues for Menu Commands

```swift
// FocusedValuesExtensions.swift
extension FocusedValues {
    @Entry var toggleBold: (() -> Void)?
    @Entry var showEditor: (() -> Void)?
    // ...
}

// Commands.swift
@FocusedValue(\.toggleBold) var toggleBold
Button("Bold") { toggleBold?() }.disabled(toggleBold == nil)

// SplitEditorView.swift
.focusedSceneValue(\.toggleBold, viewModel.formatActions.toggleBold)
```

### 8. iCloud (NSMetadataQuery)

```swift
// iCloudDocumentManager.swift
query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
query.predicate = NSPredicate(format: "%K LIKE '*.md'", NSMetadataItemFSNameKey)
```

### 9. Security-Scoped Bookmarks

```swift
// RecentDocument.swift
func createBookmark() -> Bool {
    bookmarkData = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
}

func resolveBookmark() throws -> URL {
    var isStale = false
    let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
    if isStale { /* recreate bookmark */ }
    return url
}
```

### 10. AppIntents (NavigationService Mediator)

```swift
// NavigationService.swift
@Observable @MainActor
final class NavigationService {
    static let shared = NavigationService()
    var pendingAction: NavigationAction = .none
}

// OpenDocumentIntent.swift
func perform() async throws -> some IntentResult {
    NavigationService.shared.requestOpenDocument(id: document.id)
    return .result()
}
```

---

## Key Files Reference

| Area | Files |
|------|-------|
| Entry | `AdlerScopeApp.swift`, `MarkdownFileDocument.swift` |
| Editor | `AppKitTextEditor.swift`, `SplitEditorView.swift` |
| Preview | `PreviewView.swift`, `HeadingView.swift`, `CodeBlockView.swift`, `TableView.swift` |
| State | `SplitEditorViewModel.swift`, `RenderingManager.swift`, `FormatMenuActions.swift` |
| iCloud | `iCloudDocumentManager.swift`, `RecentDocument.swift` |
| Intents | `OpenDocumentIntent.swift`, `NavigationService.swift`, `RecentDocumentQuery.swift` |

---

## Notable Decisions

1. **Pure SwiftUI** – No AppKit/UIKit for UI, only NSTextView bridge for cursor tracking
2. **DocumentGroup** – Native macOS document handling (File menu, autosave, undo/redo)
3. **swift-markdown AST** – Apple's official parser, not custom rendering
4. **Actor-based ParseMarkdownUseCase** – Thread-safe parsing
5. **Debounced Rendering** – 500ms delay prevents overhead during rapid typing
6. **Auto-save Debounce** – 1s delay batches rapid setting changes
7. **@State SettingsViewModel** – App-level lifecycle prevents FocusedValue crashes
