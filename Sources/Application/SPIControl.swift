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
    misoPin: 2,             // GPIO2 - MISO
    csPin: 10,              // GPIO10 - CS
    dcPin: 4,               // GPIO4 - DC (Data/Command)
    rstPin: 5,              // GPIO5 - RST (Reset)
    clockFreq: SPIClockFreq.FREQ_10MHZ,  // Higher frequency for display
    mode: SPIMode.MODE_0
)

// SPI0 peripheral instance (using generated registers)
private let spi0 = SPI0(unsafeAddress: 0x60003000)

// IO_MUX base for pin configuration
private let IO_MUX_BASE: UInt = 0x60009000

func initializeSPI(config: SPIConfig = defaultSPIConfig) {
    putLine("=== ESP32-C6 SPI Display Initialization ===")
    flushUART()

    // Step 1: Configure display control pins first
    putLine("Step 1: Configuring display control pins...")
    configureDisplayControlPins(config: config)

    // Step 2: Configure GPIO pins for SPI function
    putLine("Step 2: Configuring SPI GPIO pins...")
    configureSPIGPIO(config: config)

    // Step 3: Reset SPI peripheral
    putLine("Step 3: Resetting SPI peripheral...")
    resetSPI()

    // Step 4: Configure SPI clock
    putLine("Step 4: Configuring SPI clock...")
    configureSPIClock(frequency: config.clockFreq)

    // Step 5: Configure SPI mode and data format
    putLine("Step 5: Configuring SPI mode...")
    configureSPIMode(mode: config.mode)

    // Step 6: Enable SPI master mode
    putLine("Step 6: Enabling SPI master mode...")
    enableSPIMaster()

    putLine("=== SPI Display Initialization Complete ===")
    flushUART()
}

private func configureDisplayControlPins(config: SPIConfig) {
    // Configure DC pin as output
    putLine("  Configuring DC pin...")
    putString("  DC GPIO: ")
    putChar(UInt8(48 + UInt8(config.dcPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.dcPin)
    _ = esp_rom_gpio_pad_select_gpio(config.dcPin)
    esp_rom_gpio_pad_unhold(config.dcPin)
    esp_rom_gpio_pad_set_drv(config.dcPin, 2)
    // Set as simple GPIO output (not connected to SPI matrix)
    esp_rom_gpio_connect_out_signal(config.dcPin, SPISignals.GPIO_OUT_IDX, false, false)
    setDisplayDC(high: false)  // Start in command mode
    putLine("  DC done")

    // Configure RST pin as output
    putLine("  Configuring RST pin...")
    putString("  RST GPIO: ")
    putChar(UInt8(48 + UInt8(config.rstPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.rstPin)
    _ = esp_rom_gpio_pad_select_gpio(config.rstPin)
    esp_rom_gpio_pad_unhold(config.rstPin)
    esp_rom_gpio_pad_set_drv(config.rstPin, 2)
    // Set as simple GPIO output (not connected to SPI matrix)
    esp_rom_gpio_connect_out_signal(config.rstPin, SPISignals.GPIO_OUT_IDX, false, false)
    setDisplayRST(high: true)  // Start with reset inactive
    putLine("  RST done")
}

private func configureSPIGPIO(config: SPIConfig) {
    // Configure SCK pin
    putLine("  Configuring SCK pin...")
    putString("  SCK GPIO: ")
    putChar(UInt8(48 + UInt8(config.sckPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.sckPin)
    _ = esp_rom_gpio_pad_select_gpio(config.sckPin)
    esp_rom_gpio_pad_unhold(config.sckPin)
    esp_rom_gpio_pad_set_drv(config.sckPin, 2)
    esp_rom_gpio_connect_out_signal(config.sckPin, SPISignals.SPI2_CLK_OUT_IDX, false, false)
    putLine("  SCK done")

    // Configure MOSI pin
    putLine("  Configuring MOSI pin...")
    putString("  MOSI GPIO: ")
    putChar(UInt8(48 + UInt8(config.mosiPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.mosiPin)
    _ = esp_rom_gpio_pad_select_gpio(config.mosiPin)
    esp_rom_gpio_pad_unhold(config.mosiPin)
    esp_rom_gpio_pad_set_drv(config.mosiPin, 2)
    esp_rom_gpio_connect_out_signal(config.mosiPin, SPISignals.SPI2_MOSI_OUT_IDX, false, false)
    putLine("  MOSI done")

    // Configure CS pin
    putLine("  Configuring CS pin...")
    putString("  CS GPIO: ")
    putChar(UInt8(48 + UInt8(config.csPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.csPin)
    _ = esp_rom_gpio_pad_select_gpio(config.csPin)
    esp_rom_gpio_pad_unhold(config.csPin)
    esp_rom_gpio_pad_set_drv(config.csPin, 2)
    esp_rom_gpio_connect_out_signal(config.csPin, SPISignals.SPI2_CS_OUT_IDX, false, false)
    putLine("  CS done")

    // Configure MISO input pin (for completeness, though display may not use it)
    putLine("  Configuring MISO input pin...")
    putString("  MISO GPIO: ")
    putChar(UInt8(48 + UInt8(config.misoPin % 10)))
    putLine("")
    configureIOMapForGPIO(pin: config.misoPin)
    _ = esp_rom_gpio_pad_select_gpio(config.misoPin)
    esp_rom_gpio_pad_unhold(config.misoPin)
    esp_rom_gpio_connect_in_signal(config.misoPin, SPISignals.SPI2_MISO_IN_IDX, false)
    putLine("  MISO done")
}

private func configureIOMapForGPIO(pin: UInt32) {
    // Calculate IO_MUX register address for the pin
    let ioMuxOffset = getIOMapOffset(pin: pin)
    let ioMuxReg = UnsafeMutablePointer<UInt32>(bitPattern: IO_MUX_BASE + ioMuxOffset)!

    var ioMuxValue = ioMuxReg.pointee
    // Configure for GPIO function
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
    default: return 0x04  // Default to GPIO0 offset
    }
}

private func resetSPI() {
    // Reset SPI peripheral using user register
    spi0.user.write { user in
        user = .init(.init(0))  // Clear all user settings
    }

    // Reset control registers
    spi0.ctrl.write { ctrl in
        ctrl = .init(.init(0))
    }

    putLine("  SPI peripheral reset complete")
}

private func configureSPIClock(frequency: UInt32) {
    // ESP32-C6 APB clock is typically 80MHz
    let apbClockHz: UInt32 = 80_000_000
    let divider = (apbClockHz + frequency - 1) / frequency  // Round up division

    putLine("  Setting SPI clock...")
    putString("  Target frequency: ")
    // Display frequency in MHz (assuming it's in the MHz range)
    let freqMHz = frequency / 1_000_000
    if freqMHz < 10 {
        putChar(UInt8(48 + UInt8(freqMHz)))
    } else {
        putChar(UInt8(48 + UInt8(freqMHz / 10)))
        putChar(UInt8(48 + UInt8(freqMHz % 10)))
    }
    putLine("MHz")

    // Configure clock divider
    spi0.clock.write { clock in
        var clockValue: UInt32 = 0

        // Set clock divider values
        let clkdiv = divider - 1
        clockValue |= (clkdiv & 0x3F) << 12    // clkdiv_pre
        clockValue |= (clkdiv & 0x3F) << 6     // clkdiv_n
        clockValue |= (clkdiv & 0x3F)          // clkdiv_l

        clock = .init(.init(clockValue))
    }

    putLine("  Clock configured")
}

private func configureSPIMode(mode: UInt8) {
    putLine("  Setting SPI mode...")
    putString("  Mode: ")
    putChar(UInt8(48 + mode))
    putLine("")

    spi0.misc.write { misc in
        var miscValue: UInt32 = 0

        // Configure CPOL and CPHA based on mode
        switch mode {
        case SPIMode.MODE_0:  // CPOL=0, CPHA=0
            break
        case SPIMode.MODE_1:  // CPOL=0, CPHA=1
            miscValue |= (1 << 6)  // Set CPHA
        case SPIMode.MODE_2:  // CPOL=1, CPHA=0
            miscValue |= (1 << 5)  // Set CPOL
        case SPIMode.MODE_3:  // CPOL=1, CPHA=1
            miscValue |= (1 << 5) | (1 << 6)  // Set both CPOL and CPHA
        default:
            break
        }

        misc = .init(.init(miscValue))
    }

    putLine("  Mode configured")
}

private func enableSPIMaster() {
    // Configure SPI in master mode
    spi0.user.write { user in
        var userValue: UInt32 = 0

        // Enable SPI master mode
        userValue |= (1 << 18)   // SPI_USR_MOSI (enable MOSI)
        userValue |= (1 << 17)   // SPI_USR_MISO (enable MISO)
        userValue |= (1 << 6)    // SPI_CS_SETUP (CS setup time)
        userValue |= (1 << 5)    // SPI_CS_HOLD (CS hold time)

        user = .init(.init(userValue))
    }

    // Configure master mode in ctrl register
    spi0.ctrl.write { ctrl in
        var ctrlValue: UInt32 = 0
        ctrlValue |= (1 << 18)   // SPI_WR_BIT_ORDER (MSB first)
        ctrlValue |= (1 << 17)   // SPI_RD_BIT_ORDER (MSB first)
        ctrl = .init(.init(ctrlValue))
    }

    putLine("  SPI master mode enabled")
}

// Display control functions
func setDisplayDC(high: Bool) {
    // Use direct GPIO register access for DC control
    let gpioBase: UInt = 0x60004000
    let outReg = UnsafeMutablePointer<UInt32>(bitPattern: gpioBase + 0x0004)!  // GPIO_OUT_REG

    var outValue = outReg.pointee
    if high {
        outValue |= (1 << defaultSPIConfig.dcPin)   // Set bit
    } else {
        outValue &= ~(1 << defaultSPIConfig.dcPin)  // Clear bit
    }
    outReg.pointee = outValue
}

func setDisplayRST(high: Bool) {
    // Use direct GPIO register access for RST control
    let gpioBase: UInt = 0x60004000
    let outReg = UnsafeMutablePointer<UInt32>(bitPattern: gpioBase + 0x0004)!  // GPIO_OUT_REG

    var outValue = outReg.pointee
    if high {
        outValue |= (1 << defaultSPIConfig.rstPin)   // Set bit
    } else {
        outValue &= ~(1 << defaultSPIConfig.rstPin)  // Clear bit
    }
    outReg.pointee = outValue
}

// Display communication functions
func sendDisplayCommand(_ cmd: UInt8) {
    setDisplayDC(high: false)  // Command mode
    _ = spiTransferByte(cmd)
}

func sendDisplayData(_ data: UInt8) {
    setDisplayDC(high: true)   // Data mode
    _ = spiTransferByte(data)
}

func sendDisplayData16(_ data: UInt16) {
    setDisplayDC(high: true)   // Data mode
    _ = spiTransferByte(UInt8(data >> 8))    // High byte
    _ = spiTransferByte(UInt8(data & 0xFF))  // Low byte
}

// SPI Transfer functions - using direct register access since w0 might not be in generated code
func spiTransferByte(_ data: UInt8) -> UInt8 {
    // Wait for SPI to be ready
    while spi0.cmd.read().raw.storage & (1 << 18) != 0 {
        // Wait for USR command to complete
    }

    // Write data to W0 register using direct access
    let spiBase: UInt = 0x60003000
    let w0Reg = UnsafeMutablePointer<UInt32>(bitPattern: spiBase + 0x98)!  // W0 register offset
    w0Reg.pointee = UInt32(data)

    // Configure transfer length (8 bits)
    spi0.user1.write { user1 in
        var user1Value: UInt32 = 0
        user1Value |= ((8 - 1) << 0)   // MOSI bit length
        user1Value |= ((8 - 1) << 8)   // MISO bit length
        user1 = .init(.init(user1Value))
    }

    // Start transfer
    spi0.cmd.write { cmd in
        cmd = .init(.init(1 << 18))  // Set USR command
    }

    // Wait for transfer to complete
    while spi0.cmd.read().raw.storage & (1 << 18) != 0 {
        // Wait for completion
    }

    // Read received data
    let receivedData = w0Reg.pointee
    return UInt8(receivedData & 0xFF)
}

// ILI9341 Display initialization and test
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
    for _ in 0..<100 {
        sendDisplayData16(0xF800)  // Red color in RGB565
    }

    putLine("=== Display Test Complete ===")
    flushUART()
}

// Helper function to print hex values - Embedded Swift compatible
func printHex8(_ value: UInt8) {
    // Use lookup table approach instead of String indexing
    let hexChars: [UInt8] = [
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57,  // '0'-'9'
        97, 98, 99, 100, 101, 102                // 'a'-'f'
    ]

    let high = Int(value >> 4)
    let low = Int(value & 0x0F)

    putChar(hexChars[high])
    putChar(hexChars[low])
}