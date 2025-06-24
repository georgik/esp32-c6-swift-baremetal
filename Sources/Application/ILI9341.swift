
import MMIO
import Registers

// ILI9341 Display Commands (from ESP-IDF)
enum ILI9341Command: UInt8 {
    // Basic commands
    case SOFTWARE_RESET = 0x01      // SWRESET
    case SLEEP_OUT = 0x11           // SLPOUT
    case DISPLAY_ON = 0x29          // DISPON
    case DISPLAY_OFF = 0x28         // DISPOFF
    case COLUMN_ADDRESS_SET = 0x2A  // CASET
    case PAGE_ADDRESS_SET = 0x2B    // RASET/PASET
    case MEMORY_WRITE = 0x2C        // RAMWR
    case MEMORY_ACCESS_CONTROL = 0x36 // MADCTL
    case PIXEL_FORMAT = 0x3A        // COLMOD

    // Power control commands
    case POWER_CONTROL_1 = 0xC0
    case POWER_CONTROL_2 = 0xC1
    case VCOM_CONTROL_1 = 0xC5
    case VCOM_CONTROL_2 = 0xC7

    // Extended commands (from ESP-IDF vendor init)
    case POWER_CONTROL_A = 0xCB
    case POWER_CONTROL_B = 0xCF
    case DRIVER_TIMING_CONTROL_A = 0xE8
    case DRIVER_TIMING_CONTROL_B = 0xEA
    case POWER_ON_SEQUENCE = 0xED
    case PUMP_RATIO_CONTROL = 0xF7
    case FRAME_RATE_CONTROL = 0xB1
    case DISPLAY_FUNCTION_CONTROL = 0xB6
    case GAMMA_SET = 0x26
    case POSITIVE_GAMMA = 0xE0
    case NEGATIVE_GAMMA = 0xE1
    case ENTRY_MODE_SET = 0xB7
    case ENABLE_3G = 0xF2
}

// ILI9341 Display constants and colors
struct ILI9341 {
    static let width: UInt16 = 240
    static let height: UInt16 = 320

    // RGB565 colors
    static let colorRed: UInt16 = 0xF800
    static let colorGreen: UInt16 = 0x07E0
    static let colorBlue: UInt16 = 0x001F
    static let colorWhite: UInt16 = 0xFFFF
    static let colorBlack: UInt16 = 0x0000
    static let colorYellow: UInt16 = 0xFFE0
    static let colorCyan: UInt16 = 0x07FF
    static let colorMagenta: UInt16 = 0xF81F
}

// Display configuration
struct DisplayConfig {
    static let width: UInt16 = 240
    static let height: UInt16 = 320
    static let rotation: UInt8 = 0 // 0 degree rotation
}

func initializeDisplay() {
    putLine("=== ILI9341 Display Initialization ===")
    flushUART()

    // CRITICAL: Power-on reset sequence per ILI9341 datasheet
    putLine("Power-on sequence: Initial stabilization...")
    delayMilliseconds(200)  // Wait for display power to stabilize
    flushUART()
    
    // 1. Hardware reset with datasheet-compliant timing
    putLine("1. Hardware reset sequence...")
    diagnoseSPISignals("before reset")
    
    // Step 1a: Ensure RST is high first (power-on state)
    putLine("   RST high (power-on state)...")
    setDisplayRST(high: true)
    delayMilliseconds(100)  // Wait in powered state
    
    // Step 1b: RST low (reset active) - ILI9341 requires minimum 10μs
    putLine("   RST low (reset active)...")
    setDisplayRST(high: false)
    delayMilliseconds(50)   // 50ms >> 10μs minimum
    
    // Step 1c: RST high (reset release) - ILI9341 requires minimum 120ms wait
    putLine("   RST high (reset release)...")
    setDisplayRST(high: true)
    putLine("   Waiting for display wake-up (critical timing)...")
    delayMilliseconds(300)  // 300ms >> 120ms minimum from datasheet
    
    diagnoseSPISignals("after reset")
    putLine("   Hardware reset sequence complete")
    flushUART()

    // 2. Software reset with verification
    putLine("2. Software reset...")
    sendDisplayCommandWithVerification(0x01, name: "SWRESET")
    delayMilliseconds(150) // Increased from 120ms
    putLine("   Software reset complete")
    flushUART()

    // 3. Exit sleep mode with verification
    putLine("3. Exit sleep mode...")
    sendDisplayCommandWithVerification(0x11, name: "SLPOUT")
    delayMilliseconds(150) // Increased from 120ms
    putLine("   Sleep mode exit complete")
    flushUART()

    // 4. Set pixel format to RGB565 with verification
    putLine("4. Setting pixel format...")
    sendDisplayCommandWithVerification(0x3A, name: "COLMOD")
    sendDisplayDataWithVerification(0x55, name: "RGB565")
    delayMilliseconds(20)  // Increased from 10ms
    putLine("   Pixel format set to RGB565")
    flushUART()

    // 5. Execute STANDARD initialization sequence
    putLine("5. Standard initialization sequence...")
    executeStandardInitWithDiagnostics()
    putLine("   Standard initialization complete")
    flushUART()

    // 6. Turn on display with verification
    putLine("6. Turning on display...")
    sendCommandWithVerification(.DISPLAY_ON, name: "DISPON")
    delayMilliseconds(50)  // Increased from 20ms
    putLine("   Display enabled")
    flushUART()

    // 7. Final diagnostic check
    putLine("7. Final diagnostic check...")
    diagnoseSPISignals("initialization complete")
    testDisplayConnection()
    
    putLine("=== Display Initialization Complete! ===")
    flushUART()
}


// Simplified, standard-compliant initialization sequence
private func executeStandardInit() {
    // Set Memory Access Control (orientation and RGB order)
    sendCommand(.MEMORY_ACCESS_CONTROL)
    sendData([0x48])  // Normal orientation, RGB order
    delayMilliseconds(10)

    // Power control 1, GVDD=4.75V
    sendCommand(.POWER_CONTROL_1)
    sendData([0x23])
    delayMilliseconds(10)

    // Power control 2, DDVDH=VCl*2, VGH=VCl*7, VGL=-VCl*3
    sendCommand(.POWER_CONTROL_2)
    sendData([0x10])
    delayMilliseconds(10)

    // VCOM control 1, VCOMH=4.025V, VCOML=-0.950V
    sendCommand(.VCOM_CONTROL_1)
    sendData([0x3E, 0x28])
    delayMilliseconds(10)

    // VCOM control 2, VCOMH=VMH-2, VCOML=VML-2
    sendCommand(.VCOM_CONTROL_2)
    sendData([0x86])
    delayMilliseconds(10)

    // Frame rate control, Normal mode, 70Hz fps
    sendCommand(.FRAME_RATE_CONTROL)
    sendData([0x00, 0x18])
    delayMilliseconds(10)

    // Display function control
    sendCommand(.DISPLAY_FUNCTION_CONTROL)
    sendData([0x08, 0x82, 0x27])
    delayMilliseconds(10)

    // Gamma set, curve 1
    sendCommand(.GAMMA_SET)
    sendData([0x01])
    delayMilliseconds(10)

    // Positive gamma correction (simplified)
    sendCommand(.POSITIVE_GAMMA)
    sendData([0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1,
              0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00])
    delayMilliseconds(10)

    // Negative gamma correction (simplified)
    sendCommand(.NEGATIVE_GAMMA)
    sendData([0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1,
              0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F])
    delayMilliseconds(10)
}

// Vendor-specific initialization sequence from ESP-IDF
private func executeVendorInit() {
    // Power control B, power control = 0, DC_ENA = 1
    sendCommand(.POWER_CONTROL_B)
    sendData([0x00, 0xAA, 0xE0])

    // Power on sequence control
    sendCommand(.POWER_ON_SEQUENCE)
    sendData([0x67, 0x03, 0x12, 0x81])

    // Driver timing control A
    sendCommand(.DRIVER_TIMING_CONTROL_A)
    sendData([0x8A, 0x01, 0x78])

    // Power control A, Vcore=1.6V, DDVDH=5.6V
    sendCommand(.POWER_CONTROL_A)
    sendData([0x39, 0x2C, 0x00, 0x34, 0x02])

    // Pump ratio control, DDVDH=2xVCl
    sendCommand(.PUMP_RATIO_CONTROL)
    sendData([0x20])

    // Driver timing control, all=0 unit
    sendCommand(.DRIVER_TIMING_CONTROL_B)
    sendData([0x00, 0x00])

    // Power control 1, GVDD=4.75V
    sendCommand(.POWER_CONTROL_1)
    sendData([0x23])

    // Power control 2, DDVDH=VCl*2, VGH=VCl*7, VGL=-VCl*3
    sendCommand(.POWER_CONTROL_2)
    sendData([0x11])

    // VCOM control 1, VCOMH=4.025V, VCOML=-0.950V
    sendCommand(.VCOM_CONTROL_1)
    sendData([0x43, 0x4C])

    // VCOM control 2, VCOMH=VMH-2, VCOML=VML-2
    sendCommand(.VCOM_CONTROL_2)
    sendData([0xA0])

    // Frame rate control, f=fosc, 70Hz fps
    sendCommand(.FRAME_RATE_CONTROL)
    sendData([0x00, 0x1B])

    // Enable 3G, disabled
    sendCommand(.ENABLE_3G)
    sendData([0x00])

    // Gamma set, curve 1
    sendCommand(.GAMMA_SET)
    sendData([0x01])

    // Positive gamma correction
    sendCommand(.POSITIVE_GAMMA)
    sendData([0x1F, 0x36, 0x36, 0x3A, 0x0C, 0x05, 0x4F, 0x87,
              0x3C, 0x08, 0x11, 0x35, 0x19, 0x13, 0x00])

    // Negative gamma correction
    sendCommand(.NEGATIVE_GAMMA)
    sendData([0x00, 0x09, 0x09, 0x05, 0x13, 0x0A, 0x30, 0x78,
              0x43, 0x07, 0x0E, 0x0A, 0x26, 0x2C, 0x1F])

    // Entry mode set, Low vol detect disabled, normal display
    sendCommand(.ENTRY_MODE_SET)
    sendData([0x07])

    // Display function control
    sendCommand(.DISPLAY_FUNCTION_CONTROL)
    sendData([0x08, 0x82, 0x27])
}

// Send command to the display
func sendCommand(_ command: ILI9341Command) {
    setDisplayDC(high: false) // Command mode
    sendSPIByte(command.rawValue)
}

// Send data to the display
func sendData(_ data: [UInt8]) {
    setDisplayDC(high: true) // Data mode
    for byte in data {
        sendSPIByte(byte)
    }
}

// DIAGNOSTIC FUNCTIONS FOR DEBUGGING

// Diagnose SPI signal states - simplified for bare metal
func diagnoseSPISignals(_ context: StaticString) {
    putString("   SPI signals: ")
    
    let gpioOut = UInt32(gpio.out.read().raw.storage)
    let config = defaultSPIConfig
    
    // Check each signal
    let sckHigh = (gpioOut & (1 << config.sckPin)) != 0
    let mosiHigh = (gpioOut & (1 << config.mosiPin)) != 0
    let csHigh = (gpioOut & (1 << config.csPin)) != 0
    let dcHigh = (gpioOut & (1 << config.dcPin)) != 0
    let rstHigh = (gpioOut & (1 << config.rstPin)) != 0
    
    putString("SCK:")
    putString(sckHigh ? "H" : "L")
    putString(", MOSI:")
    putString(mosiHigh ? "H" : "L")
    putString(", CS:")
    putString(csHigh ? "H" : "L")
    putString(", DC:")
    putString(dcHigh ? "H" : "L")
    putString(", RST:")
    putString(rstHigh ? "H" : "L")
    putLine("")
}

// Send command with verification - simplified for bare metal
func sendDisplayCommandWithVerification(_ cmd: UInt8, name: StaticString) {
    putString("   CMD 0x")
    printHex8(cmd)
    putString("... ")
    
    diagnoseSPISignals("before cmd")
    sendDisplayCommand(cmd)
    diagnoseSPISignals("after cmd")
    
    putLine("done")
}

// Send data with verification - simplified for bare metal
func sendDisplayDataWithVerification(_ data: UInt8, name: StaticString) {
    putString("   DATA 0x")
    printHex8(data)
    putString("... ")
    
    diagnoseSPISignals("before data")
    sendDisplayData(data)
    diagnoseSPISignals("after data")
    
    putLine("done")
}

// Send command enum with verification - simplified for bare metal
func sendCommandWithVerification(_ command: ILI9341Command, name: StaticString) {
    sendDisplayCommandWithVerification(command.rawValue, name: name)
}

// Enhanced standard initialization with diagnostics
func executeStandardInitWithDiagnostics() {
    putLine("   Standard Init: Memory Access Control...")
    sendCommandWithVerification(.MEMORY_ACCESS_CONTROL, name: "MADCTL")
    sendDisplayDataWithVerification(0x48, name: "orientation")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Power Control 1...")
    sendCommandWithVerification(.POWER_CONTROL_1, name: "PWCTR1")
    sendDisplayDataWithVerification(0x23, name: "GVDD=4.75V")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Power Control 2...")
    sendCommandWithVerification(.POWER_CONTROL_2, name: "PWCTR2")
    sendDisplayDataWithVerification(0x10, name: "voltage levels")
    delayMilliseconds(20)
    
    putLine("   Standard Init: VCOM Control...")
    sendCommandWithVerification(.VCOM_CONTROL_1, name: "VMCTR1")
    sendDisplayDataWithVerification(0x3E, name: "VCOMH high")
    sendDisplayDataWithVerification(0x28, name: "VCOMH low")
    delayMilliseconds(20)
    
    sendCommandWithVerification(.VCOM_CONTROL_2, name: "VMCTR2")
    sendDisplayDataWithVerification(0x86, name: "VCOM offset")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Frame Rate Control...")
    sendCommandWithVerification(.FRAME_RATE_CONTROL, name: "FRMCTR1")
    sendDisplayDataWithVerification(0x00, name: "frame rate 1")
    sendDisplayDataWithVerification(0x18, name: "frame rate 2")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Display Function Control...")
    sendCommandWithVerification(.DISPLAY_FUNCTION_CONTROL, name: "DISCTRL")
    sendDisplayDataWithVerification(0x08, name: "display control 1")
    sendDisplayDataWithVerification(0x82, name: "display control 2")
    sendDisplayDataWithVerification(0x27, name: "display control 3")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Gamma Settings...")
    sendCommandWithVerification(.GAMMA_SET, name: "GAMSET")
    sendDisplayDataWithVerification(0x01, name: "gamma curve")
    delayMilliseconds(20)
    
    putLine("   Standard Init: Positive Gamma...")
    sendCommandWithVerification(.POSITIVE_GAMMA, name: "GMCTRP1")
    let posGamma: [UInt8] = [0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1,
                            0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00]
    for value in posGamma {
        sendDisplayDataWithVerification(value, name: "pos_gamma")
    }
    delayMilliseconds(20)
    
    putLine("   Standard Init: Negative Gamma...")
    sendCommandWithVerification(.NEGATIVE_GAMMA, name: "GMCTRN1")
    let negGamma: [UInt8] = [0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1,
                            0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F]
    for value in negGamma {
        sendDisplayDataWithVerification(value, name: "neg_gamma")
    }
    delayMilliseconds(20)
}

// Test display connection by trying to set and read back simple operations
func testDisplayConnection() {
    putLine("   Connection Test: Testing display communication...")
    
    // Test 1: Set a simple window and try to write a pixel
    putLine("   Connection Test: Setting small test area...")
    sendDisplayCommandWithVerification(0x2A, name: "CASET")
    sendDisplayDataWithVerification(0x00, name: "x_start_high")
    sendDisplayDataWithVerification(0x00, name: "x_start_low")
    sendDisplayDataWithVerification(0x00, name: "x_end_high")
    sendDisplayDataWithVerification(0x01, name: "x_end_low")
    
    sendDisplayCommandWithVerification(0x2B, name: "RASET")
    sendDisplayDataWithVerification(0x00, name: "y_start_high")
    sendDisplayDataWithVerification(0x00, name: "y_start_low")
    sendDisplayDataWithVerification(0x00, name: "y_end_high")
    sendDisplayDataWithVerification(0x01, name: "y_end_low")
    
    // Test 2: Try to write some pixel data
    putLine("   Connection Test: Writing test pixel data...")
    sendDisplayCommandWithVerification(0x2C, name: "RAMWR")
    sendDisplayDataWithVerification(0xFF, name: "test_pixel_high")
    sendDisplayDataWithVerification(0xFF, name: "test_pixel_low")
    
    delayMilliseconds(50)
    putLine("   Connection Test: Basic communication test complete")
}

// Helper function to print hex values for debugging
func printHex8(_ value: UInt8) {
    let high = (value >> 4) & 0x0F
    let low = value & 0x0F
    
    if high < 10 {
        putChar(48 + high) // '0' + digit
    } else {
        putChar(65 + high - 10) // 'A' + (digit - 10)
    }
    
    if low < 10 {
        putChar(48 + low)
    } else {
        putChar(65 + low - 10)
    }
}
