
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
    clockFreq: SPIClockFreq.FREQ_10MHZ,
    mode: SPIMode.MODE_0
)

// GPIO base address for ESP32-C6
private let GPIO_BASE: UInt = 0x60004000
private let IO_MUX_BASE: UInt = 0x60009000

func initializeSPI(config: SPIConfig = defaultSPIConfig) {
    putLine("=== ESP32-C6 SPI Display Initialization ===")
    flushUART()

    // Step 1: Configure display control pins first
    putLine("Step 1: Configuring display control pins...")
    configureDisplayControlPins(config: config)

    // Step 2: Configure GPIO pins for bit-bang SPI
    putLine("Step 2: Configuring SPI GPIO pins...")
    configureSPIGPIO(config: config)

    putLine("=== SPI Display Initialization Complete ===")
    flushUART()
}

private func configureDisplayControlPins(config: SPIConfig) {
    // Configure DC pin as output
    putLine("  Configuring DC pin...")
    configureGPIOAsOutput(pin: config.dcPin)
    setDisplayDC(high: false)  // Start in command mode
    putLine("  DC done")

    // Configure RST pin as output
    putLine("  Configuring RST pin...")
    configureGPIOAsOutput(pin: config.rstPin)
    setDisplayRST(high: true)  // Start with reset inactive
    putLine("  RST done")
}

private func configureSPIGPIO(config: SPIConfig) {
    // Configure SCK pin as output
    putLine("  Configuring SCK pin...")
    configureGPIOAsOutput(pin: config.sckPin)
    setSPIClock(high: false)  // Start with clock low
    putLine("  SCK done")

    // Configure MOSI pin as output
    putLine("  Configuring MOSI pin...")
    configureGPIOAsOutput(pin: config.mosiPin)
    setSPIData(high: false)   // Start with data low
    putLine("  MOSI done")

    // Configure CS pin as output
    putLine("  Configuring CS pin...")
    configureGPIOAsOutput(pin: config.csPin)
    setSPICS(high: true)      // Start with CS inactive (high)
    putLine("  CS done")
}

private func configureGPIOAsOutput(pin: UInt32) {
    // Configure GPIO direction as output
    let enableReg = UnsafeMutablePointer<UInt32>(bitPattern: GPIO_BASE + 0x0020)!  // GPIO_ENABLE_REG
    var enableValue = enableReg.pointee
    enableValue |= (1 << pin)
    enableReg.pointee = enableValue

    // Configure IO_MUX for GPIO function
    let ioMuxOffset = getIOMapOffset(pin: pin)
    let ioMuxReg = UnsafeMutablePointer<UInt32>(bitPattern: IO_MUX_BASE + ioMuxOffset)!

    var ioMuxValue = ioMuxReg.pointee
    ioMuxValue &= ~0xF           // Clear function select
    ioMuxValue |= 0x1            // Set GPIO function
    ioMuxValue &= ~(1 << 8)      // Enable output (OE=0, active low)
    ioMuxValue |= (2 << 10)      // Set drive strength
    ioMuxReg.pointee = ioMuxValue
}

private func getIOMapOffset(pin: UInt32) -> UInt {
    // ESP32-C6 IO_MUX register offsets for different GPIO pins
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

// ILI9341 Display Test Function
func testSPIDisplay() {
    putLine("=== ILI9341 Display Test ===")

    // Initialize SPI
    initializeSPI()

    // Hardware reset sequence
    putLine("Performing display reset...")
    setDisplayRST(high: false)
    delayMilliseconds(10)
    setDisplayRST(high: true)
    delayMilliseconds(120)

    putLine("Sending ILI9341 initialization commands...")

    // Basic ILI9341 initialization sequence
    sendDisplayCommand(0x01)  // Software reset
    delayMilliseconds(150)

    sendDisplayCommand(0x11)  // Sleep out
    delayMilliseconds(120)

    sendDisplayCommand(0x3A)  // Pixel format
    sendDisplayData(0x55)     // 16-bit color

    sendDisplayCommand(0x29)  // Display on
    delayMilliseconds(50)

    putLine("Display initialized successfully!")

    // Test pattern - fill screen with red
    putLine("Drawing test pattern...")

    sendDisplayCommand(0x2A)  // Column address set
    sendDisplayData(0x00)     // Start column high
    sendDisplayData(0x00)     // Start column low
    sendDisplayData(0x00)     // End column high
    sendDisplayData(0xEF)     // End column low (239)

    sendDisplayCommand(0x2B)  // Page address set
    sendDisplayData(0x00)     // Start page high
    sendDisplayData(0x00)     // Start page low
    sendDisplayData(0x01)     // End page high
    sendDisplayData(0x3F)     // End page low (319)

    sendDisplayCommand(0x2C)  // Memory write

    // Send red pixels (simplified test)
    putLine("Filling with red pixels...")
    for _ in 0..<1000 {
        sendDisplayData16(0xF800)  // Red color in RGB565
    }

    putLine("=== Display Test Complete ===")
    flushUART()
}

// Helper function to print hex values
func printHex8(_ value: UInt8) {
    let hexChars: [UInt8] = [
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57,  // '0'-'9'
        97, 98, 99, 100, 101, 102                // 'a'-'f'
    ]

    let high = Int(value >> 4)
    let low = Int(value & 0x0F)

    putChar(hexChars[high])
    putChar(hexChars[low])
}