// ESP32-C6 ROM Functions - Pure Swift Bare Metal Implementation
// Based on esp32c6.rom.api.ld linker script symbols

// MARK: - Reset and System Control ROM Functions


/// Get reset reason for specified CPU
/// Maps to: esp_rom_get_reset_reason = rtc_get_reset_reason
@_silgen_name("rtc_get_reset_reason")
func rtc_get_reset_reason() -> UInt32

/// Software reset of the entire system
/// Maps to: esp_rom_software_reset_system = software_reset
@_silgen_name("software_reset")
func software_reset() -> Never

/// Software reset of specific CPU
/// Maps to: esp_rom_software_reset_cpu = software_reset_cpu
@_silgen_name("software_reset_cpu")
func software_reset_cpu(_ cpu_id: UInt32)

// MARK: - Timing and Delay ROM Functions

/// Microsecond delay function
/// Maps to: esp_rom_delay_us = ets_delay_us
@_silgen_name("ets_delay_us")
func ets_delay_us(_ us: UInt32)

/// Get CPU frequency in ticks per microsecond
/// Maps to: esp_rom_get_cpu_ticks_per_us = ets_get_cpu_frequency
@_silgen_name("ets_get_cpu_frequency")
func ets_get_cpu_frequency() -> UInt32

/// Set CPU frequency in ticks per microsecond
/// Maps to: esp_rom_set_cpu_ticks_per_us = ets_update_cpu_frequency
@_silgen_name("ets_update_cpu_frequency")
func ets_update_cpu_frequency(_ ticks_per_us: UInt32)

// MARK: - UART and Output ROM Functions

/// Flush UART TX buffer
/// Maps to: esp_rom_uart_flush_tx = uart_tx_flush
@_silgen_name("uart_tx_flush")
func uart_tx_flush(_ uart_num: UInt32)

/// Transmit one character via UART
/// Maps to: esp_rom_uart_tx_one_char = uart_tx_one_char2
@_silgen_name("uart_tx_one_char2")
func uart_tx_one_char2(_ uart_num: UInt32, _ c: UInt8) -> UInt32

/// Wait for UART TX to become idle
/// Maps to: esp_rom_uart_tx_wait_idle = uart_tx_wait_idle
@_silgen_name("uart_tx_wait_idle")
func uart_tx_wait_idle(_ uart_num: UInt32)

/// Receive one character from UART
/// Maps to: esp_rom_uart_rx_one_char = uart_rx_one_char
@_silgen_name("uart_rx_one_char")
func uart_rx_one_char(_ uart_num: UInt32) -> UInt32

/// Set UART as console
/// Maps to: esp_rom_uart_set_as_console = uart_tx_switch
@_silgen_name("uart_tx_switch")
func uart_tx_switch(_ uart_num: UInt32)

// MARK: - GPIO ROM Functions

/// Select GPIO pad function
/// Maps to: esp_rom_gpio_pad_select_gpio = gpio_pad_select_gpio
@_silgen_name("gpio_pad_select_gpio")
func gpio_pad_select_gpio(_ gpio_num: UInt32)

/// Set GPIO pad pullup
/// Maps to: esp_rom_gpio_pad_pullup_only = gpio_pad_pullup
@_silgen_name("gpio_pad_pullup")
func gpio_pad_pullup(_ gpio_num: UInt32)

/// Set GPIO pad drive strength
/// Maps to: esp_rom_gpio_pad_set_drv = gpio_pad_set_drv
@_silgen_name("gpio_pad_set_drv")
func gpio_pad_set_drv(_ gpio_num: UInt32, _ drv: UInt32)

/// Unhold GPIO pad
/// Maps to: esp_rom_gpio_pad_unhold = gpio_pad_unhold
@_silgen_name("gpio_pad_unhold")
func gpio_pad_unhold(_ gpio_num: UInt32)

/// Connect input signal to GPIO matrix
/// Maps to: esp_rom_gpio_connect_in_signal = gpio_matrix_in
@_silgen_name("gpio_matrix_in")
func gpio_matrix_in(_ gpio_num: UInt32, _ signal_idx: UInt32, _ inv: Bool)

/// Connect output signal from GPIO matrix
/// Maps to: esp_rom_gpio_connect_out_signal = gpio_matrix_out
@_silgen_name("gpio_matrix_out")
func gpio_matrix_out(_ gpio_num: UInt32, _ signal_idx: UInt32, _ inv: Bool, _ oen_inv: Bool)

// MARK: - CRC ROM Functions

/// CRC32 Little Endian
/// Maps to: esp_rom_crc32_le = crc32_le
@_silgen_name("crc32_le")
func crc32_le(_ crc: UInt32, _ buf: UnsafePointer<UInt8>, _ len: UInt32) -> UInt32

/// CRC16 Little Endian
/// Maps to: esp_rom_crc16_le = crc16_le
@_silgen_name("crc16_le")
func crc16_le(_ crc: UInt16, _ buf: UnsafePointer<UInt8>, _ len: UInt32) -> UInt16

/// CRC8 Little Endian
/// Maps to: esp_rom_crc8_le = crc8_le
@_silgen_name("crc8_le")
func crc8_le(_ crc: UInt8, _ buf: UnsafePointer<UInt8>, _ len: UInt32) -> UInt8


// MARK: - Public Swift API Wrappers

public struct ESP32C6ROM {

    // MARK: - Reset and System Control

    /// Get the reset reason for the current CPU
    public static func getResetReason() -> UInt32 {
        return rtc_get_reset_reason()
    }

    /// Perform a software reset of the entire system
    public static func softwareResetSystem() -> Never {
        software_reset()
    }

    /// Perform a software reset of the specified CPU
    public static func softwareResetCPU(_ cpuId: UInt32 = 0) {
        software_reset_cpu(cpuId)
    }

    // MARK: - Timing and Delays

    /// Delay for the specified number of microseconds using ROM function
    public static func delayMicroseconds(_ microseconds: UInt32) {
        ets_delay_us(microseconds)
    }

    /// Get CPU frequency in ticks per microsecond
    public static func getCPUFrequency() -> UInt32 {
        return ets_get_cpu_frequency()
    }

    /// Set CPU frequency in ticks per microsecond
    public static func setCPUFrequency(_ ticksPerMicrosecond: UInt32) {
        ets_update_cpu_frequency(ticksPerMicrosecond)
    }

    // MARK: - UART Functions

    /// Flush UART transmit buffer
    public static func flushUART(_ uartNumber: UInt32 = 0) {
        uart_tx_flush(uartNumber)
    }

    /// Send single character via UART
    public static func sendCharUART(_ char: UInt8, uart: UInt32 = 0) {
        _ = uart_tx_one_char2(uart, char)
    }

    /// Wait for UART transmission to complete
    public static func waitUARTIdle(_ uartNumber: UInt32 = 0) {
        uart_tx_wait_idle(uartNumber)
    }

    /// Set UART as system console
    public static func setUARTAsConsole(_ uartNumber: UInt32 = 0) {
        uart_tx_switch(uartNumber)
    }

    // MARK: - GPIO Functions

    /// Configure GPIO pad for GPIO function
    public static func selectGPIOPad(_ gpioNumber: UInt32) {
        gpio_pad_select_gpio(gpioNumber)
    }

    /// Enable pullup on GPIO pad
    public static func enableGPIOPullup(_ gpioNumber: UInt32) {
        gpio_pad_pullup(gpioNumber)
    }

    /// Set GPIO pad drive strength
    public static func setGPIODriveStrength(_ gpioNumber: UInt32, strength: UInt32) {
        gpio_pad_set_drv(gpioNumber, strength)
    }

    /// Release GPIO pad hold
    public static func unholdGPIO(_ gpioNumber: UInt32) {
        gpio_pad_unhold(gpioNumber)
    }

    // MARK: - CRC Functions

    /// Calculate CRC32 using ROM function
    public static func calculateCRC32(_ data: UnsafeBufferPointer<UInt8>, initialCRC: UInt32 = 0) -> UInt32 {
        guard let baseAddress = data.baseAddress else { return initialCRC }
        return crc32_le(initialCRC, baseAddress, UInt32(data.count))
    }

    /// Calculate CRC16 using ROM function
    public static func calculateCRC16(_ data: UnsafeBufferPointer<UInt8>, initialCRC: UInt16 = 0) -> UInt16 {
        guard let baseAddress = data.baseAddress else { return initialCRC }
        return crc16_le(initialCRC, baseAddress, UInt32(data.count))
    }

    /// Calculate CRC8 using ROM function
    public static func calculateCRC8(_ data: UnsafeBufferPointer<UInt8>, initialCRC: UInt8 = 0) -> UInt8 {
        guard let baseAddress = data.baseAddress else { return initialCRC }
        return crc8_le(initialCRC, baseAddress, UInt32(data.count))
    }

    // MARK: - RTC Watchdog Control

    /// Disable the RTC watchdog timer by clearing the enable bit in WDTCONFIG0 register
    public static func disableRTCWatchdog() {
        let RTC_CNTL_BASE = 0x60008000
        let WDTWPROTECT_REG = RTC_CNTL_BASE + 0xA4
        let WDTCONFIG0_REG = RTC_CNTL_BASE + 0x48
        let WDT_WKEY_VALUE: UInt32 = 0x50D83AA1

        // Unlock WDT write protection
        let wdtProtectPtr = UnsafeMutablePointer<UInt32>(bitPattern: WDTWPROTECT_REG)!
        wdtProtectPtr.pointee = WDT_WKEY_VALUE

        // Clear bit 31 in WDTCONFIG0 to disable the watchdog
        let wdtConfig0Ptr = UnsafeMutablePointer<UInt32>(bitPattern: WDTCONFIG0_REG)!
        wdtConfig0Ptr.pointee &= ~(1 << 31)

        // Re-lock WDT write protection
        wdtProtectPtr.pointee = 0
    }

    /// Print the current state of the RTC watchdog timer
    public static func printRTCWatchdogState() {
        let RTC_CNTL_BASE = 0x60008000
        let WDTCONFIG0_REG = RTC_CNTL_BASE + 0x48
        let wdtConfig0Ptr = UnsafePointer<UInt32>(bitPattern: WDTCONFIG0_REG)!
        let value = wdtConfig0Ptr.pointee

        putString("RTC WDTCONFIG0_REG = 0x")
        printHex32(value)
        putLine("")

        if (value & (1 << 31)) != 0 {
            putString("Warning: RTC Watchdog is ENABLED\n")
        } else {
            putString("RTC Watchdog is DISABLED\n")
        }
    }
}

// MARK: - Reset Reason Constants

public extension ESP32C6ROM {
    enum ResetReason: UInt32, CaseIterable {
        case powerOn = 1
        case software = 3
        case taskWatchdog = 4
        case deepSleep = 5
        case slcModule = 6
        case timerGroup0WDT = 7
        case timerGroup1WDT = 8
        case rtcWDT = 9
        case intrusionTest = 10
        case timeGroup = 11
        case softwareRestart = 12
        case rtcWDTBrownout = 13
        case rtcWDTReset = 14
        case timerGroup0WDTReset = 15
        case rtcRWDTSystem = 16  // RTC RWDT system reset

        public var description: StaticString {
            switch self {
            case .powerOn: return "Power-on reset"
            case .software: return "Software reset"
            case .taskWatchdog: return "Task watchdog reset"
            case .deepSleep: return "Deep sleep reset"
            case .slcModule: return "Reset by SLC module"
            case .timerGroup0WDT: return "Timer Group0 WDT reset"
            case .timerGroup1WDT: return "Timer Group1 WDT reset"
            case .rtcWDT: return "RTC WDT reset"
            case .intrusionTest: return "Intrusion test reset"
            case .timeGroup: return "Time Group reset"
            case .softwareRestart: return "Software reset via esp_restart"
            case .rtcWDTBrownout: return "RTC WDT Brown-out reset"
            case .rtcWDTReset: return "RTC WDT reset"
            case .timerGroup0WDTReset: return "Timer Group0 WDT reset"
            case .rtcRWDTSystem: return "RTC RWDT system reset"
            }
        }

        public var isWatchdogReset: Bool {
            switch self {
            case .taskWatchdog, .timerGroup0WDT, .timerGroup1WDT, .rtcWDT,
                 .rtcWDTBrownout, .rtcWDTReset, .timerGroup0WDTReset, .rtcRWDTSystem:
                return true
            default:
                return false
            }
        }

        /// Print the reset reason description using putString
        public func printDescription() {
            switch self {
            case .powerOn: putString("Power-on reset")
            case .software: putString("Software reset")
            case .taskWatchdog: putString("Task watchdog reset")
            case .deepSleep: putString("Deep sleep reset")
            case .slcModule: putString("Reset by SLC module")
            case .timerGroup0WDT: putString("Timer Group0 WDT reset")
            case .timerGroup1WDT: putString("Timer Group1 WDT reset")
            case .rtcWDT: putString("RTC WDT reset")
            case .intrusionTest: putString("Intrusion test reset")
            case .timeGroup: putString("Time Group reset")
            case .softwareRestart: putString("Software reset via esp_restart")
            case .rtcWDTBrownout: putString("RTC WDT Brown-out reset")
            case .rtcWDTReset: putString("RTC WDT reset")
            case .timerGroup0WDTReset: putString("Timer Group0 WDT reset")
            case .rtcRWDTSystem: putString("RTC RWDT system reset")
            }
        }
    }
}