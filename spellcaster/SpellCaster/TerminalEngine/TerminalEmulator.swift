import Foundation
import Combine

/// Main terminal emulator coordinating parser and state
class TerminalEmulator {
    // MARK: - Properties
    
    private let parser: ANSIParser
    private(set) var state: TerminalState
    private let queue = DispatchQueue(label: "com.spellcaster.emulator", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(rows: Int, columns: Int) {
        self.state = TerminalState(rows: rows, columns: columns)
        self.parser = ANSIParser()
        
        setupParserCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupParserCallbacks() {
        parser.onPrint = { [weak self] scalar in
            self?.handlePrint(scalar)
        }
        
        parser.onExecute = { [weak self] byte in
            self?.handleExecute(byte)
        }
        
        parser.onCSI = { [weak self] params, intermediates, final in
            self?.handleCSI(params: params, intermediates: intermediates, final: final)
        }
        
        parser.onOSC = { [weak self] string in
            self?.handleOSC(string)
        }
        
        parser.onESC = { [weak self] intermediates, final in
            self?.handleESC(intermediates: intermediates, final: final)
        }
    }
    
    // MARK: - Input Processing
    
    func processData(_ data: Data) {
        queue.async { [weak self] in
            self?.parser.parse(data)
            DispatchQueue.main.async {
                self?.state.needsDisplay = true
            }
        }
    }
    
    // MARK: - Print Handler
    
    private func handlePrint(_ scalar: UnicodeScalar) {
        let grid = state.activeGrid
        
        // Handle wide characters
        let isWide = scalar.properties.isEmojiPresentation || 
                     (scalar.value >= 0x1100 && scalar.value <= 0x115F) ||
                     (scalar.value >= 0x2E80 && scalar.value <= 0x9FFF)
        
        // Create cell
        var cell = TerminalCell(
            character: scalar,
            foregroundColor: state.currentForeground,
            backgroundColor: state.currentBackground,
            attributes: state.currentAttributes,
            isWide: isWide
        )
        
        // Insert mode
        if state.insertMode {
            grid.insertBlanks(at: state.cursorRow, column: state.cursorColumn, count: isWide ? 2 : 1)
        }
        
        // Write cell
        grid[state.cursorRow, state.cursorColumn] = cell
        
        // Handle wide character continuation
        if isWide && state.cursorColumn + 1 < grid.columns {
            var continuation = TerminalCell.blank
            continuation.isWideContinuation = true
            grid[state.cursorRow, state.cursorColumn + 1] = continuation
            state.cursorColumn += 1
        }
        
        // Advance cursor
        state.cursorColumn += 1
        
        // Handle line wrap
        if state.cursorColumn >= grid.columns {
            if state.wraparoundMode {
                grid.setLineWrapped(state.cursorRow, wrapped: true)
                state.cursorColumn = 0
                state.cursorRow += 1
                
                // Scroll if needed
                if state.cursorRow > state.scrollBottom {
                    grid.scrollUp(top: state.scrollTop, bottom: state.scrollBottom)
                    state.cursorRow = state.scrollBottom
                }
            } else {
                state.cursorColumn = grid.columns - 1
            }
        }
    }
    
    // MARK: - Execute Handler (C0 controls)
    
    private func handleExecute(_ byte: UInt8) {
        switch byte {
        case 0x07: // BEL
            // Bell - handled by view
            break
        case 0x08: // BS - Backspace
            if state.cursorColumn > 0 {
                state.cursorColumn -= 1
            }
        case 0x09: // HT - Tab
            state.cursorColumn = state.nextTabStop(after: state.cursorColumn)
        case 0x0A, 0x0B, 0x0C: // LF, VT, FF - Line feed
            lineFeed()
        case 0x0D: // CR - Carriage return
            state.cursorColumn = 0
        case 0x0E: // SO - Shift out (G1 charset)
            state.activeCharset = 1
        case 0x0F: // SI - Shift in (G0 charset)
            state.activeCharset = 0
        default:
            break
        }
    }
    
    // MARK: - CSI Handler
    
    private func handleCSI(params: [Int], intermediates: [UInt8], final: UInt8) {
        switch final {
        case 0x40: // @ - ICH - Insert blank characters
            let count = params.first ?? 1
            state.activeGrid.insertBlanks(at: state.cursorRow, column: state.cursorColumn, count: count)
            
        case 0x41: // A - CUU - Cursor up
            let count = max(1, params.first ?? 1)
            state.cursorRow = max(state.scrollTop, state.cursorRow - count)
            
        case 0x42: // B - CUD - Cursor down
            let count = max(1, params.first ?? 1)
            state.cursorRow = min(state.scrollBottom, state.cursorRow + count)
            
        case 0x43: // C - CUF - Cursor forward
            let count = max(1, params.first ?? 1)
            state.cursorColumn = min(state.activeGrid.columns - 1, state.cursorColumn + count)
            
        case 0x44: // D - CUB - Cursor backward
            let count = max(1, params.first ?? 1)
            state.cursorColumn = max(0, state.cursorColumn - count)
            
        case 0x45: // E - CNL - Cursor next line
            let count = max(1, params.first ?? 1)
            state.cursorRow = min(state.scrollBottom, state.cursorRow + count)
            state.cursorColumn = 0
            
        case 0x46: // F - CPL - Cursor previous line
            let count = max(1, params.first ?? 1)
            state.cursorRow = max(state.scrollTop, state.cursorRow - count)
            state.cursorColumn = 0
            
        case 0x47: // G - CHA - Cursor horizontal absolute
            let col = max(1, params.first ?? 1) - 1
            state.cursorColumn = min(state.activeGrid.columns - 1, col)
            
        case 0x48, 0x66: // H, f - CUP - Cursor position
            let row = max(1, params.first ?? 1) - 1
            let col = max(1, params.count > 1 ? params[1] : 1) - 1
            state.cursorRow = min(state.scrollBottom, row)
            state.cursorColumn = min(state.activeGrid.columns - 1, col)
            
        case 0x4A: // J - ED - Erase in display
            let mode = params.first ?? 0
            eraseInDisplay(mode: mode)
            
        case 0x4B: // K - EL - Erase in line
            let mode = params.first ?? 0
            eraseInLine(mode: mode)
            
        case 0x4C: // L - IL - Insert lines
            let count = max(1, params.first ?? 1)
            for _ in 0..<count {
                state.activeGrid.scrollDown(top: state.cursorRow, bottom: state.scrollBottom)
            }
            
        case 0x4D: // M - DL - Delete lines
            let count = max(1, params.first ?? 1)
            for _ in 0..<count {
                state.activeGrid.scrollUp(top: state.cursorRow, bottom: state.scrollBottom)
            }
            
        case 0x50: // P - DCH - Delete characters
            let count = max(1, params.first ?? 1)
            state.activeGrid.deleteCells(at: state.cursorRow, column: state.cursorColumn, count: count)
            
        case 0x53: // S - SU - Scroll up
            let count = max(1, params.first ?? 1)
            for _ in 0..<count {
                state.activeGrid.scrollUp(top: state.scrollTop, bottom: state.scrollBottom)
            }
            
        case 0x54: // T - SD - Scroll down
            let count = max(1, params.first ?? 1)
            for _ in 0..<count {
                state.activeGrid.scrollDown(top: state.scrollTop, bottom: state.scrollBottom)
            }
            
        case 0x58: // X - ECH - Erase characters
            let count = max(1, params.first ?? 1)
            for i in 0..<count {
                let col = state.cursorColumn + i
                if col < state.activeGrid.columns {
                    state.activeGrid[state.cursorRow, col] = TerminalCell.blank
                }
            }
            
        case 0x64: // d - VPA - Vertical position absolute
            let row = max(1, params.first ?? 1) - 1
            state.cursorRow = min(state.scrollBottom, row)
            
        case 0x68: // h - SM - Set mode
            setMode(params: params, intermediates: intermediates, set: true)
            
        case 0x6C: // l - RM - Reset mode
            setMode(params: params, intermediates: intermediates, set: false)
            
        case 0x6D: // m - SGR - Select graphic rendition
            handleSGR(params: params)
            
        case 0x72: // r - DECSTBM - Set scrolling region
            let top = max(1, params.first ?? 1) - 1
            let bottom = params.count > 1 ? params[1] - 1 : state.activeGrid.rows - 1
            state.scrollTop = min(top, state.activeGrid.rows - 1)
            state.scrollBottom = min(bottom, state.activeGrid.rows - 1)
            state.cursorRow = 0
            state.cursorColumn = 0
            
        default:
            break
        }
    }
    
    // MARK: - ESC Handler
    
    private func handleESC(intermediates: [UInt8], final: UInt8) {
        switch final {
        case 0x37: // 7 - DECSC - Save cursor
            state.saveCursor()
        case 0x38: // 8 - DECRC - Restore cursor
            state.restoreCursor()
        case 0x44: // D - IND - Index (line feed)
            lineFeed()
        case 0x45: // E - NEL - Next line
            state.cursorColumn = 0
            lineFeed()
        case 0x4D: // M - RI - Reverse index
            if state.cursorRow == state.scrollTop {
                state.activeGrid.scrollDown(top: state.scrollTop, bottom: state.scrollBottom)
            } else if state.cursorRow > 0 {
                state.cursorRow -= 1
            }
        default:
            break
        }
    }
    
    // MARK: - OSC Handler
    
    private func handleOSC(_ string: String) {
        let parts = string.split(separator: ";", maxSplits: 1)
        guard let command = parts.first, let code = Int(command) else { return }
        
        switch code {
        case 0, 2: // Set window title
            if parts.count > 1 {
                DispatchQueue.main.async {
                    self.state.windowTitle = String(parts[1])
                }
            }
        case 1337: // iTerm2/shell integration
            if parts.count > 1 {
                handleShellIntegration(String(parts[1]))
            }
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func lineFeed() {
        state.cursorRow += 1
        if state.cursorRow > state.scrollBottom {
            state.activeGrid.scrollUp(top: state.scrollTop, bottom: state.scrollBottom)
            state.cursorRow = state.scrollBottom
        }
    }
    
    private func eraseInDisplay(mode: Int) {
        let grid = state.activeGrid
        let blank = TerminalCell.blank
        
        switch mode {
        case 0: // Erase below
            for col in state.cursorColumn..<grid.columns {
                grid[state.cursorRow, col] = blank
            }
            for row in (state.cursorRow + 1)..<grid.rows {
                grid.clearRow(row, withCell: blank)
            }
        case 1: // Erase above
            for row in 0..<state.cursorRow {
                grid.clearRow(row, withCell: blank)
            }
            for col in 0...state.cursorColumn {
                grid[state.cursorRow, col] = blank
            }
        case 2, 3: // Erase all
            grid.clear(withCell: blank)
        default:
            break
        }
    }
    
    private func eraseInLine(mode: Int) {
        let grid = state.activeGrid
        let blank = TerminalCell.blank
        
        switch mode {
        case 0: // Erase to right
            for col in state.cursorColumn..<grid.columns {
                grid[state.cursorRow, col] = blank
            }
        case 1: // Erase to left
            for col in 0...state.cursorColumn {
                grid[state.cursorRow, col] = blank
            }
        case 2: // Erase entire line
            grid.clearRow(state.cursorRow, withCell: blank)
        default:
            break
        }
    }
    
    private func setMode(params: [Int], intermediates: [UInt8], set: Bool) {
        let isPrivate = intermediates.contains(0x3F) // '?'
        
        for param in params {
            if isPrivate {
                setPrivateMode(param, set: set)
            } else {
                setStandardMode(param, set: set)
            }
        }
    }
    
    private func setPrivateMode(_ mode: Int, set: Bool) {
        switch mode {
        case 1: // DECCKM - Application cursor keys
            state.applicationCursorKeys = set
        case 6: // DECOM - Origin mode
            state.originMode = set
        case 7: // DECAWM - Auto wrap
            state.wraparoundMode = set
        case 25: // DECTCEM - Cursor visibility
            state.cursorVisible = set
        case 1049: // Alternate screen buffer
            state.useAlternateScreen = set
        case 2004: // Bracketed paste
            state.bracketedPaste = set
        default:
            break
        }
    }
    
    private func setStandardMode(_ mode: Int, set: Bool) {
        switch mode {
        case 4: // IRM - Insert/replace mode
            state.insertMode = set
        default:
            break
        }
    }
    
    private func handleSGR(params: [Int]) {
        var i = 0
        while i < params.count {
            let param = params[i]
            
            switch param {
            case 0: // Reset
                state.currentForeground = .defaultForeground
                state.currentBackground = .defaultBackground
                state.currentAttributes = CellAttributes()
            case 1: // Bold
                state.currentAttributes.insert(.bold)
            case 2: // Dim
                state.currentAttributes.insert(.dim)
            case 3: // Italic
                state.currentAttributes.insert(.italic)
            case 4: // Underline
                state.currentAttributes.insert(.underline)
            case 5: // Blink
                state.currentAttributes.insert(.blink)
            case 7: // Inverse
                state.currentAttributes.insert(.inverse)
            case 8: // Hidden
                state.currentAttributes.insert(.hidden)
            case 9: // Strikethrough
                state.currentAttributes.insert(.strikethrough)
            case 22: // Normal intensity
                state.currentAttributes.remove(.bold)
                state.currentAttributes.remove(.dim)
            case 23: // Not italic
                state.currentAttributes.remove(.italic)
            case 24: // Not underlined
                state.currentAttributes.remove(.underline)
            case 25: // Not blinking
                state.currentAttributes.remove(.blink)
            case 27: // Not inverse
                state.currentAttributes.remove(.inverse)
            case 28: // Not hidden
                state.currentAttributes.remove(.hidden)
            case 29: // Not strikethrough
                state.currentAttributes.remove(.strikethrough)
            case 30...37: // Foreground color
                state.currentForeground = .ansi(UInt8(param - 30))
            case 38: // Extended foreground color
                i += 1
                if i < params.count {
                    let colorType = params[i]
                    if colorType == 5 && i + 1 < params.count { // 256-color
                        i += 1
                        state.currentForeground = .palette256(UInt8(params[i]))
                    } else if colorType == 2 && i + 3 < params.count { // RGB
                        let r = UInt8(params[i + 1])
                        let g = UInt8(params[i + 2])
                        let b = UInt8(params[i + 3])
                        state.currentForeground = .trueColor(r: r, g: g, b: b)
                        i += 3
                    }
                }
            case 39: // Default foreground
                state.currentForeground = .defaultForeground
            case 40...47: // Background color
                state.currentBackground = .ansi(UInt8(param - 40))
            case 48: // Extended background color
                i += 1
                if i < params.count {
                    let colorType = params[i]
                    if colorType == 5 && i + 1 < params.count { // 256-color
                        i += 1
                        state.currentBackground = .palette256(UInt8(params[i]))
                    } else if colorType == 2 && i + 3 < params.count { // RGB
                        let r = UInt8(params[i + 1])
                        let g = UInt8(params[i + 2])
                        let b = UInt8(params[i + 3])
                        state.currentBackground = .trueColor(r: r, g: g, b: b)
                        i += 3
                    }
                }
            case 49: // Default background
                state.currentBackground = .defaultBackground
            case 90...97: // Bright foreground colors
                state.currentForeground = .ansi(UInt8(param - 90 + 8))
            case 100...107: // Bright background colors
                state.currentBackground = .ansi(UInt8(param - 100 + 8))
            default:
                break
            }
            
            i += 1
        }
    }
    
    private func handleShellIntegration(_ data: String) {
        // Parse shell integration OSC sequences
        // Format: OSC 1337 ; key=value ST
        let parts = data.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { return }
        
        let key = String(parts[0])
        let value = String(parts[1])
        
        if state.shellIntegration == nil {
            state.shellIntegration = ShellIntegrationState()
        }
        
        switch key {
        case "CurrentDir":
            state.shellIntegration?.currentWorkingDirectory = value
        case "RemoteHost":
            // Handle remote host
            break
        default:
            break
        }
    }
}
