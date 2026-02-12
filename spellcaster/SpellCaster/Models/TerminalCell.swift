import Foundation

/// Represents a single cell in the terminal grid
struct TerminalCell: Equatable {
    /// The character stored in this cell (Unicode scalar)
    var character: UnicodeScalar
    
    /// Foreground color (supports 256-color palette and truecolor)
    var foregroundColor: TerminalColor
    
    /// Background color (supports 256-color palette and truecolor)
    var backgroundColor: TerminalColor
    
    /// Text attributes (bold, italic, underline, etc.)
    var attributes: CellAttributes
    
    /// Whether this cell is part of a wide character (CJK, emoji, etc.)
    var isWide: Bool
    
    /// Whether this cell is the continuation of a wide character
    var isWideContinuation: Bool
    
    /// Hyperlink ID (for OSC 8 hyperlinks)
    var hyperlinkID: String?
    
    init(
        character: UnicodeScalar = " ",
        foregroundColor: TerminalColor = .defaultForeground,
        backgroundColor: TerminalColor = .defaultBackground,
        attributes: CellAttributes = CellAttributes(),
        isWide: Bool = false,
        isWideContinuation: Bool = false,
        hyperlinkID: String? = nil
    ) {
        self.character = character
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.attributes = attributes
        self.isWide = isWide
        self.isWideContinuation = isWideContinuation
        self.hyperlinkID = hyperlinkID
    }
    
    /// Returns a blank cell with default colors
    static var blank: TerminalCell {
        return TerminalCell()
    }
}

/// Terminal color representation supporting multiple color modes
enum TerminalColor: Equatable, Codable {
    case defaultForeground
    case defaultBackground
    case ansi(UInt8)           // 0-15: standard ANSI colors
    case palette256(UInt8)     // 0-255: 256-color palette
    case trueColor(r: UInt8, g: UInt8, b: UInt8)  // 24-bit RGB
    
    /// Standard ANSI color indices
    static let black = TerminalColor.ansi(0)
    static let red = TerminalColor.ansi(1)
    static let green = TerminalColor.ansi(2)
    static let yellow = TerminalColor.ansi(3)
    static let blue = TerminalColor.ansi(4)
    static let magenta = TerminalColor.ansi(5)
    static let cyan = TerminalColor.ansi(6)
    static let white = TerminalColor.ansi(7)
    static let brightBlack = TerminalColor.ansi(8)
    static let brightRed = TerminalColor.ansi(9)
    static let brightGreen = TerminalColor.ansi(10)
    static let brightYellow = TerminalColor.ansi(11)
    static let brightBlue = TerminalColor.ansi(12)
    static let brightMagenta = TerminalColor.ansi(13)
    static let brightCyan = TerminalColor.ansi(14)
    static let brightWhite = TerminalColor.ansi(15)
}

/// Cell text attributes
struct CellAttributes: OptionSet, Equatable, Codable {
    let rawValue: UInt16
    
    static let bold          = CellAttributes(rawValue: 1 << 0)
    static let dim           = CellAttributes(rawValue: 1 << 1)
    static let italic        = CellAttributes(rawValue: 1 << 2)
    static let underline     = CellAttributes(rawValue: 1 << 3)
    static let blink         = CellAttributes(rawValue: 1 << 4)
    static let inverse       = CellAttributes(rawValue: 1 << 5)
    static let hidden        = CellAttributes(rawValue: 1 << 6)
    static let strikethrough = CellAttributes(rawValue: 1 << 7)
    static let doubleUnderline = CellAttributes(rawValue: 1 << 8)
    static let curlyUnderline  = CellAttributes(rawValue: 1 << 9)
    static let dottedUnderline = CellAttributes(rawValue: 1 << 10)
    static let dashedUnderline = CellAttributes(rawValue: 1 << 11)
    
    init(rawValue: UInt16 = 0) {
        self.rawValue = rawValue
    }
}
