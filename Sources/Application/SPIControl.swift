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
// FIXED: Reduced clock frequency and added timing diagnostics
let defaultSPIConfig = SPIConfig(
    sckPin: 6,              // GPIO6 - SCK
    mosiPin: 7,             // GPIO7 - MOSI
    misoPin: 0,             // GPIO0 - MISO (unused)
    csPin: 20,              // GPIO20 - CS
    dcPin: 21,              // GPIO21 - DC (Data/Command)
    rstPin: 3,              // GPIO3 - RST (Reset)
    clockFreq: 10000000,    // REDUCED: 10MHz (was 40MHz - too fast for some displays)
    mode: 0                 // SPI Mode 0
)

func initializeSPI(config: SPIConfig = defaultSPIConfig) {
    putLine("=== ESP32-C6 GPIO/SPI Initialization ===")
    flushUART()

    // CRITICAL: Power-on sequencing delay
    putLine("Power-on sequence: Waiting for GPIO stabilization...")
    delayMilliseconds(100)  // Let GPIO system stabilize
    flushUART()

    // Step 1: Enable GPIO and SPI peripheral power domains
    putLine("1. Enabling power domains...")
    enablePowerDomains()
    delayMilliseconds(50)
    flushUART()

    // Step 2: Configure GPIO matrix for SPI routing
    putLine("2. Configuring GPIO matrix...")
    configureGPIOMatrix(config: config)
    delayMilliseconds(50)
    flushUART()

    // Step 3: Configure display control pins with power-on sequence
    putLine("3. Configuring display control pins...")
    configureDisplayControlPins(config: config)
    
    // CRITICAL: Delay after control pin configuration
    putLine("   Waiting for control pins to stabilize...")
    delayMilliseconds(50)
    flushUART()

    // Step 4: Configure SPI GPIO pins
    putLine("4. Configuring SPI GPIO pins...")
    configureSPIGPIO(config: config)
    
    // CRITICAL: Delay after SPI pin configuration
    putLine("   Waiting for SPI pins to stabilize...")
    delayMilliseconds(50)
    flushUART()

    // Step 5: Print GPIO status for debugging
    putLine("5. GPIO Status Check:")
    printGPIOStatus(config: config)
    
    // CRITICAL: Final stabilization delay before display operations
    putLine("Final GPIO/SPI stabilization...")
    delayMilliseconds(200)  // Extra time for all pins to be ready
    flushUART()

    putLine("=== GPIO/SPI Initialization Complete ===")
    flushUART()
}

private func configureDisplayControlPins(config: SPIConfig) {
    // Configure DC pin as GPIO output - using same method as LED
    putLine("  Configuring DC pin...")
    configureGPIOAsOutput(pin: config.dcPin)
    setDisplayDC(high: false)  // Start in command mode

    // CRITICAL: Configure RST pin as GPIO output with special attention
    putLine("  Configuring RST pin (CRITICAL for display)...")
    putString("  RST pin pre-config test: GPIO")
    printSimpleNumber(UInt16(config.rstPin))
    putLine("")
    
    // Check if GPIO3 has any special considerations on ESP32-C6
    if config.rstPin == 3 {
        putLine("  WARNING: GPIO3 on ESP32-C6 - checking for special constraints...")
        // GPIO3 might have special boot constraints on ESP32-C6
        checkGPIO3Constraints()
    }
    
    configureGPIOAsOutput(pin: config.rstPin)
    
    // Test the RST pin immediately after configuration
    putLine("  RST pin post-config test...")
    testRSTPin(config: config)
    
    setDisplayRST(high: true)  // Start with reset inactive
    
    // Verify RST pin is actually high
    delayMilliseconds(10)
    let rstState = getGPIOState(pin: config.rstPin)
    putString("  RST initial state: ")
    putString(rstState ? "HIGH (good)" : "LOW (ERROR!)")
    putLine("")
    
    if !rstState {
        putLine("  ERROR: RST pin failed to go HIGH! Display won't work!")
        flushUART()
    }
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

    // Step 2: Use ROM functions for proper pad configuration (like LED code)
    let _ = esp_rom_gpio_pad_select_gpio(pin)  // Pad configuration result
    esp_rom_gpio_pad_unhold(pin)
    esp_rom_gpio_pad_set_drv(pin, 2)  // Medium drive strength
    esp_rom_gpio_connect_out_signal(pin, 128, false, false)  // GPIO_OUT_IDX = 128

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

    for i in 0..<pins.count {
        let pin = pins[i]
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
            putString(" [ERROR]")
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


// Enhanced SPI Implementation with ultra-conservative timing for real hardware
func sendSPIByte(_ data: UInt8) {
    var byte = data

    // Assert CS (active low) with extended setup time
    setSPICS(high: false)
    delayMicroseconds(100)  // Much longer CS setup time

    // Send 8 bits, MSB first
    for _ in 0..<8 {
        // Set data line (MOSI) with extended setup
        let bitValue = (byte & 0x80) != 0
        setSPIData(high: bitValue)

        delayMicroseconds(100) // Much longer data setup time

        // Clock pulse (rising edge for Mode 0) with extended timing
        setSPIClock(high: true)
        delayMicroseconds(100) // Much longer clock high time
        setSPIClock(high: false)
        delayMicroseconds(100) // Much longer clock low time

        byte <<= 1 // Shift to next bit
    }

    // Deassert CS with extended hold time
    delayMicroseconds(100)
    setSPICS(high: true)
    delayMicroseconds(100) // Extended CS release time
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

// CRITICAL GPIO3 DIAGNOSTIC FUNCTIONS

// Check for GPIO3 specific constraints on ESP32-C6
func checkGPIO3Constraints() {
    putLine("    GPIO3 ESP32-C6 constraint check:")
    
    // Check if GPIO3 is available (not strapped for boot)
    // On ESP32-C6, GPIO3 might be used for JTAG or other functions
    let _ = UnsafeMutablePointer<UInt32>(bitPattern: 0x60009000)!  // IO_MUX base
    let gpio3Mux = UnsafeMutablePointer<UInt32>(bitPattern: 0x60009010)!    // GPIO3 IO_MUX
    
    let muxValue = gpio3Mux.pointee
    putString("    GPIO3 IO_MUX value: 0x")
    printHex32(muxValue)
    putLine("")
    
    // Check if GPIO3 is in a usable state
    let function = muxValue & 0xF
    putString("    GPIO3 function: ")
    printSimpleNumber(UInt16(function))
    if function != 1 {
        putLine(" (WARNING: Not GPIO function!)")
    } else {
        putLine(" (GPIO function - good)")
    }
    
    // Check pull-up/down configuration
    let pullUp = (muxValue & (1 << 7)) != 0
    let pullDown = (muxValue & (1 << 6)) != 0
    putString("    GPIO3 pulls: ")
    if pullUp {
        putString("UP ")
    }
    if pullDown {
        putString("DOWN ")
    }
    if !pullUp && !pullDown {
        putString("NONE ")
    }
    putLine("")
    
    // Check drive strength
    let driveStrength = (muxValue >> 10) & 0x3
    putString("    GPIO3 drive strength: ")
    printSimpleNumber(UInt16(driveStrength))
    putLine("")
    
    flushUART()
}

// Test RST pin functionality
func testRSTPin(config: SPIConfig) {
    putLine("    RST pin functionality test:")
    
    // Test 1: Set RST low
    putString("    Setting RST LOW... ")
    setDisplayRST(high: false)
    delayMilliseconds(10)
    let lowState = getGPIOState(pin: config.rstPin)
    putString(lowState ? "FAILED (still HIGH)" : "OK (LOW)")
    putLine("")
    
    // Test 2: Set RST high
    putString("    Setting RST HIGH... ")
    setDisplayRST(high: true)
    delayMilliseconds(10)
    let highState = getGPIOState(pin: config.rstPin)
    putString(highState ? "OK (HIGH)" : "FAILED (still LOW)")
    putLine("")
    
    // Test 3: Multiple toggles
    putString("    RST toggle test: ")
    var toggleOK = true
    for _ in 0..<3 {
        setDisplayRST(high: false)
        delayMicroseconds(1000)
        let low = getGPIOState(pin: config.rstPin)
        
        setDisplayRST(high: true)
        delayMicroseconds(1000)
        let high = getGPIOState(pin: config.rstPin)
        
        if low || !high {
            toggleOK = false
            break
        }
    }
    putString(toggleOK ? "PASS" : "FAIL")
    putLine("")
    
    if !toggleOK {
        putLine("    ERROR: RST pin not responding! Check wiring!")
        
        // Detailed register dump for GPIO3
        putLine("    GPIO3 register dump:")
        let enableValue = UInt32(gpio.enable.read().raw.storage)
        let outValue = UInt32(gpio.out.read().raw.storage)
        let inValue = UInt32(gpio.`in`.read().raw.storage)
        
        putString("      ENABLE[3]: ")
        putString((enableValue & (1 << config.rstPin)) != 0 ? "1" : "0")
        putLine("")
        
        putString("      OUT[3]: ")
        putString((outValue & (1 << config.rstPin)) != 0 ? "1" : "0")
        putLine("")
        
        putString("      IN[3]: ")
        putString((inValue & (1 << config.rstPin)) != 0 ? "1" : "0")
        putLine("")
    }
    
    flushUART()
}

// Get GPIO pin state
func getGPIOState(pin: UInt32) -> Bool {
    let inValue = UInt32(gpio.`in`.read().raw.storage)
    return (inValue & (1 << pin)) != 0
}

// Enhanced GPIO diagnostics for power issues
func diagnoseGPIOPowerAndWiring() {
    putLine("=== GPIO Power and Wiring Diagnostics ===")
    
    let config = defaultSPIConfig
    let allPins = [config.sckPin, config.mosiPin, config.csPin, config.dcPin, config.rstPin]
    
    putLine("Testing all display pins for basic functionality...")
    
    for pin in allPins {
        putString("GPIO")
        printSimpleNumber(UInt16(pin))
        putString(": ")
        
        // Test output capability
        setGPIO(pin: pin, high: false)
        delayMicroseconds(1000)
        let lowRead = getGPIOState(pin: pin)
        
        setGPIO(pin: pin, high: true)
        delayMicroseconds(1000)
        let highRead = getGPIOState(pin: pin)
        
        if !lowRead && highRead {
            putString("OK")
        } else {
            putString("FAIL (L:")
            putString(lowRead ? "1" : "0")
            putString(", H:")
            putString(highRead ? "1" : "0")
            putString(")")
        }
        putLine("")
    }
    
    putLine("=== Power/Wiring Diagnostics Complete ===")
    flushUART()
}

// MISSING FUNCTION IMPLEMENTATIONS

// Enable power domains for GPIO and SPI peripherals
func enablePowerDomains() {
    putLine("  Enabling ESP32-C6 power domains...")
    flushUART()  // Ensure this message is sent before any clock changes
    
    // CRITICAL: Do NOT modify clock domains that might affect UART!
    // The GPIO and SPI clocks are likely already enabled by bootloader
    // Modifying PCR registers incorrectly can corrupt UART communication
    
    // Instead, just verify that the clocks we need are already enabled
    // ESP32-C6 Power Control Register (PCR) - READ ONLY for verification
    let pcrBase: UInt = 0x60096000
    let gpioClkEnReg = UnsafeMutablePointer<UInt32>(bitPattern: pcrBase + 0x00)!  // GPIO clock enable
    let spiClkEnReg = UnsafeMutablePointer<UInt32>(bitPattern: pcrBase + 0x04)!   // SPI clock enable
    
    // READ ONLY - just check current state
    putString("    GPIO clock status: 0x")
    let gpioClkState = gpioClkEnReg.pointee
    printHex32(gpioClkState)
    putLine("")
    flushUART()
    
    putString("    SPI2 clock status: 0x")
    let spiClkState = spiClkEnReg.pointee
    printHex32(spiClkState)
    putLine("")
    flushUART()
    
    // NOTE: We're NOT modifying these registers to avoid UART corruption
    // The bootloader has already set up the necessary clock domains
    
    putLine("  Power domain check complete (no modifications)")
    flushUART()
}

// Configure GPIO matrix for SPI signal routing
func configureGPIOMatrix(config: SPIConfig) {
    putLine("  Configuring GPIO matrix for SPI routing...")
    
    // For bare metal SPI, we'll use GPIO simple output signals instead of SPI peripheral signals
    // This matches what we're doing with bit-banged SPI
    
    // Connect each GPIO pin to simple GPIO output signal
    putString("    SCK (GPIO")
    printSimpleNumber(UInt16(config.sckPin))
    putString("): ")
    let _ = esp_rom_gpio_connect_out_signal(config.sckPin, 128, false, false)  // GPIO_OUT_IDX = 128
    putString("connected")
    putLine("")
    
    putString("    MOSI (GPIO")
    printSimpleNumber(UInt16(config.mosiPin))
    putString("): ")
    let _ = esp_rom_gpio_connect_out_signal(config.mosiPin, 128, false, false)  // GPIO_OUT_IDX = 128
    putString("connected")
    putLine("")
    
    putString("    CS (GPIO")
    printSimpleNumber(UInt16(config.csPin))
    putString("): ")
    let _ = esp_rom_gpio_connect_out_signal(config.csPin, 128, false, false)  // GPIO_OUT_IDX = 128
    putString("connected")
    putLine("")
    
    putString("    DC (GPIO")
    printSimpleNumber(UInt16(config.dcPin))
    putString("): ")
    let _ = esp_rom_gpio_connect_out_signal(config.dcPin, 128, false, false)  // GPIO_OUT_IDX = 128
    putString("connected")
    putLine("")
    
    putString("    RST (GPIO")
    printSimpleNumber(UInt16(config.rstPin))
    putString("): ")
    let _ = esp_rom_gpio_connect_out_signal(config.rstPin, 128, false, false)  // GPIO_OUT_IDX = 128
    putString("connected")
    putLine("")
    
    // Small delay for signal routing to stabilize
    delayMicroseconds(1000)
    
    putLine("  GPIO matrix configuration complete")
    flushUART()
}
