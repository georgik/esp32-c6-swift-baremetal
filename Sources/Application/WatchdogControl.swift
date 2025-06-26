//
//  WatchdogControl.swift
//  Bare-metal disable of all ESP32-C6 watchdogs
//

import MMIO

public struct WatchdogControl {
    // MARK: – Constants

    // Base addresses (from Table 5.3-2)
    private static let rtcBase: UInt32   = 0x6000_8000
    private static let timg0Base: UInt32 = 0x6001_F000
    private static let timg1Base: UInt32 = 0x6002_0000

    // Offsets within each block
    private static let rtcWDTConfig0: UInt32   = 0x80   // RTC_WDT_CONFIG0_REG
    private static let rtcWDTWProtect: UInt32  = 0xA4   // RTC_WDT_WKEY

    // Additional RTC-WDT offsets
    private static let rtcWDTIntEna: UInt32      = 0x2C   // RTC_WDT_INT_ENA_REG
    private static let rtcSWDConfig: UInt32     = 0x1C   // RTC_WDT_SWD_CONFIG_REG
    private static let rtcSWDWProtect: UInt32   = 0x20   // RTC_WDT_SWD_WKEY

    private static let timgWDTConfig0: UInt32  = 0x048  // TIMG_WDTCONFIG0_REG
    private static let timgWDTWProtect: UInt32 = 0x064  // TIMG_WDTWPROTECT_REG

    // The magic write-key for both MWDT and RWDT
    private static let wdtWriteKey: UInt32 = 0x50D8_3AA1

    // MARK: – Low-level register access

    @inline(__always)
    private static func readReg32(_ addr: UInt32) -> UInt32 {
        return UnsafePointer<UInt32>(bitPattern: UInt(addr))!.pointee
    }

    @inline(__always)
    private static func writeReg32(_ addr: UInt32, _ value: UInt32) {
        UnsafeMutablePointer<UInt32>(bitPattern: UInt(addr))!.pointee = value
    }

    // MARK: – MWDT disable

    private static func disableMWDT(groupBase: UInt32) {
        // 1) unlock write-protection
        writeReg32(groupBase + timgWDTWProtect, wdtWriteKey)

        // 2) clear the “enable” bit (bit 31) and the flash-boot-protection bit (bit 29)
        var cfg = readReg32(groupBase + timgWDTConfig0)
        cfg &= ~0x8000_0000       // clear EN
        cfg &= ~0x2000_0000       // clear FLASHBOOT_MOD_EN
        writeReg32(groupBase + timgWDTConfig0, cfg)

        // 3) re-lock write-protection
        writeReg32(groupBase + timgWDTWProtect, 0)
    }

    /// Disable the LWDT in Timer Group 0 (MWDT0)
    public static func disableMWDT0() {
        disableMWDT(groupBase: timg0Base)
    }

    /// Disable the LWDT in Timer Group 1 (MWDT1)
    public static func disableMWDT1() {
        disableMWDT(groupBase: timg1Base)
    }

    // MARK: – RTC-WDT disable

    /// Disable the RTC watchdog (RWDT)
    public static func disableRTCWatchdog() {
        // 1) unlock write-protection
        writeReg32(rtcBase + rtcWDTWProtect, wdtWriteKey)

        // 2) clear enable (bit 31) and flash-boot-protection (bit 29)
        var cfg0 = readReg32(rtcBase + rtcWDTConfig0)
        cfg0 &= ~0x8000_0000       // clear EN
        cfg0 &= ~0x2000_0000       // clear FLASHBOOT_MOD_EN
        writeReg32(rtcBase + rtcWDTConfig0, cfg0)

        // 3) re-lock write-protection
        writeReg32(rtcBase + rtcWDTWProtect, 0)

        // 4) clear any pending interrupts
        writeReg32(rtcBase + rtcWDTIntEna, 0)

        // double-check disable
        writeReg32(rtcBase + rtcWDTWProtect, wdtWriteKey)
        var cfgCheck = readReg32(rtcBase + rtcWDTConfig0)
        cfgCheck &= ~0x8000_0000
        cfgCheck &= ~0x2000_0000
        writeReg32(rtcBase + rtcWDTConfig0, cfgCheck)
        writeReg32(rtcBase + rtcWDTWProtect, 0)
    }

    /// Disable the Super Watchdog (SWD)
    private static func disableSWD() {
        // unlock SWD write-protection
        writeReg32(rtcBase + rtcSWDWProtect, wdtWriteKey)
        // set the “disable” bit (bit 31) in SWD_CONFIG (RTC_WDT_SWD_DISABLE)
        var cfg = readReg32(rtcBase + rtcSWDConfig)
        cfg |= 0x8000_0000
        writeReg32(rtcBase + rtcSWDConfig, cfg)
        // re-lock write-protection
        writeReg32(rtcBase + rtcSWDWProtect, 0)
    }

    // MARK: – Top-level

    /// Disable **all** hardware watchdogs on the ESP32-C6
    public static func disableAll() {
        disableMWDT0()
        disableMWDT1()
        disableRTCWatchdog()
        disableSWD()
    }
}
