import MMIO
import Registers

// Prevent any allocations by avoiding complex Swift features
@_cdecl("_start")
public func _start() -> Never {
    // Simple bare metal main loop
    while true {
        // Blink pattern: on for short time, off for longer time
        setLED(on: true)
        busyWait(cycles: 5_000_000)

        setLED(on: false)
        busyWait(cycles: 15_000_000)
    }
}

// Simple LED control - adjust GPIO pin and registers for your ESP32-C6 board
private func setLED(on: Bool) {
    let gpioBase = UnsafeMutablePointer<UInt32>(bitPattern: 0x60004000)! // ESP32-C6 GPIO base

    if on {
        // Set bit for LED pin (example for pin 8)
        gpioBase.pointee |= (1 << 8)
    } else {
        // Clear bit for LED pin
        gpioBase.pointee &= ~(1 << 8)
    }
}

private func busyWait(cycles: UInt32) {
    var counter: UInt32 = 0
    while counter < cycles {
        counter += 1
        // Prevent optimization by making the variable volatile
        _ = counter
    }
}

// Provide minimal runtime functions
@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
    // Return error to prevent allocations
    memptr.pointee = nil
    return 12 // ENOMEM - force allocation failure
}

@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}