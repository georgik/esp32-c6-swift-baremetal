import MMIO
import Registers

// High-level display application functions
func runDisplayApplication() {
    putLine("=== Starting Display Application ===")
    flushUART()

    // CRITICAL: Test power supply and basic wiring FIRST
    putLine("STEP 1: Power and Wiring Diagnostics...")
    diagnoseGPIOPowerAndWiring()

    // Initialize SPI with enhanced diagnostics
    putLine("STEP 2: SPI Initialization...")
    initializeSPI()
    
    // CRITICAL: Verify GPIO states before display init
    putLine("STEP 3: Pre-display GPIO verification...")
    verifyPreDisplayGPIOStates()

    // Initialize the ILI9341 display
    putLine("STEP 4: Display Initialization...")
    initializeDisplay()

    // Test basic functionality
    putLine("STEP 5: Display Functionality Tests...")
    //testDisplayFunctionality()
    ESP32C6ROM.disableRTCWatchdog()
    
    putLine("=== Display Application Complete ===")
    flushUART()
}

func testDisplayFunctionality() {
    putLine("Testing display functionality...")
    flushUART()

    // Test 0: Clear screen first to remove random video memory noise
    putLine("Test 0: Clearing screen (removing random video memory)")
    clearDisplay()
//     delayMilliseconds(1000)
    flushUART()
    ESP32C6ROM.disableRTCWatchdog()

    // Test 1: Simple single pixel test first
//     putLine("Test 1: Single pixel test")
//     simpleSinglePixelTest()
//     delayMilliseconds(2000)
//     flushUART()
//     ESP32C6ROM.disableRTCWatchdog()

    // Test 2: Small rectangle test
//     putLine("Test 2: Small rectangle test")
//     simpleRectangleTest()
//     delayMilliseconds(2000)
//     flushUART()
//     ESP32C6ROM.disableRTCWatchdog()

    // Test 3: Fill screen with red (slower)
    putLine("Test 3: Red screen")
    fillScreenWithRects(color: ILI9341.colorRed)
//     delayMilliseconds(3000)
    flushUART()

    // Test 4: Fill screen with blue (slower)
    putLine("Test 4: Blue screen")
    fillScreenWithRects(color: ILI9341.colorBlue)
//     delayMilliseconds(3000)
    flushUART()

    // Test 5: Draw test pattern
    putLine("Test 5: Color pattern")
    drawTestPattern()
//     delayMilliseconds(5000)
    flushUART()

    // Test 6: Clear screen
    putLine("Test 6: Clear screen")
    clearDisplay()
//     delayMilliseconds(2000)
    flushUART()

    putLine("Display tests complete!")
    flushUART()
}

func fillScreen(color: UInt16) {
    // Set the full screen area
    setDisplayArea(x: 0, y: 0, width: ILI9341.width, height: ILI9341.height)

    // Start memory write
    sendDisplayCommand(0x2C)  // Memory write command

    // Fill screen efficiently with progress reporting
    _ = UInt32(ILI9341.width) * UInt32(ILI9341.height)  // Calculate total pixels but don't store
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
    fastClearDisplay()
    putLine("Display cleared!")
}

// Display clearing with watchdog feeding - ESP-IDF style
func fastClearDisplay() {
    putLine("Starting display clear with watchdog feeding...")
    
    // First, try a moderate area - 80x60 pixels (4800 pixels)
    // This is bigger than the tiny test but still manageable
    let clearWidth: UInt16 = 10
    let clearHeight: UInt16 = 10
    let _ = UInt32(clearWidth) * UInt32(clearHeight)  // Total pixels calculation for future use
    
    setDisplayArea(x: 0, y: 0, width: clearWidth, height: clearHeight)
    
    // Start memory write
    sendDisplayCommand(0x2C)  // Memory write command
    
    // Set DC to data mode once at start
    setDisplayDC(high: true)
    
    putString("Clearing ")
    printSimpleNumber(clearWidth)
    putString("x")
    printSimpleNumber(clearHeight)
    putString(" area (")
    // printSimpleNumber can't handle UInt32, so we'll estimate
    putString("~4800")
    putLine(" pixels)...")
    ESP32C6ROM.disableRTCWatchdog()
    ESP32C6ROM.printRTCWatchdogState()
    
    var pixelCount: UInt32 = 0
    let feedInterval: UInt32 = 100  // Feed watchdog every 100 pixels
    
    // Send all pixels with regular watchdog feeding
    for _ in 0..<clearHeight {
        for _ in 0..<clearWidth {
            // Send pixel data (black)
            sendSPIByte(0x00)  // Black high byte
            sendSPIByte(0x00)  // Black low byte
            pixelCount += 1
            
            // Feed watchdog regularly to prevent timeout
            if pixelCount % feedInterval == 0 {
                // Progress update every 1000 pixels
                if pixelCount % 1000 == 0 {
                    // Simple progress indicator
                    if pixelCount >= 1000 { putString("1k+") }
                    else if pixelCount >= 2000 { putString("2k+") }
                    else if pixelCount >= 3000 { putString("3k+") }
                    else if pixelCount >= 4000 { putString("4k+") }
                    putLine("")
                }
            }
        }
    }
    
    putString("Clearing complete! Processed ")
    putString("~4800")
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

// ADDITIONAL TEST FUNCTIONS FOR DEBUGGING

// Very simple single pixel test
func simpleSinglePixelTest() {
    putLine("   Setting single red pixel at (10,10)...")
    
    // Diagnostic before
    diagnoseSPISignals("before pixel")
    
    // Set a single red pixel at position (10, 10)
    drawPixel(x: 10, y: 10, color: ILI9341.colorRed)
    
//     delayMilliseconds(100)
    
    // Diagnostic after
    diagnoseSPISignals("after pixel")
    
    putLine("   Single pixel test complete")
}

// Simple rectangle test
func simpleRectangleTest() {
    putLine("   Drawing small green rectangle...")
    
    // Diagnostic before
    diagnoseSPISignals("before rectangle")
    
    // Draw a small 20x20 green rectangle at position (50, 50)
    fillRect(x: 50, y: 50, width: 20, height: 20, color: ILI9341.colorGreen)
    
//     delayMilliseconds(100)
    
    // Diagnostic after
    diagnoseSPISignals("after rectangle")
    
    putLine("   Rectangle test complete")
}

// -------------------------------------------------------------
// Whole-screen fill using many small fillRect tiles
// -------------------------------------------------------------
func fillScreenWithRects(color: UInt16,
                         tile: UInt16 = 40) {   // 40×40 pixels per chunk
    putLine("   Filling screen with rectangular tiles...")
    flushUART()

    var y: UInt16 = 0
    while y < ILI9341.height {
     putLine("   +Filling screen with rectangular tiles...")
        flushUART()
        var x: UInt16 = 0
        let h = min(tile, ILI9341.height - y)

        while x < ILI9341.width {
                              putChar(46)      // '.'
                                flushUART()

            let w = min(tile, ILI9341.width - x)
            fillRect(x: x, y: y, width: 14, height: 14, color: color)
            x &+= w
        }
        y &+= h
        // Optional: progress heartbeat every full row of tiles
        if (y % 80) == 0 {   // every two tile rows
            putChar(46)      // '.'
            flushUART()
        }
    }
    putLine("\n   Rect-based fill complete")
    flushUART()
}

// Critical GPIO state verification before display operations
func verifyPreDisplayGPIOStates() {
    putLine("=== Pre-Display GPIO State Verification ===")
    
    let config = defaultSPIConfig
    
    // Check that all pins are properly configured as outputs
    let enableValue = UInt32(gpio.enable.read().raw.storage)
    let outValue = UInt32(gpio.out.read().raw.storage)
    let inValue = UInt32(gpio.`in`.read().raw.storage)
    
    putString("Current GPIO states: ENABLE=0x")
    printHex32(enableValue)
    putString(", OUT=0x")
    printHex32(outValue)
    putString(", IN=0x")
    printHex32(inValue)
    putLine("")
    
    // Check each critical pin using indices to avoid string comparisons
    let criticalPins = [config.rstPin, config.dcPin, config.csPin, config.sckPin, config.mosiPin]
    
    var allGood = true
    
    for index in 0..<criticalPins.count {
        let pin = criticalPins[index]
        let enabled = (enableValue & (1 << pin)) != 0
        let outState = (outValue & (1 << pin)) != 0
        let inState = (inValue & (1 << pin)) != 0
        
        // Print pin name using index to avoid String comparisons
        switch index {
        case 0: // RST
            putChar(82) // 'R'
            putChar(83) // 'S'
            putChar(84) // 'T'
        case 1: // DC
            putChar(68) // 'D'
            putChar(67) // 'C'
        case 2: // CS
            putChar(67) // 'C'
            putChar(83) // 'S'
        case 3: // SCK
            putChar(83) // 'S'
            putChar(67) // 'C'
            putChar(75) // 'K'
        case 4: // MOSI
            putChar(77) // 'M'
            putChar(79) // 'O'
            putChar(83) // 'S'
            putChar(73) // 'I'
        default:
            putChar(63) // '?'
        }
        putString("(GPIO")
        printSimpleNumber(UInt16(pin))
        putString("): ")
        
        if enabled {
            putString("ENABLED, OUT=")
            putString(outState ? "H" : "L")
            putString(", IN=")
            putString(inState ? "H" : "L")
            
            // Special checks using index
            if index == 0 && !outState { // RST
                putString(" [WARNING: RST should be HIGH]")
                allGood = false
            }
            if index == 2 && !outState { // CS
                putString(" [WARNING: CS should be HIGH]")
                allGood = false
            }
        } else {
            putString("NOT_ENABLED [ERROR]")
            allGood = false
        }
        putLine("")
    }
    
    if !allGood {
        putLine("ERROR: GPIO configuration problems detected!")
        putLine("Display is unlikely to work with these issues.")
    } else {
        putLine("GPIO verification: ALL GOOD")
    }
    
    // Extra RST pin verification with manual toggle
    putLine("Extra RST pin test...")
    let _ = getGPIOState(pin: config.rstPin)
    
    setDisplayRST(high: false)
    delayMilliseconds(10)
    let rstLow = getGPIOState(pin: config.rstPin)
    
    setDisplayRST(high: true)
    delayMilliseconds(10)
    let rstHigh = getGPIOState(pin: config.rstPin)
    
    putString("RST toggle test: LOW=")
    putString(rstLow ? "FAIL" : "OK")
    putString(", HIGH=")
    putString(rstHigh ? "OK" : "FAIL")
    
    if rstLow || !rstHigh {
        putString(" [CRITICAL ERROR]")
        allGood = false
    }
    putLine("")
    
    if !allGood {
        putLine("CRITICAL: Display hardware issues detected!")
        putLine("Check power supply, wiring, and GPIO configuration.")
    }
    
    putLine("=== GPIO Verification Complete ===")
    flushUART()
}
