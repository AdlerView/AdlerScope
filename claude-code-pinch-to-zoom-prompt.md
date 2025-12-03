# Claude Code Task: Implement Trackpad Pinch-to-Zoom in AdlerScope

## Context

AdlerScope is a macOS Markdown editor built with SwiftUI and AppKit. The editor uses `AppKitTextEditor` (an `NSViewRepresentable` wrapping `NSTextView`) for native text editing. The app follows Clean Architecture with MVVM and uses composition patterns for menu/action management.

## Task

Implement **Trackpad Pinch-to-Zoom** functionality for the Markdown editor using **Text-Level Zoom** (font size scaling), NOT NSScrollView magnification. This preserves correct line wrapping and text layout.

---

## Technical Requirements

### 1. Core Zoom Implementation

**Create a new `ZoomManager` class** following the existing `FormatMenuActions`/`RenderingManager` pattern:

```swift
// Location: AdlerScope/MenuBar/View/ZoomManager.swift

@Observable
@MainActor
final class ZoomManager {
    // Zoom State
    private(set) var currentZoomLevel: CGFloat = 1.0
    private var gestureBaseZoom: CGFloat = 1.0
    
    // Constraints
    let minimumZoomLevel: CGFloat = 0.5   // 50%
    let maximumZoomLevel: CGFloat = 3.0   // 300%
    let zoomStepFactor: CGFloat = 1.25    // 25% per step
    
    // Base font size (from EditorSettings)
    var basePointSize: CGFloat = 14.0
    
    // Pending zoom for NSTextView to apply
    var pendingZoomUpdate: CGFloat?
    
    // Methods
    func handleMagnifyGesture(phase: NSEvent.Phase, magnification: CGFloat)
    func zoomIn()
    func zoomOut()
    func resetZoom()
    func setZoomLevel(_ level: CGFloat, animated: Bool)
}
```

### 2. Modify AppKitTextEditor

**File: `AdlerScope/Views/Editor/AppKitTextEditor.swift`**

Add magnification gesture handling to the NSTextView:

```swift
// In the NSTextView setup within makeNSView:
// - Create custom NSTextView subclass OR use swizzling/delegation
// - Override magnify(with:) to capture trackpad pinch gestures
// - Forward gesture data to ZoomManager

// In Coordinator:
// - Add ZoomManager reference
// - Handle zoom updates similar to pendingInsertion pattern

// In updateNSView:
// - Check for pendingZoomUpdate from ZoomManager
// - Apply font scaling to textStorage
// - Preserve cursor position and selection
```

**Key Implementation Details:**

```swift
// Magnify gesture handling (in custom NSTextView subclass or via event monitor)
override func magnify(with event: NSEvent) {
    switch event.phase {
    case .began:
        zoomManager?.gestureBaseZoom = zoomManager?.currentZoomLevel ?? 1.0
    case .changed:
        let proposedZoom = gestureBaseZoom * (1.0 + event.magnification)
        zoomManager?.setZoomLevel(proposedZoom, animated: false)
    case .ended, .cancelled:
        zoomManager?.finalizeZoom()
    default:
        break
    }
}

// Smart magnify (two-finger double-tap)
override func smartMagnify(with event: NSEvent) {
    let targetZoom: CGFloat = (currentZoomLevel < 1.25) ? 1.5 : 1.0
    zoomManager?.setZoomLevel(targetZoom, animated: true)
}
```

### 3. Font Scaling Implementation

**Apply zoom by scaling fonts in NSTextStorage:**

```swift
private func applyZoomLevel(_ zoomLevel: CGFloat, to textView: NSTextView) {
    guard let textStorage = textView.textStorage else { return }
    
    // Preserve selection and scroll position
    let selectedRanges = textView.selectedRanges
    let visibleRect = textView.enclosingScrollView?.documentVisibleRect ?? textView.bounds
    
    textStorage.beginEditing()
    
    textStorage.enumerateAttribute(.font, in: NSRange(location: 0, length: textStorage.length), options: []) { value, range, _ in
        guard let font = value as? NSFont else { return }
        
        // Calculate scaled size
        let scaledSize = basePointSize * zoomLevel * (font.pointSize / basePointSize)
        let scaledFont = NSFont(descriptor: font.fontDescriptor, size: scaledSize) ?? font
        
        textStorage.addAttribute(.font, value: scaledFont, range: range)
    }
    
    textStorage.endEditing()
    
    // Update typing attributes
    if var typingAttrs = textView.typingAttributes,
       let font = typingAttrs[.font] as? NSFont {
        typingAttrs[.font] = NSFont(descriptor: font.fontDescriptor, size: basePointSize * zoomLevel)
        textView.typingAttributes = typingAttrs
    }
    
    // Restore selection
    textView.selectedRanges = selectedRanges
}
```

### 4. Integrate with ViewMenuActions

**File: `AdlerScope/MenuBar/View/ViewMenuActions.swift`**

Add zoom-related methods and state:

```swift
@Observable
final class ViewMenuActions {
    // Existing properties...
    
    // NEW: ZoomManager instance
    let zoomManager = ZoomManager()
    
    // NEW: Zoom action methods (for menu commands)
    func zoomIn() {
        zoomManager.zoomIn()
    }
    
    func zoomOut() {
        zoomManager.zoomOut()
    }
    
    func resetZoom() {
        zoomManager.resetZoom()
    }
    
    // NEW: Current zoom level for display
    var currentZoomPercentage: Int {
        Int(zoomManager.currentZoomLevel * 100)
    }
}
```

### 5. Add Menu Commands

**File: `AdlerScope/MenuBar/Commands.swift`**

Add zoom commands to the View menu:

```swift
// In DocumentGroupCommands or appropriate Commands struct

CommandGroup(after: .toolbar) {
    Section {
        Button("Zoom In") {
            zoomIn?()
        }
        .keyboardShortcut("+", modifiers: .command)
        .disabled(zoomIn == nil)
        
        Button("Zoom Out") {
            zoomOut?()
        }
        .keyboardShortcut("-", modifiers: .command)
        .disabled(zoomOut == nil)
        
        Button("Actual Size") {
            resetZoom?()
        }
        .keyboardShortcut("0", modifiers: .command)
        .disabled(resetZoom == nil)
    }
}
```

### 6. Add FocusedValues

**File: `AdlerScope/Extensions/FocusedValuesExtensions.swift`**

```swift
extension FocusedValues {
    // Existing entries...
    
    @Entry var zoomIn: (() -> Void)?
    @Entry var zoomOut: (() -> Void)?
    @Entry var resetZoom: (() -> Void)?
    @Entry var currentZoomLevel: CGFloat?
}
```

### 7. Wire Up in SplitEditorView

**File: `AdlerScope/Views/Editor/SplitEditorView.swift`**

```swift
// In the view body, add focused values:
.focusedSceneValue(\.zoomIn, viewModel.viewActions.zoomIn)
.focusedSceneValue(\.zoomOut, viewModel.viewActions.zoomOut)
.focusedSceneValue(\.resetZoom, viewModel.viewActions.resetZoom)
.focusedSceneValue(\.currentZoomLevel, viewModel.viewActions.zoomManager.currentZoomLevel)
```

### 8. Integrate with SplitEditorViewModel

**File: `AdlerScope/ViewModels/SplitEditorViewModel.swift`**

Pass ZoomManager to AppKitTextEditor:

```swift
@Observable
final class SplitEditorViewModel {
    // Existing properties...
    
    // ZoomManager is accessed via viewActions.zoomManager
    var zoomManager: ZoomManager {
        viewActions.zoomManager
    }
}
```

---

## Architecture Notes

### Follow Existing Patterns

1. **Composition Pattern**: ZoomManager should be a composed member of ViewMenuActions (like RenderingManager)

2. **Pending Update Pattern**: Use `pendingZoomUpdate` similar to `pendingInsertion` in FormatMenuActions

3. **FocusedValue Pattern**: Expose zoom actions as closures via FocusedValues for menu commands

4. **Coordinator Pattern**: Handle zoom state changes through the AppKitTextEditor Coordinator

### State Flow

```
User pinch gesture
    ↓
NSTextView.magnify(with:) 
    ↓
ZoomManager.handleMagnifyGesture()
    ↓
ZoomManager.pendingZoomUpdate = newLevel
    ↓
updateNSView() detects pending update
    ↓
applyZoomLevel() scales fonts in textStorage
    ↓
pendingZoomUpdate = nil
```

---

## Optional Enhancements (Lower Priority)

1. **Persist Zoom Level**: Add `zoomLevel` to `EditorSettings` in SwiftData for persistence

2. **Preview Zoom**: Apply zoom to PreviewView as well (CSS transform or font scaling)

3. **Zoom Indicator**: Show current zoom percentage in the status bar or toolbar

4. **Animated Transitions**: Use NSAnimationContext for smooth zoom animations

5. **Smart Zoom Behavior**: Configure smart magnify (two-finger double-tap) behavior

---

## Files to Modify/Create

| Action | File Path |
|--------|-----------|
| CREATE | `AdlerScope/MenuBar/View/ZoomManager.swift` |
| MODIFY | `AdlerScope/Views/Editor/AppKitTextEditor.swift` |
| MODIFY | `AdlerScope/MenuBar/View/ViewMenuActions.swift` |
| MODIFY | `AdlerScope/MenuBar/Commands.swift` |
| MODIFY | `AdlerScope/Extensions/FocusedValuesExtensions.swift` |
| MODIFY | `AdlerScope/Views/Editor/SplitEditorView.swift` |
| MODIFY | `AdlerScope/ViewModels/SplitEditorViewModel.swift` |

---

## Testing Checklist

- [ ] Trackpad pinch-to-zoom works smoothly
- [ ] Zoom level is clamped between 50% and 300%
- [ ] Text reflows correctly at all zoom levels
- [ ] Cursor position is preserved during zoom
- [ ] Selection is preserved during zoom
- [ ] ⌘+ zooms in
- [ ] ⌘- zooms out
- [ ] ⌘0 resets to 100%
- [ ] Menu items are properly enabled/disabled at zoom limits
- [ ] Two-finger double-tap (smart magnify) toggles zoom
- [ ] Zoom works with styled Markdown (headings, code, etc.)

---

## Important: DO NOT Use NSScrollView Magnification

The analysis explicitly recommends against `NSScrollView.allowsMagnification = true` because:
- Text doesn't reflow when zoomed
- Line wrapping stays at original width  
- Users must scroll horizontally to read zoomed text

**Always use font size scaling for text-level zoom.**
