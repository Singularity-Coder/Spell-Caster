import Foundation
import AppKit

/// Terminal profile containing appearance and behavior settings
struct Profile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    
    // MARK: - Font Settings
    
    var fontName: String
    var fontSize: CGFloat
    var fontLigatures: Bool
    var lineSpacing: CGFloat
    
    // MARK: - Color Scheme
    
    var colorScheme: ColorScheme
    
    // MARK: - Cursor Settings
    
    var cursorStyle: CursorStyleSetting
    var cursorBlink: Bool
    var cursorBlinkInterval: TimeInterval
    
    // MARK: - Shell Settings
    
    var shellPath: String
    var shellArguments: [String]
    var environmentVariables: [String: String]
    var workingDirectory: String?
    
    // MARK: - Scrollback Settings
    
    var scrollbackLimit: Int
    var scrollbackUnlimited: Bool
    
    // MARK: - Behavior Settings
    
    var audibleBell: Bool
    var visualBell: Bool
    var closeOnExit: Bool
    var confirmBeforeClosing: Bool
    
    // MARK: - AI Settings
    
    var aiProvider: String
    var aiModel: String
    var aiSystemPromptPreset: String
    var aiAutoContextCapture: Bool
    var aiIncludeScrollback: Bool
    var aiIncludeEnvironment: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String = "Default",
        fontName: String = "SF Mono",
        fontSize: CGFloat = 13,
        fontLigatures: Bool = true,
        lineSpacing: CGFloat = 1.2,
        colorScheme: ColorScheme = .default,
        cursorStyle: CursorStyleSetting = .block,
        cursorBlink: Bool = true,
        cursorBlinkInterval: TimeInterval = 0.5,
        shellPath: String = "/bin/zsh",
        shellArguments: [String] = ["-l"],
        environmentVariables: [String: String] = [:],
        workingDirectory: String? = nil,
        scrollbackLimit: Int = 10000,
        scrollbackUnlimited: Bool = false,
        audibleBell: Bool = false,
        visualBell: Bool = true,
        closeOnExit: Bool = true,
        confirmBeforeClosing: Bool = false,
        aiProvider: String = "openai",
        aiModel: String = "gpt-4",
        aiSystemPromptPreset: String = "shell-assistant",
        aiAutoContextCapture: Bool = true,
        aiIncludeScrollback: Bool = true,
        aiIncludeEnvironment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontLigatures = fontLigatures
        self.lineSpacing = lineSpacing
        self.colorScheme = colorScheme
        self.cursorStyle = cursorStyle
        self.cursorBlink = cursorBlink
        self.cursorBlinkInterval = cursorBlinkInterval
        self.shellPath = shellPath
        self.shellArguments = shellArguments
        self.environmentVariables = environmentVariables
        self.workingDirectory = workingDirectory
        self.scrollbackLimit = scrollbackLimit
        self.scrollbackUnlimited = scrollbackUnlimited
        self.audibleBell = audibleBell
        self.visualBell = visualBell
        self.closeOnExit = closeOnExit
        self.confirmBeforeClosing = confirmBeforeClosing
        self.aiProvider = aiProvider
        self.aiModel = aiModel
        self.aiSystemPromptPreset = aiSystemPromptPreset
        self.aiAutoContextCapture = aiAutoContextCapture
        self.aiIncludeScrollback = aiIncludeScrollback
        self.aiIncludeEnvironment = aiIncludeEnvironment
    }
    
    /// Default profile
    static let `default` = Profile()
}

// MARK: - Color Scheme

struct ColorScheme: Codable, Equatable {
    // MARK: - Standard ANSI Colors (0-7)
    
    var black: RGBColor
    var red: RGBColor
    var green: RGBColor
    var yellow: RGBColor
    var blue: RGBColor
    var magenta: RGBColor
    var cyan: RGBColor
    var white: RGBColor
    
    // MARK: - Bright ANSI Colors (8-15)
    
    var brightBlack: RGBColor
    var brightRed: RGBColor
    var brightGreen: RGBColor
    var brightYellow: RGBColor
    var brightBlue: RGBColor
    var brightMagenta: RGBColor
    var brightCyan: RGBColor
    var brightWhite: RGBColor
    
    // MARK: - Special Colors
    
    var foreground: RGBColor
    var background: RGBColor
    var cursor: RGBColor
    var cursorText: RGBColor
    var selection: RGBColor
    var selectionText: RGBColor?
    
    // MARK: - Initialization
    
    init(
        black: RGBColor = RGBColor(r: 0, g: 0, b: 0),
        red: RGBColor = RGBColor(r: 205, g: 49, b: 49),
        green: RGBColor = RGBColor(r: 13, g: 188, b: 121),
        yellow: RGBColor = RGBColor(r: 229, g: 229, b: 16),
        blue: RGBColor = RGBColor(r: 36, g: 114, b: 200),
        magenta: RGBColor = RGBColor(r: 188, g: 63, b: 188),
        cyan: RGBColor = RGBColor(r: 17, g: 168, b: 205),
        white: RGBColor = RGBColor(r: 229, g: 229, b: 229),
        brightBlack: RGBColor = RGBColor(r: 102, g: 102, b: 102),
        brightRed: RGBColor = RGBColor(r: 241, g: 76, b: 76),
        brightGreen: RGBColor = RGBColor(r: 35, g: 209, b: 139),
        brightYellow: RGBColor = RGBColor(r: 245, g: 245, b: 67),
        brightBlue: RGBColor = RGBColor(r: 59, g: 142, b: 234),
        brightMagenta: RGBColor = RGBColor(r: 214, g: 112, b: 214),
        brightCyan: RGBColor = RGBColor(r: 41, g: 184, b: 219),
        brightWhite: RGBColor = RGBColor(r: 255, g: 255, b: 255),
        foreground: RGBColor = RGBColor(r: 229, g: 229, b: 229),
        background: RGBColor = RGBColor(r: 0, g: 0, b: 0),
        cursor: RGBColor = RGBColor(r: 229, g: 229, b: 229),
        cursorText: RGBColor = RGBColor(r: 0, g: 0, b: 0),
        selection: RGBColor = RGBColor(r: 178, g: 215, b: 255, a: 0.3),
        selectionText: RGBColor? = nil
    ) {
        self.black = black
        self.red = red
        self.green = green
        self.yellow = yellow
        self.blue = blue
        self.magenta = magenta
        self.cyan = cyan
        self.white = white
        self.brightBlack = brightBlack
        self.brightRed = brightRed
        self.brightGreen = brightGreen
        self.brightYellow = brightYellow
        self.brightBlue = brightBlue
        self.brightMagenta = brightMagenta
        self.brightCyan = brightCyan
        self.brightWhite = brightWhite
        self.foreground = foreground
        self.background = background
        self.cursor = cursor
        self.cursorText = cursorText
        self.selection = selection
        self.selectionText = selectionText
    }
    
    /// Get ANSI color by index (0-15)
    func ansiColor(index: UInt8) -> RGBColor {
        switch index {
        case 0: return black
        case 1: return red
        case 2: return green
        case 3: return yellow
        case 4: return blue
        case 5: return magenta
        case 6: return cyan
        case 7: return white
        case 8: return brightBlack
        case 9: return brightRed
        case 10: return brightGreen
        case 11: return brightYellow
        case 12: return brightBlue
        case 13: return brightMagenta
        case 14: return brightCyan
        case 15: return brightWhite
        default: return foreground
        }
    }
    
    /// Default color scheme
    static let `default` = ColorScheme()
}

// MARK: - RGB Color

struct RGBColor: Codable, Equatable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: CGFloat
    
    init(r: UInt8, g: UInt8, b: UInt8, a: CGFloat = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    /// Convert to NSColor
    var nsColor: NSColor {
        return NSColor(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: a
        )
    }
    
    /// Create from NSColor
    init(nsColor: NSColor) {
        let rgb = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        self.r = UInt8(rgb.redComponent * 255)
        self.g = UInt8(rgb.greenComponent * 255)
        self.b = UInt8(rgb.blueComponent * 255)
        self.a = rgb.alphaComponent
    }
}

// MARK: - Cursor Style Setting

enum CursorStyleSetting: String, Codable {
    case block
    case underline
    case bar
}
