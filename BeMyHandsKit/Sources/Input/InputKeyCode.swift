/// Window server tap event key codes for US ANSI keyboards.
public enum InputKeyCode: Int64, Codable, Hashable {
    case keyboardA = 0x0
    case keyboardB = 0xb
    case keyboardC = 0x8
    case keyboardD = 0x2
    case keyboardE = 0xe
    case keyboardF = 0x3
    case keyboardG = 0x5
    case keyboardH = 0x4
    case keyboardI = 0x22
    case keyboardJ = 0x26
    case keyboardK = 0x28
    case keyboardL = 0x25
    case keyboardM = 0x2e
    case keyboardN = 0x2d
    case keyboardO = 0x1f
    case keyboardP = 0x23
    case keyboardQ = 0xc
    case keyboardR = 0xf
    case keyboardS = 0x1
    case keyboardT = 0x11
    case keyboardU = 0x20
    case keyboardV = 0x9
    case keyboardW = 0xd
    case keyboardX = 0x7
    case keyboardY = 0x10
    case keyboardZ = 0x6
    case keyboard1AndExclamation = 0x12
    case keyboard2AndAtt = 0x13
    case keyboard3AndHash = 0x14
    case keyboard4AndDollar = 0x15
    case keyboard5AndPercent = 0x17
    case keyboard6AndCaret = 0x16
    case keyboard7AndAmp = 0x1a
    case keyboard8AndStar = 0x1c
    case keyboard9AndLeftParen = 0x19
    case keyboard0AndRightParen = 0x1d
    case keyboardReturn = 0x24
    case keyboardEscape = 0x35
    case keyboardBackDelete = 0x33
    case keyboardTab = 0x30
    case keyboardSpace = 0x31
    case keyboardMinusAndUnderscore = 0x1b
    case keyboardEqualsAndPlus = 0x18
    case keyboardLeftBracketAndBrace = 0x21
    case keyboardRightBracketAndBrace = 0x1e
    case keyboardBackSlashAndVertical = 0x2a
    case keyboardSemiColonAndColon = 0x29
    case keyboardApostropheAndQuote = 0x27
    case keyboardGraveAccentAndTilde = 0x32
    case keyboardCommaAndLeftAngle = 0x2b
    case keyboardPeriodAndRightAngle = 0x2f
    case keyboardSlashAndQuestion = 0x2c
    case keyboardF1 = 0x7a
    case keyboardF2 = 0x78
    case keyboardF3 = 0x63
    case keyboardF4 = 0x76
    case keyboardF5 = 0x60
    case keyboardF6 = 0x61
    case keyboardF7 = 0x62
    case keyboardF8 = 0x64
    case keyboardF9 = 0x65
    case keyboardF10 = 0x6d
    case keyboardF11 = 0x67
    case keyboardF12 = 0x6f
    case keyboardHome = 0x73
    case keyboardPageUp = 0x74
    case keyboardDelete = 0x75
    case keyboardEnd = 0x77
    case keyboardPageDown = 0x79
    case keyboardLeftArrow = 0x7b
    case keyboardRightArrow = 0x7c
    case keyboardDownArrow = 0x7d
    case keyboardUpArrow = 0x7e
    case keypadNumLock = 0x47
    case keypadDivide = 0x4b
    case keypadMultiply = 0x43
    case keypadSubtract = 0x4e
    case keypadAdd = 0x45
    case keypadEnter = 0x4c
    case keypad1AndEnd = 0x53
    case keypad2AndDownArrow = 0x54
    case keypad3AndPageDown = 0x55
    case keypad4AndLeftArrow = 0x56
    case keypad5 = 0x57
    case keypad6AndRightArrow = 0x58
    case keypad7AndHome = 0x59
    case keypad8AndUpArrow = 0x5b
    case keypad9AndPageUp = 0x5c
    case keypad0 = 0x52
    case keypadDecimalAndDelete = 0x41
    case keypadEquals = 0x51
    case keyboardF13 = 0x69
    case keyboardF14 = 0x6b
    case keyboardF15 = 0x71
    case keyboardF16 = 0x6a
    case keyboardF17 = 0x40
    case keyboardF18 = 0x4f
    case keyboardF19 = 0x50
    case keyboardF20 = 0x5a
    case keyboardVolumeUp = 0x48
    case keyboardVolumeDown = 0x49
    case keyboardVolumeMute = 0x4a
    case keyboardHelp = 0x72

    /// Description of the key code.
    public var description: String {
        switch self {
        case .keyboardA: "A"
        case .keyboardB: "B"
        case .keyboardC: "C"
        case .keyboardD: "D"
        case .keyboardE: "E"
        case .keyboardF: "F"
        case .keyboardG: "G"
        case .keyboardH: "H"
        case .keyboardI: "I"
        case .keyboardJ: "J"
        case .keyboardK: "K"
        case .keyboardL: "L"
        case .keyboardM: "M"
        case .keyboardN: "N"
        case .keyboardO: "O"
        case .keyboardP: "P"
        case .keyboardQ: "Q"
        case .keyboardR: "R"
        case .keyboardS: "S"
        case .keyboardT: "T"
        case .keyboardU: "U"
        case .keyboardV: "V"
        case .keyboardW: "W"
        case .keyboardX: "X"
        case .keyboardY: "Y"
        case .keyboardZ: "Z"
        case .keyboard1AndExclamation: "1"
        case .keyboard2AndAtt: "2"
        case .keyboard3AndHash: "3"
        case .keyboard4AndDollar: "4"
        case .keyboard5AndPercent: "5"
        case .keyboard6AndCaret: "6"
        case .keyboard7AndAmp: "7"
        case .keyboard8AndStar: "8"
        case .keyboard9AndLeftParen: "9"
        case .keyboard0AndRightParen: "0"
        case .keyboardReturn: "Return"
        case .keyboardEscape: "Escape"
        case .keyboardBackDelete: "Backspace"
        case .keyboardTab: "Tab"
        case .keyboardSpace: "Space"
        case .keyboardMinusAndUnderscore: "Minus"
        case .keyboardEqualsAndPlus: "Equals"
        case .keyboardLeftBracketAndBrace: "Left Bracket"
        case .keyboardRightBracketAndBrace: "Right Bracket"
        case .keyboardBackSlashAndVertical: "Backslash"
        case .keyboardSemiColonAndColon: "Semicolon"
        case .keyboardApostropheAndQuote: "Apostrophe"
        case .keyboardGraveAccentAndTilde: "Grave Accent"
        case .keyboardCommaAndLeftAngle: "Comma"
        case .keyboardPeriodAndRightAngle: "Period"
        case .keyboardSlashAndQuestion: "Slash"
        case .keyboardF1: "F1"
        case .keyboardF2: "F2"
        case .keyboardF3: "F3"
        case .keyboardF4: "F4"
        case .keyboardF5: "F5"
        case .keyboardF6: "F6"
        case .keyboardF7: "F7"
        case .keyboardF8: "F8"
        case .keyboardF9: "F9"
        case .keyboardF10: "F10"
        case .keyboardF11: "F11"
        case .keyboardF12: "F12"
        case .keyboardHome: "Home"
        case .keyboardPageUp: "Page Up"
        case .keyboardDelete: "Delete"
        case .keyboardEnd: "End"
        case .keyboardPageDown: "Page Down"
        case .keyboardLeftArrow: "Left Arrow"
        case .keyboardRightArrow: "Right Arrow"
        case .keyboardDownArrow: "Down Arrow"
        case .keyboardUpArrow: "Up Arrow"
        case .keypadNumLock: "Num Lock"
        case .keypadDivide: "Keypad /"
        case .keypadMultiply: "Keypad *"
        case .keypadSubtract: "Keypad -"
        case .keypadAdd: "Keypad +"
        case .keypadEnter: "Keypad Enter"
        case .keypad1AndEnd: "Keypad 1"
        case .keypad2AndDownArrow: "Keypad 2"
        case .keypad3AndPageDown: "Keypad 3"
        case .keypad4AndLeftArrow: "Keypad 4"
        case .keypad5: "Keypad 5"
        case .keypad6AndRightArrow: "Keypad 6"
        case .keypad7AndHome: "Keypad 7"
        case .keypad8AndUpArrow: "Keypad 8"
        case .keypad9AndPageUp: "Keypad 9"
        case .keypad0: "Keypad 0"
        case .keypadDecimalAndDelete: "Keypad Decimal"
        case .keypadEquals: "Keypad ="
        case .keyboardF13: "F13"
        case .keyboardF14: "F14"
        case .keyboardF15: "F15"
        case .keyboardF16: "F16"
        case .keyboardF17: "F17"
        case .keyboardF18: "F18"
        case .keyboardF19: "F19"
        case .keyboardF20: "F20"
        case .keyboardVolumeUp: "Volume Up"
        case .keyboardVolumeDown: "Volume Down"
        case .keyboardVolumeMute: "Volume Mute"
        case .keyboardHelp: "Help"
        }
    }

    /// Symbol representations of the key code, such as `delete.left` for `Backspace` and `Delete` for
    /// codes that have it.
    var symbol: String? {
        switch self {
        case .keyboardReturn: return "return"
        case .keyboardEscape: return "escape"
        case .keyboardBackDelete: return "delete.left"
        case .keyboardTab: return "arrow.right.to.line"
        case .keyboardSpace: return "space"
        case .keyboardDelete: return "delete.right"
        case .keyboardHome: return "house"
        case .keyboardPageUp: return "arrow.up.doc"
        case .keyboardEnd: return "arrow.right.to.line"
        case .keyboardPageDown: return "arrow.down.doc"
        case .keyboardLeftArrow: return "arrow.left"
        case .keyboardRightArrow: return "arrow.right"
        case .keyboardDownArrow: return "arrow.down"
        case .keyboardUpArrow: return "arrow.up"
        case .keypadNumLock: return "number"
        case .keypadDivide: return "divide"
        case .keypadMultiply: return "multiply"
        case .keypadSubtract: return "minus"
        case .keypadAdd: return "plus"
        case .keypadEnter: return "return"
        case .keypadDecimalAndDelete: return "delete.right"
        case .keypadEquals: return "equal"
        case .keyboardVolumeUp: return "speaker.wave.3"
        case .keyboardVolumeDown: return "speaker.wave.1"
        case .keyboardVolumeMute: return "speaker.slash"
        case .keyboardHelp: return "questionmark.circle"
        default: return nil
        }
    }

    /// Shortened representations of the key code, such as `(` for `Left Bracket`, for codes that have it.
    var shortRepresentation: String? {
        switch self {
        case .keyboard1AndExclamation: return "!"
        case .keyboard2AndAtt: return "@"
        case .keyboard3AndHash: return "#"
        case .keyboard4AndDollar: return "$"
        case .keyboard5AndPercent: return "%"
        case .keyboard6AndCaret: return "^"
        case .keyboard7AndAmp: return "&"
        case .keyboard8AndStar: return "*"
        case .keyboard9AndLeftParen: return "("
        case .keyboard0AndRightParen: return ")"
        case .keyboardMinusAndUnderscore: return "_"
        case .keyboardEqualsAndPlus: return "+"
        case .keyboardLeftBracketAndBrace: return "{"
        case .keyboardRightBracketAndBrace: return "}"
        case .keyboardBackSlashAndVertical: return "|"
        case .keyboardSemiColonAndColon: return ":"
        case .keyboardApostropheAndQuote: return "\""
        case .keyboardGraveAccentAndTilde: return "~"
        case .keyboardCommaAndLeftAngle: return "<"
        case .keyboardPeriodAndRightAngle: return ">"
        case .keyboardSlashAndQuestion: return "?"
        default: return nil
        }
    }
}
