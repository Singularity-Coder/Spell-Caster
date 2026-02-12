import AppKit
import Carbon

/// Converts NSEvent key events to terminal escape sequences
struct TerminalInput {
    /// Convert a key event to terminal input data
    static func encode(event: NSEvent, applicationCursorKeys: Bool = false, applicationKeypad: Bool = false) -> Data? {
        guard event.type == .keyDown else { return nil }
        
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        let characters = event.characters ?? ""
        
        // Handle special keys
        if let specialSequence = encodeSpecialKey(
            keyCode: keyCode,
            modifiers: modifiers,
            applicationCursorKeys: applicationCursorKeys,
            applicationKeypad: applicationKeypad
        ) {
            return specialSequence.data(using: .utf8)
        }
        
        // Handle modified keys
        if modifiers.contains(.control) && !characters.isEmpty {
            return encodeControlKey(characters: characters)
        }
        
        // Handle alt/option keys
        if modifiers.contains(.option) && !characters.isEmpty {
            return encodeAltKey(characters: characters)
        }
        
        // Regular character input
        return characters.data(using: .utf8)
    }
    
    // MARK: - Special Keys
    
    private static func encodeSpecialKey(
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags,
        applicationCursorKeys: Bool,
        applicationKeypad: Bool
    ) -> String? {
        switch Int(keyCode) {
        // Arrow keys
        case kVK_UpArrow:
            return applicationCursorKeys ? "\u{1B}OA" : "\u{1B}[A"
        case kVK_DownArrow:
            return applicationCursorKeys ? "\u{1B}OB" : "\u{1B}[B"
        case kVK_RightArrow:
            return applicationCursorKeys ? "\u{1B}OC" : "\u{1B}[C"
        case kVK_LeftArrow:
            return applicationCursorKeys ? "\u{1B}OD" : "\u{1B}[D"
            
        // Function keys
        case kVK_F1:
            return "\u{1B}OP"
        case kVK_F2:
            return "\u{1B}OQ"
        case kVK_F3:
            return "\u{1B}OR"
        case kVK_F4:
            return "\u{1B}OS"
        case kVK_F5:
            return "\u{1B}[15~"
        case kVK_F6:
            return "\u{1B}[17~"
        case kVK_F7:
            return "\u{1B}[18~"
        case kVK_F8:
            return "\u{1B}[19~"
        case kVK_F9:
            return "\u{1B}[20~"
        case kVK_F10:
            return "\u{1B}[21~"
        case kVK_F11:
            return "\u{1B}[23~"
        case kVK_F12:
            return "\u{1B}[24~"
            
        // Editing keys
        case kVK_Home:
            return applicationCursorKeys ? "\u{1B}OH" : "\u{1B}[H"
        case kVK_End:
            return applicationCursorKeys ? "\u{1B}OF" : "\u{1B}[F"
        case kVK_PageUp:
            return "\u{1B}[5~"
        case kVK_PageDown:
            return "\u{1B}[6~"
        case kVK_ForwardDelete:
            return "\u{1B}[3~"
        case kVK_Delete:
            return "\u{7F}" // DEL
            
        // Keypad (application mode)
        case kVK_ANSI_KeypadEnter:
            return applicationKeypad ? "\u{1B}OM" : "\r"
        case kVK_ANSI_KeypadMultiply:
            return applicationKeypad ? "\u{1B}Oj" : "*"
        case kVK_ANSI_KeypadPlus:
            return applicationKeypad ? "\u{1B}Ok" : "+"
        case kVK_ANSI_KeypadMinus:
            return applicationKeypad ? "\u{1B}Om" : "-"
        case kVK_ANSI_KeypadDivide:
            return applicationKeypad ? "\u{1B}Oo" : "/"
        case kVK_ANSI_KeypadEquals:
            return applicationKeypad ? "\u{1B}OX" : "="
        case kVK_ANSI_Keypad0:
            return applicationKeypad ? "\u{1B}Op" : "0"
        case kVK_ANSI_Keypad1:
            return applicationKeypad ? "\u{1B}Oq" : "1"
        case kVK_ANSI_Keypad2:
            return applicationKeypad ? "\u{1B}Or" : "2"
        case kVK_ANSI_Keypad3:
            return applicationKeypad ? "\u{1B}Os" : "3"
        case kVK_ANSI_Keypad4:
            return applicationKeypad ? "\u{1B}Ot" : "4"
        case kVK_ANSI_Keypad5:
            return applicationKeypad ? "\u{1B}Ou" : "5"
        case kVK_ANSI_Keypad6:
            return applicationKeypad ? "\u{1B}Ov" : "6"
        case kVK_ANSI_Keypad7:
            return applicationKeypad ? "\u{1B}Ow" : "7"
        case kVK_ANSI_Keypad8:
            return applicationKeypad ? "\u{1B}Ox" : "8"
        case kVK_ANSI_Keypad9:
            return applicationKeypad ? "\u{1B}Oy" : "9"
        case kVK_ANSI_KeypadDecimal:
            return applicationKeypad ? "\u{1B}On" : "."
            
        // Tab
        case kVK_Tab:
            if modifiers.contains(.shift) {
                return "\u{1B}[Z" // Backtab
            }
            return "\t"
            
        // Return
        case kVK_Return:
            return "\r"
            
        // Escape
        case kVK_Escape:
            return "\u{1B}"
            
        default:
            return nil
        }
    }
    
    // MARK: - Control Keys
    
    private static func encodeControlKey(characters: String) -> Data? {
        guard let first = characters.first else { return nil }
        
        // Control + letter produces ASCII control codes
        if first.isLetter {
            let upper = first.uppercased().first!
            let code = upper.asciiValue! - 64 // A=1, B=2, etc.
            return Data([code])
        }
        
        // Special control combinations
        switch first {
        case " ":
            return Data([0x00]) // Ctrl+Space = NUL
        case "[":
            return Data([0x1B]) // Ctrl+[ = ESC
        case "\\":
            return Data([0x1C]) // Ctrl+\ = FS
        case "]":
            return Data([0x1D]) // Ctrl+] = GS
        case "^":
            return Data([0x1E]) // Ctrl+^ = RS
        case "_":
            return Data([0x1F]) // Ctrl+_ = US
        case "?":
            return Data([0x7F]) // Ctrl+? = DEL
        default:
            return characters.data(using: .utf8)
        }
    }
    
    // MARK: - Alt/Option Keys
    
    private static func encodeAltKey(characters: String) -> Data? {
        // Alt/Option sends ESC prefix
        guard let data = characters.data(using: .utf8) else { return nil }
        var result = Data([0x1B]) // ESC
        result.append(data)
        return result
    }
    
    // MARK: - Bracketed Paste
    
    static func encodeBracketedPaste(_ text: String) -> Data? {
        var result = "\u{1B}[200~" // Start bracketed paste
        result += text
        result += "\u{1B}[201~" // End bracketed paste
        return result.data(using: .utf8)
    }
}
