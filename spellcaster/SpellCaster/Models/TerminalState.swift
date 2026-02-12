import Foundation
import Combine

/// Complete terminal state including grid, cursor, modes, and scrollback
class TerminalState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var needsDisplay: Bool = false
    
    // MARK: - Screen Buffers
    
    /// Primary screen buffer
    private(set) var primaryGrid: TerminalGrid
    
    /// Alternate screen buffer (for full-screen apps like vim, less)
    private(set) var alternateGrid: TerminalGrid
    
    /// Currently active grid
    var activeGrid: TerminalGrid {
        return useAlternateScreen ? alternateGrid : primaryGrid
    }
    
    /// Scrollback buffer (ring buffer of lines)
    private(set) var scrollback: [[TerminalCell]]
    private(set) var scrollbackLimit: Int
    
    // MARK: - Cursor State
    
    /// Current cursor position (0-based)
    var cursorRow: Int = 0
    var cursorColumn: Int = 0
    
    /// Cursor style
    var cursorStyle: CursorStyle = .block
    
    /// Cursor visibility
    var cursorVisible: Bool = true
    
    /// Cursor blink state
    var cursorBlink: Bool = true
    
    /// Saved cursor state (for DECSC/DECRC)
    private var savedCursor: SavedCursor?
    
    // MARK: - Terminal Modes
    
    var originMode: Bool = false              // DECOM - origin mode
    var wraparoundMode: Bool = true           // DECAWM - auto wrap
    var insertMode: Bool = false              // IRM - insert/replace mode
    var applicationCursorKeys: Bool = false   // DECCKM - cursor key mode
    var applicationKeypad: Bool = false       // DECKPAM - keypad mode
    var bracketedPaste: Bool = false          // Bracketed paste mode
    var mouseReportingMode: MouseReportingMode = .none
    var focusReportingMode: Bool = false
    var useAlternateScreen: Bool = false      // Alternate screen buffer
    
    // MARK: - Scroll Region
    
    var scrollTop: Int = 0
    var scrollBottom: Int
    
    // MARK: - Tab Stops
    
    private var tabStops: Set<Int>
    
    // MARK: - Character Set State
    
    var charset: CharacterSet = .ascii
    var g0Charset: CharacterSet = .ascii
    var g1Charset: CharacterSet = .ascii
    var activeCharset: Int = 0  // 0 = G0, 1 = G1
    
    // MARK: - Current SGR State
    
    var currentForeground: TerminalColor = .defaultForeground
    var currentBackground: TerminalColor = .defaultBackground
    var currentAttributes: CellAttributes = CellAttributes()
    
    // MARK: - Window Title
    
    @Published var windowTitle: String = "SpellCaster"
    
    // MARK: - Shell Integration
    
    var shellIntegration: ShellIntegrationState?
    
    // MARK: - Initialization
    
    init(rows: Int, columns: Int, scrollbackLimit: Int = 10000) {
        self.primaryGrid = TerminalGrid(rows: rows, columns: columns)
        self.alternateGrid = TerminalGrid(rows: rows, columns: columns)
        self.scrollback = []
        self.scrollbackLimit = scrollbackLimit
        self.scrollBottom = rows - 1
        self.tabStops = Set(stride(from: 8, to: columns, by: 8))
    }
    
    // MARK: - Grid Operations
    
    func resize(rows: Int, columns: Int) {
        primaryGrid.resize(rows: rows, columns: columns)
        alternateGrid.resize(rows: rows, columns: columns)
        scrollBottom = rows - 1
        
        // Clamp cursor position
        cursorRow = min(cursorRow, rows - 1)
        cursorColumn = min(cursorColumn, columns - 1)
        
        // Rebuild tab stops
        tabStops = Set(stride(from: 8, to: columns, by: 8))
        
        needsDisplay = true
    }
    
    func clear() {
        activeGrid.clear()
        cursorRow = 0
        cursorColumn = 0
        needsDisplay = true
    }
    
    func clearScrollback() {
        scrollback.removeAll()
        needsDisplay = true
    }
    
    func reset() {
        // Reset to initial state
        primaryGrid.clear()
        alternateGrid.clear()
        scrollback.removeAll()
        
        cursorRow = 0
        cursorColumn = 0
        cursorStyle = .block
        cursorVisible = true
        cursorBlink = true
        
        originMode = false
        wraparoundMode = true
        insertMode = false
        applicationCursorKeys = false
        applicationKeypad = false
        bracketedPaste = false
        mouseReportingMode = .none
        focusReportingMode = false
        useAlternateScreen = false
        
        scrollTop = 0
        scrollBottom = primaryGrid.rows - 1
        
        currentForeground = .defaultForeground
        currentBackground = .defaultBackground
        currentAttributes = CellAttributes()
        
        charset = .ascii
        g0Charset = .ascii
        g1Charset = .ascii
        activeCharset = 0
        
        needsDisplay = true
    }
    
    // MARK: - Cursor Operations
    
    func moveCursor(row: Int, column: Int) {
        let maxRow = activeGrid.rows - 1
        let maxCol = activeGrid.columns - 1
        
        cursorRow = max(0, min(row, maxRow))
        cursorColumn = max(0, min(column, maxCol))
        needsDisplay = true
    }
    
    func saveCursor() {
        savedCursor = SavedCursor(
            row: cursorRow,
            column: cursorColumn,
            foreground: currentForeground,
            background: currentBackground,
            attributes: currentAttributes,
            charset: charset,
            originMode: originMode
        )
    }
    
    func restoreCursor() {
        guard let saved = savedCursor else { return }
        
        cursorRow = saved.row
        cursorColumn = saved.column
        currentForeground = saved.foreground
        currentBackground = saved.background
        currentAttributes = saved.attributes
        charset = saved.charset
        originMode = saved.originMode
        needsDisplay = true
    }
    
    // MARK: - Scrollback Operations
    
    func addLineToScrollback(_ line: [TerminalCell]) {
        scrollback.append(line)
        if scrollback.count > scrollbackLimit {
            scrollback.removeFirst()
        }
    }
    
    // MARK: - Tab Stop Operations
    
    func setTabStop(at column: Int) {
        tabStops.insert(column)
    }
    
    func clearTabStop(at column: Int) {
        tabStops.remove(column)
    }
    
    func clearAllTabStops() {
        tabStops.removeAll()
    }
    
    func nextTabStop(after column: Int) -> Int {
        let sorted = tabStops.sorted()
        return sorted.first(where: { $0 > column }) ?? activeGrid.columns - 1
    }
    
    // MARK: - Text Extraction
    
    func getVisibleText() -> String {
        var text = ""
        for row in 0..<activeGrid.rows {
            let line = activeGrid.getRow(row)
            for cell in line {
                if !cell.isWideContinuation {
                    text.append(Character(cell.character))
                }
            }
            text.append("\n")
        }
        return text
    }
}

// MARK: - Supporting Types

enum CursorStyle: Codable {
    case block
    case underline
    case bar
}

enum MouseReportingMode {
    case none
    case x10            // Click only
    case normal         // Click and release
    case buttonEvent    // Click, release, and motion while button pressed
    case anyEvent       // All motion events
    case sgr            // SGR-encoded mouse reporting
    case urxvt          // urxvt-style mouse reporting
}

enum CharacterSet {
    case ascii
    case decSpecialGraphics  // Line drawing characters
    case uk
    case dutch
    case finnish
    case french
    case frenchCanadian
    case german
    case italian
    case norwegian
    case spanish
    case swedish
    case swiss
}

struct SavedCursor {
    let row: Int
    let column: Int
    let foreground: TerminalColor
    let background: TerminalColor
    let attributes: CellAttributes
    let charset: CharacterSet
    let originMode: Bool
}

/// Shell integration state tracking
struct ShellIntegrationState {
    var currentCommand: String?
    var commandStartTime: Date?
    var lastExitStatus: Int?
    var currentWorkingDirectory: String?
    var gitBranch: String?
    var promptMark: (row: Int, column: Int)?
    var commandStartMark: (row: Int, column: Int)?
    var commandEndMark: (row: Int, column: Int)?
}
