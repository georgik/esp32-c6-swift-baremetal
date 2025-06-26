
import MMIO
import Registers


/// Pretty-print the SoC reset cause and key WDT status bits.
/// Call this once right after UART is initialised.
public func printBootDiagnostics() {
    putLine("=== Boot Diagnostics ===")

    // 1. ROM helper: esp_rom_get_reset_reason() -> UInt32
    let rawReason = ESP32C6ROM.getResetReason()

    // 2. Try to decode with the enum you already have
    if let decoded = ESP32C6ROM.ResetReason(rawValue: rawReason) {
        putString("Reset reason (code ")
        printSimpleNumber(UInt16(rawReason))
        putString("): ")
        decoded.printDescription()
        putLine("")
        if decoded.isWatchdogReset {
            putLine("NOTE: reset was triggered by a watchdog.")
        }
    } else {
        // Unknown / future reason
        putString("Reset reason code: ")
        printSimpleNumber(UInt16(rawReason))
        putLine(" (unrecognised)")
    }


    putLine("=== End Boot Diagnostics ===")
    flushUART()
}

@_cdecl("swift_main")
public func swiftMain() {
    putLine("ESP32-C6")
    putLine("Registers and configuration")
    flushUART()
    WatchdogControl.disableAll()

    printBootDiagnostics()

    // IMPORTANT: Initialize the LED first!
    initializeLED()

    // Initialize and test SPI
    putLine("Initializing SPI for display communication...")
    runDisplayApplication()

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

@_silgen_name("initializeWatchdogWithLongerTimeout")
func initializeWatchdogWithLongerTimeout()

@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
    memptr.pointee = nil
    return 12 // ENOMEM
}

@_cdecl("free_embedded")
public func freeEmbedded(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}

@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}