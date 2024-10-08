import Foundation
import CoreGraphics
import IOKit
import Output
import OSLog

private let logger = Logger(subsystem: #fileID, category: "Input")

/// Input handler.
@MainActor
public final class Input {
    /// Keys currently being pressed.
    public private(set) var regularKeys = Set<InputKeyCode>()
    /// Modifiers currently being pressed.
    public private(set) var modifierKeys = Set<InputModifierKeyCode>()
    /// Input state.
    private let state = State()
    /// CapsLock stream event continuation.
    private let capsLockContinuation: AsyncStream<(timestamp: UInt64, isDown: Bool)>.Continuation
    /// Modifier stream event continuation.
    private var modifierContinuation: AsyncStream<(key: InputModifierKeyCode, isDown: Bool)>.Continuation
    /// Keyboard tap event stream continuation.
    private let keyboardTapContinuation: AsyncStream<CGEvent>.Continuation
    /// Legacy Human Interface Device manager instance.
    private let hidManager: IOHIDManager
    /// CapsLock event service handle.
    private var connect = io_connect_t(0)
    /// Tap into the windoe server's input events.
    private var eventTap: CFMachPort!
    /// Task handling CapsLock events.
    private var capsLockTask: Task<Void, Never>!
    /// Task handling modifier key events.
    private var modifierTask: Task<Void, Never>!
    /// Task handling keyboard window server tap events.
    private var keyboardTapTask: Task<Void, Never>!
    /// Shared singleton.
    public static let shared = Input()

    /// Browse mode state.
    public var browseModeEnabled: Bool {
        get { state.browseModeEnabled }
        set { state.browseModeEnabled = newValue }
    }

    /// Swallow mode state.
    public var swallowTapEvents: Bool {
        get { state.swallowTapEvents }
        set { state.swallowTapEvents = newValue }
    }

    /// Creates a new input handler.
    private init() {
        // create streams
        let (capsLockStream, capsLockContinuation) = AsyncStream<(timestamp: UInt64, isDown: Bool)>.makeStream()
        let (modifierStream, modifierContinuation) = AsyncStream<(key: InputModifierKeyCode, isDown: Bool)>.makeStream()
        let (keyboardTapStream, keyboardTapContinuation) = AsyncStream<CGEvent>.makeStream()

        // assign continuations
        self.capsLockContinuation = capsLockContinuation
        self.modifierContinuation = modifierContinuation
        self.keyboardTapContinuation = keyboardTapContinuation

        // create Human Interface Device manager
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matches = [
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard],
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Keypad]
        ]
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, matches as CFArray)

        // Set caps lock callback
        let capsLockCallback: IOHIDValueCallback = {(this, _, _, value) in
            let this = Unmanaged<Input>.fromOpaque(this!).takeUnretainedValue()
            let isDown = IOHIDValueGetIntegerValue(value) != 0
            let timestamp = IOHIDValueGetTimeStamp(value)
            let element = IOHIDValueGetElement(value)
            let scanCode = IOHIDElementGetUsage(element)
            guard let modifierKeyCode = InputModifierKeyCode(rawValue: scanCode) else {
                return
            }
            if modifierKeyCode == .capsLock {
                this.capsLockContinuation.yield((timestamp: timestamp, isDown: isDown))
            }
            this.modifierContinuation.yield((key: modifierKeyCode, isDown: isDown))
        }
        IOHIDManagerRegisterInputValueCallback(hidManager, capsLockCallback, Unmanaged.passUnretained(self).toOpaque())

        // Schedule run loop
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))

        // Open service
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        IOHIDGetModifierLockState(connect, Int32(kIOHIDCapsLockState), &state.capsLockEnabled)

        // Set keyboard callback
        let keyboardTapCallback: CGEventTapCallBack = {(_, _, event, this) in
            let this = Unmanaged<Input>.fromOpaque(this!).takeUnretainedValue()
            guard event.type != CGEventType.tapDisabledByTimeout else {
                CGEvent.tapEnable(tap: this.eventTap, enable: true)
                return nil
            }
            this.keyboardTapContinuation.yield(event)
            // if caps or browse is on and tap events are to be swallowed, return nil
            if (this.state.capsLockPressed || this.state.browseModeEnabled) && this.state.swallowTapEvents {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        // Set event of interest
        let eventOfInterest: CGEventMask = (
            1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue | 1 << CGEventType.flagsChanged.rawValue
        )

        // Create tap event
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .tailAppendEventTap,
            options: .defaultTap,
            eventsOfInterest: eventOfInterest,
            callback: keyboardTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            fatalError("Failed to create a keyboard event tap")
        }

        // Assign tap events
        let eventRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), eventRunLoopSource, CFRunLoopMode.defaultMode)
        capsLockTask = Task(operation: { [unowned self] in await handleCapsLockStream(capsLockStream) })
        modifierTask = Task(operation: { [unowned self] in await handleModifierStream(modifierStream) })
        keyboardTapTask = Task(operation: { [unowned self] in await handleKeyboardTapStream(keyboardTapStream) })
    }

    deinit {
        capsLockTask.cancel()
        modifierTask.cancel()
        keyboardTapTask.cancel()
        IOServiceClose(connect)
    }

    /// Binds a key to an action with optional modifiers.
    /// - Parameters:
    ///   - keyBinding: The key binding to bind to
    ///   - action: Action to perform when the key combination is pressed.
    public func bindKey(
        _ keyBinding: KeyBinding,
        action: @escaping () async -> Void
    ) {
        guard state.keyBindings.updateValue(action, forKey: keyBinding) == nil else {
            logger.error("Attempted to bind the same key combination twice")
            return
        }
    }

    /// Removes a key bind
    /// - Parameter keyBinding: The key to unbind
    public func unbindKey(_ keyBinding: KeyBinding) {
        state.keyBindings[keyBinding] = nil
    }

    /// Changes the key binding for an action. This action fails silently if the original key binding does not have an
    /// associated action.
    /// - Parameters:
    ///   - originalBinding: The original key binding
    ///   - newBinding: The new key binding
    public func rebindKey(from originalBinding: KeyBinding, to newBinding: KeyBinding) {
        state.keyBindings[newBinding] = state.keyBindings[originalBinding]
    }

    /// Detects and executes a callback on the next key event
    /// - Parameter callback: The key binding that was pressed
    public func detectKeyEvent(
        _ callback: @escaping (KeyBinding) -> Void
    ) {
        state.keyEventCallback = callback
    }

    /// Handles the stream of CapsLock events.
    /// - Parameter capsLockStream: Stream of CapsLock events.
    private func handleCapsLockStream(_ capsLockStream: AsyncStream<(timestamp: UInt64, isDown: Bool)>) async {
        for await (timestamp: timestamp, isDown: isDown) in capsLockStream {
            state.capsLockPressed = isDown
            var timeBase = mach_timebase_info(numer: 0, denom: 0)
            mach_timebase_info(&timeBase)
            let timestamp = timestamp / UInt64(timeBase.denom) * UInt64(timeBase.numer)
            if state.lastCapsLockEvent + 250000000 > timestamp && isDown {
                state.lastCapsLockEvent = 0
                state.capsLockEnabled.toggle()
                IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), state.capsLockEnabled)
                let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x39, keyDown: state.capsLockEnabled)
                event?.post(tap: .cghidEventTap)
                Output.shared.convey([OutputSemantic.capsLockStatusChanged(state.capsLockEnabled)])
                continue
            }
            IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), state.capsLockEnabled)
            if isDown {
                state.lastCapsLockEvent = timestamp
            }
        }
    }

    /// Handles the stream of modifier key events.
    /// - Parameter modifierStream: Stream of modifier key events.
    private func handleModifierStream(_ modifierStream: AsyncStream<(key: InputModifierKeyCode, isDown: Bool)>) async {
        for await event in modifierStream {
            if event.isDown {
                state.shouldInterrupt = (
                    regularKeys.isEmpty &&
                    modifierKeys.isEmpty &&
                    (event.key == .leftControl || event.key == .rightControl)
                )
                modifierKeys.insert(event.key)
                continue
            }
            modifierKeys.remove(event.key)
            if state.shouldInterrupt {
                Output.shared.interrupt()
                state.shouldInterrupt = false
            }
        }
    }

    /// Handles the stream of keyboard tap events.
    /// - Parameter keyboardTapStream: Stream of keyboard tap events.
    private func handleKeyboardTapStream(_ keyboardTapStream: AsyncStream<CGEvent>) async {
        for await event in keyboardTapStream {
            // cast the key code to an integer
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            guard let keyCode = InputKeyCode(rawValue: keyCode) else {
                continue
            }

            // if its a key up, remove it from regularKeys and proceed to the next
            state.shouldInterrupt = false
            guard event.type == .keyDown else {
                regularKeys.remove(keyCode)
                continue
            }

            // insert this into regularKeys
            regularKeys.insert(keyCode)

            // determine if we should execute an action
            guard state.capsLockPressed || state.browseModeEnabled else {
                continue
            }

            // create a binding
            let browseMode = state.browseModeEnabled && !state.capsLockPressed
            let controlModifier = event.flags.contains(.maskControl)
            let optionModifier = event.flags.contains(.maskAlternate)
            let commandModifier = event.flags.contains(.maskCommand)
            let shiftModifier = event.flags.contains(.maskShift)
            let keyBinding = KeyBinding(
                browseMode: browseMode,
                controlModifier: controlModifier,
                optionModifier: optionModifier,
                commandModifier: commandModifier,
                shiftModifier: shiftModifier,
                key: keyCode
            )

            // determine if we should call the keyEventCallback
            if let keyEventCallback = state.keyEventCallback {
                keyEventCallback(keyBinding)
                state.keyEventCallback = nil
                continue
            }

            // execute the action
            if let action = state.keyBindings[keyBinding] {
                await action()
            }
        }
    }

    /// Input state.
    private final class State {
        /// Whether browse mode is enabled.
        var browseModeEnabled = false
        /// Whether keyboard tap events are "swallowed" when caps is pressed, or browse mode is on
        var swallowTapEvents = false
        /// Mach timestamp of the last CapsLock key press event.
        var lastCapsLockEvent = UInt64(0)
        /// Whether CapsLock is enabled.
        var capsLockEnabled = false
        /// Whether CapsLock is being pressed.
        var capsLockPressed = false
        /// Map of key bindings to their respective actions.
        var keyBindings = [KeyBinding: () async -> Void]()
        /// Whether the user wants to interrupt speech.
        var shouldInterrupt = false
        /// The callback that is set if we want to detect a shortcut triggered by the user. This will be called
        /// when a key is pressed, then set to nil.
        var keyEventCallback: ((KeyBinding) -> Void)?
    }
}

/// Key to the key bindings map.
public struct KeyBinding: Hashable, Codable {
    /// Whether browse mode is required.
    public let browseMode: Bool
    /// Whether the Control key modifier is required.
    public let controlModifier: Bool
    /// Whether the Option key modifier is required.
    public let optionModifier: Bool
    /// Whether the Command key modifier is required.
    public let commandModifier: Bool
    /// Whether the Shift key modifier is required.
    public let shiftModifier: Bool
    /// Bound key.
    public let key: InputKeyCode

    /// Creates a key binding
    public init(
        browseMode: Bool = false,
        controlModifier: Bool = false,
        optionModifier: Bool = false,
        commandModifier: Bool = false,
        shiftModifier: Bool = false,
        key: InputKeyCode
    ) {
        self.browseMode = browseMode
        self.controlModifier = controlModifier
        self.optionModifier = optionModifier
        self.commandModifier = commandModifier
        self.shiftModifier = shiftModifier
        self.key = key
    }
}
