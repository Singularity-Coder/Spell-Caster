# Spell Caster - File Structure

## Overview

This document defines the file and directory structure for the Spell Caster project. The project uses Swift Package Manager and follows a simplified architecture with native macOS window tabbing.

## Project Structure

```
SpellCaster/
├── Package.swift                    # Swift Package Manager manifest
├── SpellCaster/                    # Main application target
│   ├── App/
│   │   ├── SpellCasterApp.swift    # App entry point with WindowGroup
│   │   └── AppDelegate.swift       # Enables native window tabbing
│   │
│   ├── TerminalEngine/
│   │   ├── PTYProcess.swift        # PTY session management
│   │   ├── TerminalEmulator.swift  # Terminal state machine
│   │   ├── ANSIParser.swift        # Escape sequence parser
│   │   ├── TerminalInput.swift     # Input handling
│   │   └── ShellIntegration.swift  # Shell integration protocol
│   │
│   ├── Renderer/
│   │   ├── TerminalView.swift      # AppKit terminal view
│   │   ├── TerminalRenderer.swift  # CoreText rendering
│   │   └── SelectionManager.swift  # Selection handling
│   │
│   ├── Models/
│   │   ├── TerminalCell.swift      # Grid cell model
│   │   ├── TerminalGrid.swift      # Grid buffer
│   │   ├── TerminalState.swift     # Terminal state
│   │   ├── Profile.swift           # User profiles
│   │   ├── AISession.swift         # AI session state
│   │   ├── AIMessage.swift         # Chat messages
│   │   ├── CommandCard.swift       # Command actions
│   │   └── ContextSnapshot.swift   # AI context
│   │
│   ├── ViewModels/
│   │   ├── PaneViewModel.swift     # Terminal pane state
│   │   ├── AISidebarViewModel.swift # AI sidebar logic
│   │   └── PreferencesViewModel.swift
│   │
│   ├── Views/
│   │   ├── MainWindowView.swift    # Main window (terminal + sidebar)
│   │   ├── TerminalViewRepresentable.swift # SwiftUI-AppKit bridge
│   │   ├── AISidebarView.swift     # AI chat interface
│   │   ├── ChatMessageView.swift   # Message display
│   │   ├── CommandCardView.swift   # Insert/Run/Copy actions
│   │   ├── ContextInspectorView.swift # Context preview
│   │   └── PreferencesView.swift   # Settings window
│   │
│   ├── AI/
│   │   ├── AIProvider.swift        # Provider protocol
│   │   ├── OpenAIProvider.swift    # OpenAI implementation
│   │   ├── PromptPresets.swift     # System prompt templates
│   │   ├── AIContextBuilder.swift  # Context construction
│   │   └── SecretRedactor.swift    # Secret detection
│   │
│   ├── Services/
│   │   ├── KeychainService.swift   # Secure key storage
│   │   └── ProfileManager.swift    # Profile persistence
│   │
│   └── Resources/
│       └── ShellIntegration/
│           ├── spellcaster-zsh.sh  # Zsh integration
│           └── spellcaster-bash.sh # Bash integration
│
├── docs/                           # Documentation
│   └── architecture/
│       ├── 01-overall-architecture.md
│       ├── 02-data-models.md
│       ├── 03-terminal-engine.md
│       ├── 04-rendering-layer.md
│       ├── 05-window-management.md  # Native tabs approach
│       ├── 06-ai-sidebar.md
│       ├── 07-ai-provider.md
│       ├── 08-context-capture.md
│       ├── 09-security-privacy.md
│       └── 10-file-structure.md
│
├── .gitignore
└── README.md
```

> **Note**: This project uses **native macOS window tabbing** instead of custom window/tab management. The `WindowManagement` folder from the original architecture has been removed. Each `MainWindowView` instance creates its own `PaneViewModel` and `AISession` via `@StateObject`, ensuring complete isolation between tabs.

## Key Architecture Decisions

### Native Window Tabbing

The project intentionally avoids custom window management:

| Removed | Replacement |
|---------|-------------|
| `WindowManager.swift` | Native `WindowGroup` |
| `WindowViewModel.swift` | Per-view `@StateObject` |
| `TabBarView.swift` | Native macOS tab bar |
| `SplitPaneView.swift` | Future feature |
| `WindowController.swift` | SwiftUI `WindowGroup` |

### Per-Window State

Each window (tab) maintains independent state:

```swift
struct MainWindowView: View {
    @StateObject private var paneViewModel: PaneViewModel
    @StateObject private var aiSession: AISession
    @State private var sidebarVisible: Bool = true
    // ...
}
```

This ensures:
- Terminal sessions are isolated per tab
- AI conversations are independent per window
- Settings changes don't affect other windows

## Naming Conventions

### Files

| Type | Convention | Example |
|------|------------|---------|
| Swift files | PascalCase | `TerminalEngine.swift` |
| View files | PascalCase + "View" suffix | `AISidebarView.swift` |
| ViewModel files | PascalCase + "ViewModel" suffix | `PaneViewModel.swift` |
| Protocol files | PascalCase + "Protocol" suffix (optional) | `AIProvider.swift` |
| Shell scripts | kebab-case + ".sh" | `spellcaster-zsh.sh` |

### Code

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `TerminalEmulator` |
| Structs | PascalCase | `TerminalCell` |
| Enums | PascalCase | `RiskLevel` |
| Protocols | PascalCase | `AIProviderProtocol` |
| Variables | camelCase | `currentContext` |
| Functions | camelCase | `captureContext()` |

## Module Organization

### TerminalEngine

Core PTY and terminal emulation:
- `PTYProcess`: Fork/exec shell processes
- `TerminalEmulator`: State machine for terminal
- `ANSIParser`: Parse escape sequences
- `TerminalInput`: Handle keyboard/mouse input

### Renderer

High-performance text rendering:
- `TerminalView`: AppKit NSView for Metal/CoreText
- `TerminalRenderer`: CoreText-based text drawing
- `SelectionManager`: Mouse selection handling

### AI

AI integration layer:
- `AIProvider`: Protocol for AI backends
- `OpenAIProvider`: OpenAI API implementation
- `PromptPresets`: System prompt templates
- `SecretRedactor`: Remove secrets from context

### Views

SwiftUI interface:
- `MainWindowView`: Main window layout
- `AISidebarView`: Chat interface
- `PreferencesView`: Settings window

## Build Configuration

### Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpellCaster",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SpellCaster",
            targets: ["SpellCaster"]
        )
    ],
    dependencies: [
        // Add dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "SpellCaster",
            dependencies: []
        )
    ]
)
```

### Build Commands

```bash
# Build
swift build

# Run
swift run

# Build release
swift build -c release
```

## Summary

| Aspect | Implementation |
|--------|----------------|
| Build System | Swift Package Manager |
| Window Management | Native macOS tabs |
| Per-Window State | `@StateObject` in `MainWindowView` |
| Terminal Session | `PaneViewModel` (one per window) |
| AI Session | `AISession` (one per window) |
| Rendering | AppKit + CoreText |

## Next Steps

For architecture details, see:
- [01-overall-architecture.md](01-overall-architecture.md) - System overview
- [05-window-management.md](05-window-management.md) - Native tabs implementation
