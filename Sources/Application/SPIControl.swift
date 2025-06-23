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

// ESP32-C6 System Registers
private let GPIO_BASE: UInt = 0x60004000
private let IO_MUX_BASE: UInt = 0x60009000
private let SYSTEM_BASE: UInt = 0x60026000

// System clock control registers
private let SYSTEM_PERIP_CLK_EN0_REG = SYSTEM_BASE + 0x018
private let SYSTEM_PERIP_RST_EN0_REG = SYSTEM_BASE + 0x01C

// GPIO clock enable bits
private let SYSTEM_GPIO_CLK_EN: UInt32 = (1 << 16)

func initializeSPI(config: SPIConfig = defaultSPIConfig) {
    putLine("=== ESP32-C6 GPIO/SPI Initialization ===")
    flushUART()

    // Step 1: Enable GPIO peripheral clock
    putLine("1. Enabling GPIO peripheral clock...")
    enableGPIOClock()

    // Step 2: Configure display control pins
    putLine("2. Configuring display control pins...")
    configureDisplayControlPins(config: config)

    // Step 3: Configure SPI GPIO pins with proper IO_MUX settings
    putLine("3. Configuring SPI GPIO pins...")
    configureSPIGPIO(config: config)

    // Step 4: Print GPIO status for debugging
    putLine("4. GPIO Status Check:")
    printGPIOStatus(config: config)

    putLine("=== GPIO/SPI Initialization Complete ===")
    flushUART()
}

private func enableGPIOClock() {
    let clkEnReg = UnsafeMutablePointer<UInt32>(bitPattern: SYSTEM_PERIP_CLK_EN0_REG)!
    let rstEnReg = UnsafeMutablePointer<UInt32>(bitPattern: SYSTEM_PERIP_RST_EN0_REG)!

    // Enable GPIO clock
    var clkValue = clkEnReg.pointee
    clkValue |= SYSTEM_GPIO_CLK_EN
    clkEnReg.pointee = clkValue

    // Clear GPIO reset (enable)
    var rstValue = rstEnReg.pointee
    rstValue &= ~SYSTEM_GPIO_CLK_EN
    rstEnReg.pointee = rstValue

    putLine("  GPIO clock enabled")
}

private func configureDisplayControlPins(config: SPIConfig) {
    // Configure DC pin as GPIO output
    putLine("  Configuring DC pin...")
    configureGPIOAsOutput(pin: config.dcPin)
    setDisplayDC(high: false)  // Start in command mode

    // Configure RST pin as GPIO output
    putLine("  Configuring RST pin...")
    configureGPIOAsOutput(pin: config.rstPin)
    setDisplayRST(high: true)  // Start with reset inactive
}

private func configureSPIGPIO(config: SPIConfig) {
    // Configure SCK pin as GPIO output
    putLine("  Configuring SCK pin...")
    configureGPIOAsOutput(pin: config.sckPin)
    setSPIClock(high: false)  // Start with clock low

    // Configure MOSI pin as GPIO output
    putLine("  Configuring MOSI pin...")
    configureGPIOAsOutput(pin: config.mosiPin)
    setSPIData(high: false)   // Start with data low

    // Configure CS pin as GPIO output
    putLine("  Configuring CS pin...")
    configureGPIOAsOutput(pin: config.csPin)
    setSPICS(high: true)      // Start with CS inactive (high)
}

private func configureGPIOAsOutput(pin: UInt32) {
    // Step 1: Configure IO_MUX for GPIO function
    let ioMuxOffset = getIOMuxOffset(pin: pin)
    let ioMuxReg = UnsafeMutablePointer<UInt32>(bitPattern: IO_MUX_BASE + ioMuxOffset)!

    putString("    Pin ")
    printSimpleNumber(UInt16(pin))
    putString(": IO_MUX offset 0x")
    printHex32(UInt32(ioMuxOffset))

    // Read current value
    let currentIOMux = ioMuxReg.pointee
    putString(", current: 0x")
    printHex32(currentIOMux)

    // Configure IO_MUX: GPIO function, output enable, proper drive strength
    var ioMuxValue = currentIOMux
    ioMuxValue &= ~0xF           // Clear function select (bits 0-3)
    ioMuxValue |= 0x1            // Set GPIO function (function 1)
    ioMuxValue &= ~(1 << 8)      // Clear input enable for output
    ioMuxValue &= ~(1 << 9)      // Clear pull-up
    ioMuxValue &= ~(1 << 10)     // Clear pull-down
    ioMuxValue |= (2 << 11)      // Set drive strength to 2 (medium)
    ioMuxReg.pointee = ioMuxValue

    putString(", new: 0x")
    printHex32(ioMuxValue)
    putLine("")

    // Step 2: Configure GPIO direction as output
    let enableReg = UnsafeMutablePointer<UInt32>(bitPattern: GPIO_BASE + 0x0020)!  // GPIO_ENABLE_REG
    var enableValue = enableReg.pointee
    enableValue |= (1 << pin)
    enableReg.pointee = enableValue

    // Step 3: Clear any pull-up/pull-down in GPIO registers
    let pullUpReg = UnsafeMutablePointer<UInt32>(bitPattern: GPIO_BASE + 0x0074)!   // GPIO_PIN_REG base
    let pullDownReg = UnsafeMutablePointer<UInt32>(bitPattern: GPIO_BASE + 0x0078)! // GPIO_PIN_REG base

    // Clear pull-up and pull-down for this pin
    var pullUpValue = pullUpReg.pointee
    var pullDownValue = pullDownReg.pointee
    pullUpValue &= ~(1 << pin)
    pullDownValue &= ~(1 << pin)
    pullUpReg.pointee = pullUpValue
    pullDownReg.pointee = pullDownValue
}

private func getIOMuxOffset(pin: UInt32) -> UInt {
    // ESP32-C6 IO_MUX register offsets for GPIO pins
    switch pin {
    case 0: return 0x04
    case 1: return 0x08
    case 2: return 0x0C
    case 3: return 0x10
    case 4: return 0x14
    case 5: return 0x18
    case 6: return 0x1C
    case 7: return 0x20
    case 8: return 0x24
    case 9: return 0x28
    case 10: return 0x2C
    case 11: return 0x30
    case 20: return 0x54  // GPIO20
    case 21: return 0x58  // GPIO21
    default: return 0x04  // Default to GPIO0 offset
    }
}

private func printGPIOStatus(config: SPIConfig) {
    let enableReg = UnsafePointer<UInt32>(bitPattern: GPIO_BASE + 0x0020)!
    let outReg = UnsafePointer<UInt32>(bitPattern: GPIO_BASE + 0x0004)!

    let enableValue = enableReg.pointee
    let outValue = outReg.pointee

    putString("  GPIO Enable: 0x")
    printHex32(enableValue)
    putLine("")
    putString("  GPIO Out: 0x")
    printHex32(outValue)
    putLine("")

    // Check each SPI pin specifically - use static strings to avoid conversion issues
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
        putLine("")
    }
}

// GPIO Control Functions
private func setGPIO(pin: UInt32, high: Bool) {
    let outReg = UnsafeMutablePointer<UInt32>(bitPattern: GPIO_BASE + 0x0004)!  // GPIO_OUT_REG
    var outValue = outReg.pointee

    if high {
        outValue |= (1 << pin)   // Set bit
    } else {
        outValue &= ~(1 << pin)  // Clear bit
    }
    outReg.pointee = outValue
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

// Bit-bang SPI Implementation
func sendSPIByte(_ data: UInt8) {
    var byte = data

    // Assert CS (active low)
    setSPICS(high: false)
    delayMicroseconds(1)

    // Send 8 bits, MSB first
    for _ in 0..<8 {
        // Set data line (MOSI)
        if (byte & 0x80) != 0 {
            setSPIData(high: true)
        } else {
            setSPIData(high: false)
        }

        delayMicroseconds(1) // Setup time

        // Clock pulse (rising edge for Mode 0)
        setSPIClock(high: true)
        delayMicroseconds(1)
        setSPIClock(high: false)
        delayMicroseconds(1)

        byte <<= 1 // Shift to next bit
    }

    // Deassert CS
    delayMicroseconds(1)
    setSPICS(high: true)
    delayMicroseconds(1)
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