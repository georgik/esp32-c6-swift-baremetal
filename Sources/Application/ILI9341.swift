
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

// Initialize the ILI9341 display following ESP-IDF sequence
func initializeDisplay() {
    putLine("=== ILI9341 Display Initialization ===")
    flushUART()

    // Step 1: Hardware reset sequence
    putLine("1. Hardware reset...")
    setDisplayRST(high: false)
    delayMilliseconds(10)
    setDisplayRST(high: true)
    delayMilliseconds(10)

    // Step 2: Exit sleep mode first (critical!)
    putLine("2. Exit sleep mode...")
    sendCommand(.SLEEP_OUT)
    delayMilliseconds(100)  // Wait at least 100ms after sleep out

    // Step 3: Set MADCTL (Memory Access Control) - before vendor init
    putLine("3. Setting memory access control...")
    sendCommand(.MEMORY_ACCESS_CONTROL)
    sendData([0x00])  // Normal orientation, RGB order

    // Step 4: Set pixel format to RGB565
    putLine("4. Setting pixel format...")
    sendCommand(.PIXEL_FORMAT)
    sendData([0x55])  // 16-bit RGB565

    // Step 5: Execute vendor-specific initialization sequence (from ESP-IDF)
    putLine("5. Vendor initialization sequence...")
    executeVendorInit()

    // Step 6: Turn on display
    putLine("6. Turning on display...")
    sendCommand(.DISPLAY_ON)
    delayMilliseconds(20)

    putLine("=== Display Initialization Complete! ===")
    flushUART()
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