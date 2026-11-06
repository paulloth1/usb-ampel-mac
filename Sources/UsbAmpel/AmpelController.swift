import Foundation
import IOKit
import IOKit.hid

enum LightColor: Int, CaseIterable, Identifiable {
    case red = 0, yellow = 1, green = 2

    var id: Int { rawValue }
    /// Cleware switch code (0x10 = red, 0x11 = yellow, 0x12 = green)
    var code: UInt8 { UInt8(0x10 + rawValue) }
    var name: String {
        switch self {
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .green: return "Green"
        }
    }
}

/// Talks to the Cleware USB-Ampel (VID 0x0D50, PID 0x0008) via IOKit HID output reports.
/// All callbacks are scheduled on the main run loop, so state is only touched on the main thread.
final class AmpelController: ObservableObject {
    static let vendorID = 0x0D50
    static let productID = 0x0008

    @Published private(set) var connected = false
    @Published private(set) var lights: [LightColor: Bool] = [.red: false, .yellow: false, .green: false]
    @Published private(set) var blinking: LightColor?
    @Published private(set) var blinkPhase = false
    @Published private(set) var lastError: String?

    private let manager: IOHIDManager
    private var device: IOHIDDevice?
    private var blinkTimer: Timer?
    let blinkInterval: TimeInterval = 0.6

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: AmpelController.vendorID,
            kIOHIDProductIDKey: AmpelController.productID,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<AmpelController>.fromOpaque(context).takeUnretainedValue().attach(device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<AmpelController>.fromOpaque(context).takeUnretainedValue().detach(device)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            lastError = "Could not open HID manager (\(hex(result)))"
        }
    }

    // MARK: - Device handling

    private func attach(_ newDevice: IOHIDDevice) {
        device = newDevice
        connected = true
        lastError = nil
        applyAll()   // restore the state shown in the UI
    }

    private func detach(_ oldDevice: IOHIDDevice) {
        guard device === oldDevice else { return }
        device = nil
        connected = false
    }

    private func write(_ color: LightColor, _ on: Bool) {
        guard let device else { return }
        var report: [UInt8] = [0x00, color.code, on ? 0x01 : 0x00]
        if let maxSize = IOHIDDeviceGetProperty(device, kIOHIDMaxOutputReportSizeKey as CFString) as? Int,
           maxSize > report.count {
            report += [UInt8](repeating: 0, count: maxSize - report.count)
        }
        let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, report, report.count)
        if result != kIOReturnSuccess {
            lastError = "Write failed (\(hex(result)))"
        } else if lastError != nil {
            lastError = nil
        }
    }

    private func applyAll() {
        for color in LightColor.allCases {
            if color == blinking {
                write(color, blinkPhase)
            } else {
                write(color, lights[color] ?? false)
            }
        }
    }

    // MARK: - Public API

    func isLit(_ color: LightColor) -> Bool {
        color == blinking ? blinkPhase : (lights[color] ?? false)
    }

    func toggle(_ color: LightColor) {
        set(color, !isLit(color))
    }

    func set(_ color: LightColor, _ on: Bool) {
        if blinking == color { stopBlink() }
        lights[color] = on
        write(color, on)
    }

    func allOff() {
        stopBlink()
        for color in LightColor.allCases { set(color, false) }
    }

    func allOn() {
        stopBlink()
        for color in LightColor.allCases { set(color, true) }
    }

    func setBlink(_ color: LightColor?) {
        stopBlink()
        guard let color else { return }
        blinking = color
        blinkPhase = true
        lights[color] = false
        write(color, true)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self, let current = self.blinking else { return }
            self.blinkPhase.toggle()
            self.write(current, self.blinkPhase)
        }
    }

    private func stopBlink() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        if let color = blinking {
            blinking = nil
            blinkPhase = false
            write(color, lights[color] ?? false)
        }
    }

    private func hex(_ value: IOReturn) -> String {
        "0x" + String(UInt32(bitPattern: value), radix: 16)
    }
}
