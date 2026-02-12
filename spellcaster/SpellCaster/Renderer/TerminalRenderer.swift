import AppKit
import CoreText

/// CoreText-based terminal renderer
class TerminalRenderer {
    // MARK: - Properties
    
    private let profile: Profile
    private var font: NSFont
    private var boldFont: NSFont
    private var italicFont: NSFont
    private var boldItalicFont: NSFont
    
    var cellSize: CGSize
    private var baseline: CGFloat
    
    // MARK: - Initialization
    
    init(profile: Profile) {
        self.profile = profile
        
        // Load fonts
        self.font = NSFont(name: profile.fontName, size: profile.fontSize) ?? 
                    NSFont.monospacedSystemFont(ofSize: profile.fontSize, weight: .regular)
        
        self.boldFont = NSFont(name: profile.fontName, size: profile.fontSize)?.bold ?? 
                        NSFont.monospacedSystemFont(ofSize: profile.fontSize, weight: .bold)
        
        self.italicFont = NSFont(name: profile.fontName, size: profile.fontSize)?.italic ?? 
                          NSFont.monospacedSystemFont(ofSize: profile.fontSize, weight: .regular)
        
        self.boldItalicFont = self.boldFont.italic ?? self.boldFont
        
        // Calculate cell size
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = ("M" as NSString).size(withAttributes: attributes)
        self.cellSize = CGSize(
            width: ceil(size.width),
            height: ceil(size.height * profile.lineSpacing)
        )
        
        // Calculate baseline
        self.baseline = font.ascender
    }
    
    // MARK: - Rendering
    
    func render(
        state: TerminalState,
        in rect: CGRect,
        context: CGContext,
        cursorVisible: Bool
    ) {
        let grid = state.activeGrid
        
        // Fill background
        context.setFillColor(profile.colorScheme.background.nsColor.cgColor)
        context.fill(rect)
        
        // Render cells
        for row in 0..<grid.rows {
            for col in 0..<grid.columns {
                let cell = grid[row, col]
                let cellRect = CGRect(
                    x: CGFloat(col) * cellSize.width,
                    y: rect.height - CGFloat(row + 1) * cellSize.height,
                    width: cellSize.width,
                    height: cellSize.height
                )
                
                renderCell(cell, at: cellRect, in: context)
            }
        }
        
        // Render cursor
        if cursorVisible {
            renderCursor(state: state, in: rect, context: context)
        }
    }
    
    private func renderCell(_ cell: TerminalCell, at rect: CGRect, in context: CGContext) {
        // Skip wide character continuations
        if cell.isWideContinuation {
            return
        }
        
        // Get colors
        var fg = resolveColor(cell.foregroundColor)
        var bg = resolveColor(cell.backgroundColor)
        
        // Handle inverse attribute
        if cell.attributes.contains(.inverse) {
            swap(&fg, &bg)
        }
        
        // Draw background
        if bg != profile.colorScheme.background.nsColor {
            context.setFillColor(bg.cgColor)
            context.fill(rect)
        }
        
        // Skip if hidden
        if cell.attributes.contains(.hidden) {
            return
        }
        
        // Select font
        var selectedFont = font
        if cell.attributes.contains(.bold) && cell.attributes.contains(.italic) {
            selectedFont = boldItalicFont
        } else if cell.attributes.contains(.bold) {
            selectedFont = boldFont
        } else if cell.attributes.contains(.italic) {
            selectedFont = italicFont
        }
        
        // Create attributed string
        let char = String(Character(cell.character))
        var attributes: [NSAttributedString.Key: Any] = [
            .font: selectedFont,
            .foregroundColor: fg
        ]
        
        // Add underline
        if cell.attributes.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        // Add strikethrough
        if cell.attributes.contains(.strikethrough) {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        
        let attrString = NSAttributedString(string: char, attributes: attributes)
        
        // Draw text
        let textRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + (cellSize.height - baseline) / 2,
            width: rect.width,
            height: rect.height
        )
        attrString.draw(in: textRect)
    }
    
    private func renderCursor(state: TerminalState, in rect: CGRect, context: CGContext) {
        let cursorRect = CGRect(
            x: CGFloat(state.cursorColumn) * cellSize.width,
            y: rect.height - CGFloat(state.cursorRow + 1) * cellSize.height,
            width: cellSize.width,
            height: cellSize.height
        )
        
        context.setFillColor(profile.colorScheme.cursor.nsColor.cgColor)
        
        switch state.cursorStyle {
        case .block:
            context.fill(cursorRect)
        case .underline:
            let underlineRect = CGRect(
                x: cursorRect.origin.x,
                y: cursorRect.origin.y,
                width: cursorRect.width,
                height: 2
            )
            context.fill(underlineRect)
        case .bar:
            let barRect = CGRect(
                x: cursorRect.origin.x,
                y: cursorRect.origin.y,
                width: 2,
                height: cursorRect.height
            )
            context.fill(barRect)
        }
    }
    
    func renderSelection(_ selection: Selection, in rect: CGRect, context: CGContext) {
        context.setFillColor(profile.colorScheme.selection.nsColor.cgColor)
        
        for row in selection.start.row...selection.end.row {
            let startCol = (row == selection.start.row) ? selection.start.col : 0
            let endCol = (row == selection.end.row) ? selection.end.col : Int(rect.width / cellSize.width) - 1
            
            let selectionRect = CGRect(
                x: CGFloat(startCol) * cellSize.width,
                y: rect.height - CGFloat(row + 1) * cellSize.height,
                width: CGFloat(endCol - startCol + 1) * cellSize.width,
                height: cellSize.height
            )
            
            context.fill(selectionRect)
        }
    }
    
    // MARK: - Color Resolution
    
    private func resolveColor(_ color: TerminalColor) -> NSColor {
        switch color {
        case .defaultForeground:
            return profile.colorScheme.foreground.nsColor
        case .defaultBackground:
            return profile.colorScheme.background.nsColor
        case .ansi(let index):
            return profile.colorScheme.ansiColor(index: index).nsColor
        case .palette256(let index):
            return palette256Color(index: index)
        case .trueColor(let r, let g, let b):
            return NSColor(
                red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: 1.0
            )
        }
    }
    
    private func palette256Color(index: UInt8) -> NSColor {
        // 0-15: ANSI colors
        if index < 16 {
            return profile.colorScheme.ansiColor(index: index).nsColor
        }
        
        // 16-231: 6x6x6 color cube
        if index >= 16 && index < 232 {
            let i = Int(index) - 16
            let r = (i / 36) * 51
            let g = ((i % 36) / 6) * 51
            let b = (i % 6) * 51
            return NSColor(
                red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: 1.0
            )
        }
        
        // 232-255: Grayscale
        let gray = Int(index - 232) * 10 + 8
        return NSColor(
            red: CGFloat(gray) / 255.0,
            green: CGFloat(gray) / 255.0,
            blue: CGFloat(gray) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - Font Extensions

extension NSFont {
    var bold: NSFont? {
        return NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask)
    }
    
    var italic: NSFont? {
        return NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)
    }
}
