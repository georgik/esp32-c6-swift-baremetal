import MMIO
import Registers

// ESP32-C6 SPI Configuration
struct SPIConfig {
    let sckPin: UInt32      // Serial Clock
    let mosiPin: UInt32     // Master Out Slave In
    let misoPin: UInt32     // Master In Slave Out
    let csPin: UInt32       // Chip Select
    let dcPin: UInt32       // Data/Command pin for display
    let rstPin: UInt32      // Reset pin for display
    let clockFreq: UInt32   // Clock frequency in Hz
    let mode: UInt8         // SPI mode (0-3)
}

// Updated SPI configuration for ESP32-C6 with ILI9341 display
let defaultSPIConfig = SPIConfig(
    sckPin: 6,              // GPIO6 - SCK
    mosiPin: 7,             // GPIO7 - MOSI
    misoPin: 0,             // GPIO0 - MISO (unused)
    csPin: 20,              // GPIO20 - CS
    dcPin: 21,              // GPIO21 - DC (Data/Command)
    rstPin: 3,              // GPIO3 - RST (Reset)
    clockFreq: 40000000,    // 40MHz
    mode: 0                 // SPI Mode 0
)

func initializeSPI(config: SPIConfig = defaultSPIConfig) {
    putLine("=== ESP32-C6 GPIO/SPI Initialization ===")
    flushUART()

    // Step 1: Configure display control pins
    putLine("1. Configuring display control pins...")
    configureDisplayControlPins(config: config)

    // Step 2: Configure SPI GPIO pins
    putLine("2. Configuring SPI GPIO pins...")
    configureSPIGPIO(config: config)

    // Step 3: Print GPIO status for debugging
    putLine("3. GPIO Status Check:")
    printGPIOStatus(config: config)

    putLine("=== GPIO/SPI Initialization Complete ===")
    flushUART()
}

private func configureDisplayControlPins(config: SPIConfig) {
    // Configure DC pin as GPIO output - using same method as LED
    putLine("  Configuring DC pin...")
    configureGPIOAsOutput(pin: config.dcPin)
    setDisplayDC(high: false)  // Start in command mode

    // Configure RST pin as GPIO output - using same method as LED
    putLine("  Configuring RST pin...")
    configureGPIOAsOutput(pin: config.rstPin)
    setDisplayRST(high: true)  // Start with reset inactive
}

private func configureSPIGPIO(config: SPIConfig) {
    // Configure SCK pin as GPIO output - using same method as LED
    putLine("  Configuring SCK pin...")
    configureGPIOAsOutput(pin: config.sckPin)
    setSPIClock(high: false)  // Start with clock low

    // Configure MOSI pin as GPIO output - using same method as LED
    putLine("  Configuring MOSI pin...")
    configureGPIOAsOutput(pin: config.mosiPin)
    setSPIData(high: false)   // Start with data low

    // Configure CS pin as GPIO output - using same method as LED
    putLine("  Configuring CS pin...")
    configureGPIOAsOutput(pin: config.csPin)
    setSPICS(high: true)      // Start with CS inactive (high)
}

private func configureGPIOAsOutput(pin: UInt32) {
    putString("    Pin ")
    printSimpleNumber(UInt16(pin))
    putString(": ")

    // Step 1: Configure IO_MUX for GPIO function (EXACTLY like LED code)
    let ioMuxBase: UInt = 0x60009000
    let ioMuxOffset = getIOMuxOffset(pin: pin)
    let ioMuxReg = UnsafeMutablePointer<UInt32>(bitPattern: ioMuxBase + ioMuxOffset)!

    var ioMuxValue = ioMuxReg.pointee
    putString("IO_MUX(0x")
    printHex32(ioMuxValue)
    putString(") ")

    // Configure IO_MUX: GPIO function, output enable, proper drive strength (EXACTLY like LED)
    ioMuxValue &= ~0xF           // Clear function select (bits 0-3)
    ioMuxValue |= 0x1            // Set GPIO function (function 1)
    ioMuxValue &= ~(1 << 8)      // Enable output (OE=0, active low)
    ioMuxValue |= (2 << 10)      // Set drive strength to 2
    ioMuxReg.pointee = ioMuxValue

    putString("-> 0x")
    printHex32(ioMuxValue)

    // Step 2: Skip ROM calls entirely, use only MMIO

    // Step 3: Enable GPIO output using MMIO (EXACTLY like LED code)
    gpio.enable.modify { enable in
        let currentBits = UInt32(enable.raw.storage)
        let newBits = currentBits | (1 << pin)
        enable = .init(.init(newBits))
    }

    // Verify the enable register was set
    let enableValue = UInt32(gpio.enable.read().raw.storage)
    let isEnabled = (enableValue & (1 << pin)) != 0

    putString(", GPIO_EN: ")
    putString(isEnabled ? "SET" : "FAILED")
    putLine("")

    if !isEnabled {
        putString("    ERROR: GPIO ")
        printSimpleNumber(UInt16(pin))
        putString(" enable failed! Enable reg: 0x")
        printHex32(enableValue)
        putLine("")
    }
}

private func getIOMuxOffset(pin: UInt32) -> UInt {
    // ESP32-C6 IO_MUX register offsets for GPIO pins (same as LED code)
    switch pin {
    case 0: return 0x04
    case 1: return 0x08
    case 2: return 0x0C
    case 3: return 0x10
    case 4: return 0x14
    case 5: return 0x18
    case 6: return 0x1C
    case 7: return 0x20
    case 8: return 0x24   // LED pin
    case 9: return 0x28
    case 10: return 0x2C
    case 11: return 0x30
    case 20: return 0x54  // GPIO20
    case 21: return 0x58  // GPIO21
    default: return 0x04  // Default to GPIO0 offset
    }
}

private func printGPIOStatus(config: SPIConfig) {
    let enableValue = UInt32(gpio.enable.read().raw.storage)
    let outValue = UInt32(gpio.out.read().raw.storage)

    putString("  GPIO Enable: 0x")
    printHex32(enableValue)
    putLine("")
    putString("  GPIO Out: 0x")
    printHex32(outValue)
    putLine("")

    // Check expected pins
    let expectedPins: UInt32 = (1 << config.sckPin) | (1 << config.mosiPin) | (1 << config.csPin) | (1 << config.dcPin) | (1 << config.rstPin)
    putString("  Expected enable bits: 0x")
    printHex32(expectedPins)
    putLine("")

    // Check each SPI pin specifically
    let pins = [config.sckPin, config.mosiPin, config.csPin, config.dcPin, config.rstPin]

    for (i, pin) in pins.enumerated() {
        let enabled = (enableValue & (1 << pin)) != 0
        let outState = (outValue & (1 << pin)) != 0

        putString("  ")

        // Use individual putString calls with static strings
        switch i {
        case 0: putString("SCK")
        case 1: putString("MOSI")
        case 2: putString("CS")
        case 3: putString("DC")
        case 4: putString("RST")
        default: putString("UNK")
        }

        putString("(GPIO")
        printSimpleNumber(UInt16(pin))
        putString("): ")
        putString(enabled ? "OUT" : "IN")
        putString(", ")
        putString(outState ? "HIGH" : "LOW")

        if !enabled {
            putString(" ❌")
        }
        putLine("")
    }
}

// GPIO Control Functions - Using MMIO like the LED code
private func setGPIO(pin: UInt32, high: Bool) {
    if high {
        // Use the set register for atomic operation (same as LED code)
        gpio.out_w1ts.write { out_w1ts in
            out_w1ts = .init(.init(1 << pin))
        }
    } else {
        // Use the clear register for atomic operation (same as LED code)
        gpio.out_w1tc.write { out_w1tc in
            out_w1tc = .init(.init(1 << pin))
        }
    }
}

// Display Control Functions
func setDisplayDC(high: Bool) {
    setGPIO(pin: defaultSPIConfig.dcPin, high: high)
}

func setDisplayRST(high: Bool) {
    setGPIO(pin: defaultSPIConfig.rstPin, high: high)
}

// SPI Signal Control Functions
private func setSPIClock(high: Bool) {
    setGPIO(pin: defaultSPIConfig.sckPin, high: high)
}

private func setSPIData(high: Bool) {
    setGPIO(pin: defaultSPIConfig.mosiPin, high: high)
}

private func setSPICS(high: Bool) {
    setGPIO(pin: defaultSPIConfig.csPin, high: high)
}


// Enhanced SPI Implementation with slower timing for real hardware
func sendSPIByte(_ data: UInt8) {
    var byte = data

    // Assert CS (active low)
    setSPICS(high: false)
    delayMicroseconds(10)  // Increased delay

    // Send 8 bits, MSB first
    for _ in 0..<8 {
        // Set data line (MOSI)
        let bitValue = (byte & 0x80) != 0
        setSPIData(high: bitValue)

        delayMicroseconds(10) // Increased setup time

        // Clock pulse (rising edge for Mode 0)
        setSPIClock(high: true)
        delayMicroseconds(10) // Increased clock high time
        setSPIClock(high: false)
        delayMicroseconds(10) // Increased clock low time

        byte <<= 1 // Shift to next bit
    }

    // Deassert CS
    delayMicroseconds(10)
    setSPICS(high: true)
    delayMicroseconds(10)
}

// Send multiple bytes via SPI
func sendSPIBytes(_ data: [UInt8]) {
    for byte in data {
        sendSPIByte(byte)
    }
}

// Send 16-bit data (for RGB565 colors)
func sendSPIWord(_ data: UInt16) {
    sendSPIByte(UInt8(data >> 8))   // High byte first
    sendSPIByte(UInt8(data & 0xFF)) // Low byte
}

// Display Communication Functions
func sendDisplayCommand(_ cmd: UInt8) {
    setDisplayDC(high: false)  // Command mode
    sendSPIByte(cmd)
}

func sendDisplayData(_ data: UInt8) {
    setDisplayDC(high: true)   // Data mode
    sendSPIByte(data)
}

func sendDisplayData16(_ data: UInt16) {
    setDisplayDC(high: true)   // Data mode
    sendSPIByte(UInt8(data >> 8))    // High byte
    sendSPIByte(UInt8(data & 0xFF))  // Low byte
}