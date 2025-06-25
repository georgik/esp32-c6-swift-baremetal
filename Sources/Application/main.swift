
import MMIO
import Registers

/// Read a 32-bit peripheral register (volatile, no import from C needed)
@inline(__always)
private func readReg32(_ addr: UInt32) -> UInt32 {
    return UnsafePointer<UInt32>(bitPattern: UInt(addr))!.pointee
}

/// Pretty-print the SoC reset cause and key WDT status bits.
/// Call this once right after UART is initialised.
public func printBootDiagnostics() {
    ESP32C6ROM.hardDisableMWDT0()
    ESP32C6ROM.hardDisableRWDT()
    ESP32C6ROM.disableRTCWatchdogDirectly()
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

    // 3. Extra low-level context from RTC_CNTL
    let RTC_CNTL_BASE: UInt32 = 0x6000_8000
    let rstState   = readReg32(RTC_CNTL_BASE + 0x34)   // RESET_STATE_REG
    let wdtCfg0    = readReg32(RTC_CNTL_BASE + 0x80)   // WDTCONFIG0_REG
    let wdtProtect = readReg32(RTC_CNTL_BASE + 0xA4)   // WDTWPROTECT_REG

    putString("RTC_CNTL_RESET_STATE_REG: 0x");  printHex32(rstState);   putLine("")
    putString("RTC_CNTL_WDTCONFIG0_REG : 0x");  printHex32(wdtCfg0);    putLine("")
    putString("RTC_CNTL_WDTWPROTECT_REG: 0x");  printHex32(wdtProtect); putLine("")

    // 4. Quick hint if the RTC watchdog is still enabled
    if (wdtCfg0 & (1 << 31)) != 0 {
        putLine("WARNING: RTC watchdog is still ENABLED (bit31 set).")
    } else {
        putLine("RTC watchdog appears to be disabled (bit31 clear).")
    }

    ESP32C6ROM.printRTCWatchdogState()   // before disabling
    ESP32C6ROM.hardDisableRWDT()      // clear the enable bit
    ESP32C6ROM.printRTCWatchdogState()   // verify it's really off

    putLine("=== End Boot Diagnostics ===")
    flushUART()
}

@_cdecl("swift_main")
public func swiftMain() {
    putLine("ESP32-C6")
    putLine("Registers and configuration")
    flushUART()

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