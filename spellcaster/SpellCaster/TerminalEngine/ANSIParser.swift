import Foundation

/// ANSI/VT100/xterm escape sequence parser
class ANSIParser {
    // MARK: - Parser State
    
    private var state: ParserState = .ground
    private var params: [Int] = []
    private var intermediates: [UInt8] = []
    private var oscString: String = ""
    
    // MARK: - Callbacks
    
    var onPrint: ((UnicodeScalar) -> Void)?
    var onExecute: ((UInt8) -> Void)?
    var onCSI: (([Int], [UInt8], UInt8) -> Void)?
    var onOSC: ((String) -> Void)?
    var onESC: (([UInt8], UInt8) -> Void)?
    
    // MARK: - Parsing
    
    func parse(_ data: Data) {
        for byte in data {
            processByte(byte)
        }
    }
    
    private func processByte(_ byte: UInt8) {
        switch state {
        case .ground:
            processGround(byte)
        case .escape:
            processEscape(byte)
        case .escapeIntermediate:
            processEscapeIntermediate(byte)
        case .csiEntry:
            processCSIEntry(byte)
        case .csiParam:
            processCSIParam(byte)
        case .csiIntermediate:
            processCSIIntermediate(byte)
        case .oscString:
            processOSCString(byte)
        }
    }
    
    // MARK: - State Processors
    
    private func processGround(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            // C0 control characters
            onExecute?(byte)
        case 0x1B:
            // ESC
            state = .escape
            params.removeAll()
            intermediates.removeAll()
        case 0x20...0x7E:
            // Printable ASCII
            if let scalar = UnicodeScalar(byte) {
                onPrint?(scalar)
            }
        case 0x7F:
            // DEL - ignore
            break
        case 0x80...0xFF:
            // UTF-8 continuation or high bytes
            if let scalar = UnicodeScalar(byte) {
                onPrint?(scalar)
            }
        default:
            break
        }
    }
    
    private func processEscape(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            onExecute?(byte)
        case 0x20...0x2F:
            // Intermediate bytes
            intermediates.append(byte)
            state = .escapeIntermediate
        case 0x30...0x4F, 0x51...0x57, 0x59, 0x5A, 0x5C, 0x60...0x7E:
            // Final byte
            dispatchESC(byte)
            state = .ground
        case 0x5B:
            // CSI
            state = .csiEntry
        case 0x5D:
            // OSC
            state = .oscString
            oscString = ""
        case 0x50, 0x58, 0x5E, 0x5F:
            // DCS, SOS, PM, APC - not implemented, return to ground
            state = .ground
        case 0x7F:
            // Ignore
            break
        default:
            state = .ground
        }
    }
    
    private func processEscapeIntermediate(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            onExecute?(byte)
        case 0x20...0x2F:
            intermediates.append(byte)
        case 0x30...0x7E:
            dispatchESC(byte)
            state = .ground
        case 0x7F:
            // Ignore
            break
        default:
            state = .ground
        }
    }
    
    private func processCSIEntry(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            onExecute?(byte)
        case 0x20...0x2F:
            intermediates.append(byte)
            state = .csiIntermediate
        case 0x30...0x39, 0x3B:
            // Parameter bytes
            params.append(0)
            state = .csiParam
            processCSIParam(byte)
        case 0x3A:
            // Colon - ignore for now
            state = .csiParam
        case 0x3C...0x3F:
            // Private markers
            intermediates.append(byte)
            state = .csiParam
        case 0x40...0x7E:
            // Final byte
            dispatchCSI(byte)
            state = .ground
        case 0x7F:
            // Ignore
            break
        default:
            state = .ground
        }
    }
    
    private func processCSIParam(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            onExecute?(byte)
        case 0x20...0x2F:
            intermediates.append(byte)
            state = .csiIntermediate
        case 0x30...0x39:
            // Digit
            if params.isEmpty {
                params.append(0)
            }
            let digit = Int(byte - 0x30)
            params[params.count - 1] = params[params.count - 1] * 10 + digit
        case 0x3A:
            // Colon - ignore for now
            break
        case 0x3B:
            // Semicolon - parameter separator
            params.append(0)
        case 0x3C...0x3F:
            // Invalid in param state
            state = .ground
        case 0x40...0x7E:
            // Final byte
            dispatchCSI(byte)
            state = .ground
        case 0x7F:
            // Ignore
            break
        default:
            state = .ground
        }
    }
    
    private func processCSIIntermediate(_ byte: UInt8) {
        switch byte {
        case 0x00...0x17, 0x19, 0x1C...0x1F:
            onExecute?(byte)
        case 0x20...0x2F:
            intermediates.append(byte)
        case 0x30...0x3F:
            // Invalid
            state = .ground
        case 0x40...0x7E:
            // Final byte
            dispatchCSI(byte)
            state = .ground
        case 0x7F:
            // Ignore
            break
        default:
            state = .ground
        }
    }
    
    private func processOSCString(_ byte: UInt8) {
        switch byte {
        case 0x07:
            // BEL - end of OSC
            dispatchOSC()
            state = .ground
        case 0x1B:
            // ESC - might be ESC \ (ST)
            if let next = peekNextByte(), next == 0x5C {
                // ESC \ - end of OSC
                dispatchOSC()
                state = .ground
            } else {
                oscString.append(Character(UnicodeScalar(byte)))
            }
        case 0x20...0x7E:
            oscString.append(Character(UnicodeScalar(byte)))
        default:
            // Ignore other bytes
            break
        }
    }
    
    // MARK: - Dispatch
    
    private func dispatchCSI(_ final: UInt8) {
        onCSI?(params, intermediates, final)
        params.removeAll()
        intermediates.removeAll()
    }
    
    private func dispatchESC(_ final: UInt8) {
        onESC?(intermediates, final)
        intermediates.removeAll()
    }
    
    private func dispatchOSC() {
        onOSC?(oscString)
        oscString = ""
    }
    
    // MARK: - Helper
    
    private func peekNextByte() -> UInt8? {
        // This is a simplified implementation
        // In a real parser, you'd need to peek ahead in the input stream
        return nil
    }
}

// MARK: - Parser State

private enum ParserState {
    case ground
    case escape
    case escapeIntermediate
    case csiEntry
    case csiParam
    case csiIntermediate
    case oscString
}
