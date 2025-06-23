import MMIO
import Registers

// ILI9341 Display constants
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

// Display application functions
func runDisplayApplication() {
    putLine("=== Starting Display Application ===")

    // First run the SPI test
    testSPIDisplay()

    putLine("Running blue fill test...")
    fillDisplayBlue()

    putLine("=== Display Application Complete ===")
    flushUART()
}

func fillDisplayBlue() {
    putLine("Filling display with blue color...")

    // Set the full screen area
    setDisplayArea(x: 0, y: 0, width: ILI9341.width, height: ILI9341.height)

    // Start memory write
    sendDisplayCommand(0x2C)  // Memory write command

    // Simplified approach - avoid large number calculations
    putLine("Drawing blue pixels...")

    // Fill screen line by line to avoid large loop
    for row in 0..<ILI9341.height {
        for col in 0..<ILI9341.width {
            sendDisplayData16(ILI9341.colorBlue)
        }

        // Print progress every 50 rows
        if row % 50 == 0 {
            putString("Row: ")
            printSimpleNumber(UInt16(row))
            putString(" / ")
            printSimpleNumber(ILI9341.height)
            putLine("")
            flushUART()
        }
    }

    putLine("Blue fill complete!")
    flushUART()
}

func setDisplayArea(x: UInt16, y: UInt16, width: UInt16, height: UInt16) {
    let x2 = x + width - 1
    let y2 = y + height - 1

    // Set column address
    sendDisplayCommand(0x2A)  // Column address set
    sendDisplayData(UInt8(x >> 8))      // Start column high
    sendDisplayData(UInt8(x & 0xFF))    // Start column low
    sendDisplayData(UInt8(x2 >> 8))     // End column high
    sendDisplayData(UInt8(x2 & 0xFF))   // End column low

    // Set page address
    sendDisplayCommand(0x2B)  // Page address set
    sendDisplayData(UInt8(y >> 8))      // Start page high
    sendDisplayData(UInt8(y & 0xFF))    // Start page low
    sendDisplayData(UInt8(y2 >> 8))     // End page high
    sendDisplayData(UInt8(y2 & 0xFF))   // End page low
}

func drawPixel(x: UInt16, y: UInt16, color: UInt16) {
    // Set single pixel area
    setDisplayArea(x: x, y: y, width: 1, height: 1)

    // Write pixel color
    sendDisplayCommand(0x2C)  // Memory write
    sendDisplayData16(color)
}

func fillRect(x: UInt16, y: UInt16, width: UInt16, height: UInt16, color: UInt16) {
    // Set rectangle area
    setDisplayArea(x: x, y: y, width: width, height: height)

    // Start memory write
    sendDisplayCommand(0x2C)  // Memory write

    // Fill rectangle with color using simple loops
    for _ in 0..<height {
        for _ in 0..<width {
            sendDisplayData16(color)
        }
    }
}

// Ultra-simple number printing for small numbers (embedded-safe)
func printSimpleNumber(_ number: UInt16) {
    if number == 0 {
        putChar(48)  // '0'
        return
    }

    // Handle up to 5 digits (max 65535)
    var digits: [UInt8] = [0, 0, 0, 0, 0]
    var digitCount = 0
    var n = number

    // Extract digits
    while n > 0 && digitCount < 5 {
        digits[digitCount] = UInt8(48 + (n % 10))
        digitCount += 1
        n /= 10
    }

    // Print in reverse order
    for i in (0..<digitCount).reversed() {
        putChar(digits[i])
    }
}

// Test pattern functions for future expansion
func drawTestPattern() {
    putLine("Drawing test pattern...")

    // Draw colored rectangles
    fillRect(x: 0, y: 0, width: 80, height: 80, color: ILI9341.colorRed)
    fillRect(x: 80, y: 0, width: 80, height: 80, color: ILI9341.colorGreen)
    fillRect(x: 160, y: 0, width: 80, height: 80, color: ILI9341.colorBlue)

    fillRect(x: 0, y: 80, width: 80, height: 80, color: ILI9341.colorYellow)
    fillRect(x: 80, y: 80, width: 80, height: 80, color: ILI9341.colorCyan)
    fillRect(x: 160, y: 80, width: 80, height: 80, color: ILI9341.colorMagenta)

    putLine("Test pattern complete!")
}

func clearDisplay() {
    putLine("Clearing display...")
    fillRect(x: 0, y: 0, width: ILI9341.width, height: ILI9341.height, color: ILI9341.colorBlack)
    putLine("Display cleared!")
}