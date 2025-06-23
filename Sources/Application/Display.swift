
import MMIO
import Registers

// High-level display application functions
func runDisplayApplication() {
    putLine("=== Starting Display Application ===")

    // Initialize SPI first
    initializeSPI()

    // Initialize the ILI9341 display
    initializeDisplay()

    // Test basic functionality
    testDisplayFunctionality()

    putLine("=== Display Application Complete ===")
    flushUART()
}

func testDisplayFunctionality() {
    putLine("Testing display functionality...")

    // Test 1: Fill screen with red
    putLine("Test 1: Red screen")
    fillScreen(color: ILI9341.colorRed)
    delayMilliseconds(1000)

    // Test 2: Fill screen with blue
    putLine("Test 2: Blue screen")
    fillScreen(color: ILI9341.colorBlue)
    delayMilliseconds(1000)

    // Test 3: Draw test pattern
    putLine("Test 3: Color pattern")
    drawTestPattern()
    delayMilliseconds(2000)

    // Test 4: Clear screen
    putLine("Test 4: Clear screen")
    clearDisplay()

    putLine("Display tests complete!")
}

func fillScreen(color: UInt16) {
    // Set the full screen area
    setDisplayArea(x: 0, y: 0, width: ILI9341.width, height: ILI9341.height)

    // Start memory write
    sendDisplayCommand(0x2C)  // Memory write command

    // Fill screen efficiently with progress reporting
    let totalPixels = UInt32(ILI9341.width) * UInt32(ILI9341.height)
    var pixelCount: UInt32 = 0

    for row in 0..<ILI9341.height {
        for _ in 0..<ILI9341.width {
            sendDisplayData16(color)
            pixelCount += 1
        }

        // Report progress every 32 rows to avoid flooding
        if row % 32 == 0 {
            putString("Progress: ")
            printSimpleNumber(row)
            putString("/")
            printSimpleNumber(ILI9341.height)
            putLine("")
            flushUART()
        }
    }

    putLine("Screen fill complete")
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

    // Fill rectangle with color
    for _ in 0..<height {
        for _ in 0..<width {
            sendDisplayData16(color)
        }
    }
}

// Test pattern functions
func drawTestPattern() {
    putLine("Drawing color test pattern...")

    // Calculate rectangle size (divide screen into 6 rectangles)
    let rectWidth: UInt16 = ILI9341.width / 3
    let rectHeight: UInt16 = ILI9341.height / 2

    // Top row
    fillRect(x: 0, y: 0, width: rectWidth, height: rectHeight, color: ILI9341.colorRed)
    fillRect(x: rectWidth, y: 0, width: rectWidth, height: rectHeight, color: ILI9341.colorGreen)
    fillRect(x: rectWidth * 2, y: 0, width: rectWidth, height: rectHeight, color: ILI9341.colorBlue)

    // Bottom row
    fillRect(x: 0, y: rectHeight, width: rectWidth, height: rectHeight, color: ILI9341.colorYellow)
    fillRect(x: rectWidth, y: rectHeight, width: rectWidth, height: rectHeight, color: ILI9341.colorCyan)
    fillRect(x: rectWidth * 2, y: rectHeight, width: rectWidth, height: rectHeight, color: ILI9341.colorMagenta)

    putLine("Test pattern complete!")
}

func clearDisplay() {
    putLine("Clearing display...")
    fillScreen(color: ILI9341.colorBlack)
    putLine("Display cleared!")
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