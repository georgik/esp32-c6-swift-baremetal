import MMIO
import Registers

// ILI9341 Display Commands
enum ILI9341Command: UInt8 {
    case POWER_CONTROL_A = 0xCB
    case POWER_CONTROL_B = 0xCF
    case DRIVER_TIMING_CONTROL_A = 0xE8
    case DRIVER_TIMING_CONTROL_B = 0xEA
    case POWER_ON_SEQUENCE = 0xED
    case PUMP_RATIO_CONTROL = 0xF7
    case POWER_CONTROL_1 = 0xC0
    case POWER_CONTROL_2 = 0xC1
    case VCOM_CONTROL_1 = 0xC5
    case VCOM_CONTROL_2 = 0xC7
    case MEMORY_ACCESS_CONTROL = 0x36
    case PIXEL_FORMAT = 0x3A
    case FRAME_RATE_CONTROL = 0xB1
    case DISPLAY_FUNCTION_CONTROL = 0xB6
    case SLEEP_OUT = 0x11
    case DISPLAY_ON = 0x29
    case COLUMN_ADDRESS_SET = 0x2A
    case PAGE_ADDRESS_SET = 0x2B
    case MEMORY_WRITE = 0x2C
    case SOFTWARE_RESET = 0x01
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

// Initialize the ILI9341 display
func initializeDisplay() {
    putLine("Initializing ILI9341 Display...")
    flushUART()

    // Hardware reset sequence
    putLine("Performing hardware reset...")
    setDisplayRST(high: false)
    delayMilliseconds(10)
    setDisplayRST(high: true)
    delayMilliseconds(120)

    // Software reset
    putLine("Software reset...")
    sendCommand(.SOFTWARE_RESET)
    delayMilliseconds(150)

    // Extended command set initialization
    putLine("Configuring display parameters...")
    
    sendCommand(.POWER_CONTROL_A)
    sendData([0x39, 0x2C, 0x00, 0x34, 0x02])

    sendCommand(.POWER_CONTROL_B)
    sendData([0x00, 0xC1, 0x30])

    sendCommand(.DRIVER_TIMING_CONTROL_A)
    sendData([0x85, 0x00, 0x78])

    sendCommand(.DRIVER_TIMING_CONTROL_B)
    sendData([0x00, 0x00])

    sendCommand(.POWER_ON_SEQUENCE)
    sendData([0x64, 0x03, 0x12, 0x81])

    sendCommand(.PUMP_RATIO_CONTROL)
    sendData([0x20])

    sendCommand(.POWER_CONTROL_1)
    sendData([0x23])

    sendCommand(.POWER_CONTROL_2)
    sendData([0x10])

    sendCommand(.VCOM_CONTROL_1)
    sendData([0x3E, 0x28])

    sendCommand(.VCOM_CONTROL_2)
    sendData([0x86])

    // Set pixel format to RGB565 (16-bit color)
    sendCommand(.PIXEL_FORMAT)
    sendData([0x55]) // 16-bit color

    // Set memory access control (rotation)
    sendCommand(.MEMORY_ACCESS_CONTROL)
    sendData([0x48]) // Normal orientation

    sendCommand(.FRAME_RATE_CONTROL)
    sendData([0x00, 0x18])

    sendCommand(.DISPLAY_FUNCTION_CONTROL)
    sendData([0x08, 0x82, 0x27])

    // Exit sleep mode
    putLine("Waking up display...")
    sendCommand(.SLEEP_OUT)
    delayMilliseconds(120)

    // Turn on the display
    putLine("Turning on display...")
    sendCommand(.DISPLAY_ON)
    delayMilliseconds(20)

    putLine("Display initialization complete!")
    flushUART()
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