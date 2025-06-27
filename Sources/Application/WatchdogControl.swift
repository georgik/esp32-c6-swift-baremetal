import MMIO
import Registers

public struct WatchdogControl {
    // Constants
    private static let wdtWriteKey: UInt32 = 0x50D8_3AA1
    
    // ESP32-C6 Watchdog Timer base addresses
    private static let timg0Base: UInt32 = 0x60008000
    private static let timg1Base: UInt32 = 0x60009000
    private static let lpWdtBase: UInt32 = 0x600B1C00
    
    // Register offsets
    private static let wdtConfig0Offset: UInt32 = 0x48  // TIMG WDTCONFIG0
    private static let lpWdtConfig0Offset: UInt32 = 0x0  // LP_WDT CONFIG0
    private static let wdtProtectOffset: UInt32 = 0x64   // TIMG WDTWPROTECT
    private static let lpWdtProtectOffset: UInt32 = 0x18 // LP_WDT WDTWPROTECT
    
    // Watchdog status structure
    public struct WatchdogStatus {
        public let enabled: Bool
        public let config0Value: UInt32
        public let name: String
        
        public init(enabled: Bool, config0Value: UInt32, name: String) {
            self.enabled = enabled
            self.config0Value = config0Value
            self.name = name
        }
    }

    @inline(__always)
    private static func readReg32(_ addr: UInt32) -> UInt32 {
        return UnsafePointer<UInt32>(bitPattern: UInt(addr))!.pointee
    }

    @inline(__always)
    private static func writeReg32(_ addr: UInt32, _ value: UInt32) {
        UnsafeMutablePointer<UInt32>(bitPattern: UInt(addr))!.pointee = value
    }

    // Disable all TIMG MWDT (Timer Group Watchdog)
    private static func disableMWDT() {
        [timg0Base, timg1Base].forEach { base in
            // TIMG WDTWPROTECT register at offset 0x64
            writeReg32(base + 0x64, wdtWriteKey)
            // TIMG WDTCONFIG0 register at offset 0x48 - clear enable bit (31)
            writeReg32(base + 0x48, 0)
            // Re-enable write protection
            writeReg32(base + 0x64, 0)
        }
    }

    // Disable RWDT (LP_WDT)
    public static func disableRTCWatchdog() {
        // LP_WDT write protection register is at offset 0x18
        writeReg32(lpWdtBase + 0x18, wdtWriteKey)
        
        // Read current config0 value
        let currentConfig = readReg32(lpWdtBase + 0x0)
        
        // Clear enable bit (bit 31) and flashboot bit (bit 12) while preserving other bits
        let newConfig = currentConfig & ~((1 << 31) | (1 << 12))
        
        // Write the modified config
        writeReg32(lpWdtBase + 0x0, newConfig)
        
        // Feed the watchdog once to reset counter
        writeReg32(lpWdtBase + 0x14, 1)
        
        // Re-enable write protection
        writeReg32(lpWdtBase + 0x18, 0)
    }

    public static func disableAll() {
        disableMWDT()
        disableRTCWatchdog()
    }
    
    // MARK: - Diagnostic Functions
    
    // Check TIMG0 MWDT status
    public static func checkTIMG0Status() -> WatchdogStatus {
        let config0Reg = readReg32(timg0Base + wdtConfig0Offset)
        let enabled = (config0Reg & (1 << 31)) != 0 // bit 31 is wdt_en
        return WatchdogStatus(enabled: enabled, config0Value: config0Reg, name: "TIMG0 MWDT")
    }
    
    // Check TIMG1 MWDT status
    public static func checkTIMG1Status() -> WatchdogStatus {
        let config0Reg = readReg32(timg1Base + wdtConfig0Offset)
        let enabled = (config0Reg & (1 << 31)) != 0 // bit 31 is wdt_en
        return WatchdogStatus(enabled: enabled, config0Value: config0Reg, name: "TIMG1 MWDT")
    }
    
    // Check RWDT (LP_WDT) status
    public static func checkRWDTStatus() -> WatchdogStatus {
        let config0Reg = readReg32(lpWdtBase + lpWdtConfig0Offset)
        let enabled = (config0Reg & (1 << 31)) != 0 // bit 31 is wdt_en
        return WatchdogStatus(enabled: enabled, config0Value: config0Reg, name: "RWDT (LP_WDT)")
    }
    
    // Get all watchdog statuses (individual checks to avoid array allocation)
    public static func checkAllWatchdogStatuses() {
        printTIMG0Status()
        printTIMG1Status()
        printRWDTStatus()
    }
    
    // Print watchdog status (static strings only)
    public static func printTIMG0Status() {
        let status = checkTIMG0Status()
        putString("TIMG0 MWDT enabled: ")
        putString(status.enabled ? "true" : "false")
        putString(", config0: 0x")
        printHex32(status.config0Value)
        putLine("")
    }
    
    public static func printTIMG1Status() {
        let status = checkTIMG1Status()
        putString("TIMG1 MWDT enabled: ")
        putString(status.enabled ? "true" : "false")
        putString(", config0: 0x")
        printHex32(status.config0Value)
        putLine("")
    }
    
    public static func printRWDTStatus() {
        let status = checkRWDTStatus()
        putString("RWDT (LP_WDT) enabled: ")
        putString(status.enabled ? "true" : "false")
        putString(", config0: 0x")
        printHex32(status.config0Value)
        putLine("")
    }
    
    // Print all watchdog statuses
    public static func printAllWatchdogStatuses() {
        printTIMG0Status()
        printTIMG1Status()
        printRWDTStatus()
    }
    
}
