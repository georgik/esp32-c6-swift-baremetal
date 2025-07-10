
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

/// Print a StaticString without Unicode processing
public func printStaticString(_ str: StaticString) {
    str.withUTF8Buffer { buffer in
        for i in 0..<buffer.count {
            putChar(buffer[i])
        }
    }
}

@_cdecl("swift_main")
public func swiftMain() {
    putLine("ESP32-C6")
    putLine("Registers and configuration")
    flushUART()
    
    // Check watchdog status before disabling
    putLine("\n=== Watchdog Status Analysis ===")
    putLine("Checking watchdog status BEFORE disabling:")
    WatchdogControl.printAllWatchdogStatuses()
    flushUART()
    
    putLine("\n==> Disabling all watchdogs...")
    WatchdogControl.disableAll()
    
    putLine("\nChecking watchdog status AFTER disabling:")
    WatchdogControl.printAllWatchdogStatuses()
    
    putLine("\nWatchdog disabling complete.")
    
    putLine("\nWatchdog control registers:")
    putLine("- TIMG0 base: 0x60008000 (MWDT0 control)")
    putLine("- TIMG1 base: 0x60009000 (MWDT1 control)")
    putLine("- LP_WDT base: 0x600B1C00 (RWDT control)")
    putLine("- Key register field: wdtconfig0.wdt_en (bit 31)")
    putLine("=== End Watchdog Analysis ===")
    flushUART()

    printBootDiagnostics()

    // IMPORTANT: Initialize the LED first!
    initializeLED()

    // Initialize and test SPI first (needed for NVS flash operations)
    putLine("Initializing SPI for display communication...")
    runDisplayApplication()

    // Initialize the NVS first
    putLine("\n=== NVS Initialization ===")
    let nvsResult = nvs_flash_init()
    if nvsResult != 0 {
        putLine("Failed to initialize NVS flash")
        return
    }
    putLine("NVS flash initialized")

    // Mark NVS as initialized in WiFiManager
    WiFiManager.markNVSInitialized()

    // Create scheduler and tasks
    let scheduler = Scheduler()
    scheduler.addTask(Task(name: "Init WiFi") {
        // First task: Initialize WiFi after NVS
        WiFiManager.initializeWiFi()
    })
    scheduler.addTask(Task(name: "Scan Networks") {
        // Second task: Scan for networks after WiFi is initialized
        WiFiManager.scanNetworks()
    })

    // Run the scheduler
    scheduler.run()

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
public func freeEmbeddedFree(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}

@_cdecl("putchar")
public func putchar(_ char: Int32) -> Int32 {
    putChar(UInt8(char))
    return char
}
