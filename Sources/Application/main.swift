import MMIO
import Registers

@_silgen_name("esp_app_desc")
func _getAppDesc() -> UnsafeRawPointer

@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()

    
    // Simple bare metal main loop
    while true {
        setLED(on: true)
        busyWait(cycles: 5_000_000)
        setLED(on: false)
        busyWait(cycles: 15_000_000)
    }
}

// Simple LED control
private func setLED(on: Bool) {
    let gpioBase = UnsafeMutablePointer<UInt32>(bitPattern: 0x60004000)!
    if on {
        gpioBase.pointee |= (1 << 8)
    } else {
        gpioBase.pointee &= ~(1 << 8)
    }
}

private func busyWait(cycles: UInt32) {
    var counter: UInt32 = 0
    while counter < cycles {
        counter += 1
        _ = counter
    }
}

@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
    memptr.pointee = nil
    return 12 // ENOMEM
}

@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}
