
import MMIO
import Registers


@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()

    // Initialize LED with enhanced debugging
    initializeLED()

    // Simple main loop with status output
    var cycle = 0
    while true {
        if cycle % 10 == 0 {
            putString("LED ON (cycle ")
            putChar(UInt8(48 + (cycle / 10) % 10))
            putLine(")")
            flushUART()
        }

        setLED(on: true)
        delayMilliseconds(200)
        setLED(on: false)
        delayMilliseconds(800)

        cycle += 1
    }
}

@_cdecl("swift_main")
public func swiftMain() {
    putLine("ESP32-C6")
    putLine("Registers and configuration")
    flushUART()

    // IMPORTANT: Initialize the LED first!
    initializeLED()

    // Initialize and test SPI
    putLine("Initializing SPI for display communication...")
    testSPIDisplay()

    var counter = 0

    while true {
        putString("Debug cycle ")
        putChar(UInt8(48 + (counter % 10)))
        putLine("")

        // Print current register states during operation
        if counter % 5 == 0 {
            putLine("Current states:")
            putString("ENABLE: ")
            printHex32(UInt32(gpio.enable.read().raw.storage))
            putLine("")
            putString("OUT: ")
            printHex32(UInt32(gpio.out.read().raw.storage))
            putLine("")
        }
        flushUART()

        // Test pattern
        setLED(on: true)
        delayMicroseconds(100_000)
        setLED(on: false)
        delayMicroseconds(100_000)

        setLED(on: true)
        delayMicroseconds(500_000)
        setLED(on: false)
        delayMicroseconds(500_000)

        counter += 1
        if counter >= 20 {
            putLine("=== Register Analysis Complete ===")
            flushUART()
            counter = 0
        }
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