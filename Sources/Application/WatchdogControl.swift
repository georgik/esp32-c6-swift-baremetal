import MMIO
import Registers

public struct WatchdogControl {
    // Constants
    private static let wdtWriteKey: UInt32 = 0x50D8_3AA1
    
    // ESP32-C6 Watchdog Timer base addresses
    private static let timg0Base: UInt32 = 0x6001F000
    private static let timg1Base: UInt32 = 0x60020000
    private static let lpWdtBase: UInt32 = 0x600B1C00

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
        // LP_WDT config0 register is at offset 0x0 - disable by writing 0
        writeReg32(lpWdtBase + 0x0, 0)
        // Re-enable write protection
        writeReg32(lpWdtBase + 0x18, 0)
    }

    public static func disableAll() {
        disableMWDT()
        disableRTCWatchdog()
    }
}
