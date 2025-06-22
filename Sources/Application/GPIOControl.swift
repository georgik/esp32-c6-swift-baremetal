
import MMIO
import Registers

// ESP32-C6 GPIO Configuration
let LED_GPIO_PIN: UInt32 = 8
let SIG_GPIO_OUT_IDX: UInt32 = 128  // GPIO simple output signal (0x80)

// IO_MUX base address and GPIO8 offset
private let IO_MUX_BASE: UInt = 0x60009000
private let IO_MUX_GPIO8_REG_OFFSET: UInt = 0x24

func initializeLED() {
    flushUART()

    putLine("Initial states:")
    putString("ENABLE: 0x")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: 0x")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")
    flushUART()

    // Step 1: Configure IO_MUX register directly
    putString("Step 1: Configuring IO_MUX... ")
    let ioMuxReg = UnsafeMutablePointer<UInt32>(bitPattern: IO_MUX_BASE + IO_MUX_GPIO8_REG_OFFSET)!
    
    var ioMuxValue = ioMuxReg.pointee
    putString("(initial: 0x")
    printHex32(ioMuxValue)
    putString(") ")
    
    // Configure IO_MUX for GPIO function:
    // - Clear function select bits (0-3) and set to GPIO (1)
    // - Clear output enable bit (bit 8 is active low)
    // - Set drive strength
    ioMuxValue &= ~0xF           // Clear function select
    ioMuxValue |= 0x1            // Set GPIO function
    ioMuxValue &= ~(1 << 8)      // Enable output (OE=0, active low)
    ioMuxValue |= (2 << 10)      // Set drive strength to 2
    ioMuxReg.pointee = ioMuxValue
    
    putString("configured: 0x")
    printHex32(ioMuxValue)
    putLine("")

    // Step 2: ROM pad select
    putString("Step 2: ROM pad select... ")
    let padResult = esp_rom_gpio_pad_select_gpio(LED_GPIO_PIN)
    putString("result=")
    putChar(UInt8(48 + UInt8(abs(padResult) % 10)))
    putLine("")

    // Step 3: Unhold the pad (ensure it's not stuck in previous state)
    putString("Step 3: ROM pad unhold... ")
    esp_rom_gpio_pad_unhold(LED_GPIO_PIN)
    putLine("done")

    // Step 4: Set drive strength
    putString("Step 4: ROM set drive strength... ")
    esp_rom_gpio_pad_set_drv(LED_GPIO_PIN, 2)  // Medium drive strength
    putLine("done")

    // Step 5: ROM output signal connection
    putString("Step 5: ROM output signal connection... ")
    esp_rom_gpio_connect_out_signal(LED_GPIO_PIN, SIG_GPIO_OUT_IDX, false, false)
    putLine("done")

    // Step 6: Enable GPIO output using MMIO
    putString("Step 6: Setting ENABLE register... ")
    gpio.enable.modify { enable in
        let currentBits = UInt32(enable.raw.storage)
        let newBits = currentBits | (1 << LED_GPIO_PIN)
        enable = .init(.init(newBits))
    }
    putLine("done")

    // Step 7: Ensure output starts LOW
    putString("Step 7: Initialize output to LOW... ")
    ledOff()
    putLine("done")

    putLine("Final states:")
    putString("ENABLE: 0x")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: 0x")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")
    
    putString("IO_MUX final: 0x")
    printHex32(ioMuxReg.pointee)
    putLine("")
    
    putLine("=== GPIO Initialization Complete ===")
    flushUART()
}

func ledOn() {
    // Use the set register for atomic operation
    gpio.out_w1ts.write { out_w1ts in
        out_w1ts = .init(.init(1 << LED_GPIO_PIN))
    }
    
    // Debug: verify the change
    let currentOut = UInt32(gpio.out.read().raw.storage)
    if (currentOut & (1 << LED_GPIO_PIN)) != 0 {
        putString("✓ LED ON confirmed: 0x")
        printHex32(currentOut)
        putLine("")
    } else {
        putString("✗ LED ON failed: 0x")
        printHex32(currentOut)
        putLine("")
    }
}

func ledOff() {
    // Use the clear register for atomic operation
    gpio.out_w1tc.write { out_w1tc in
        out_w1tc = .init(.init(1 << LED_GPIO_PIN))
    }
    
    // Debug: verify the change
    let currentOut = UInt32(gpio.out.read().raw.storage)
    if (currentOut & (1 << LED_GPIO_PIN)) == 0 {
        putString("✓ LED OFF confirmed: 0x")
        printHex32(currentOut)
        putLine("")
    } else {
        putString("✗ LED OFF failed: 0x")
        printHex32(currentOut)
        putLine("")
    }
}

// Enhanced LED control with comprehensive debugging
func setLED(on: Bool) {
    putString("Setting LED ")
    putString(on ? "ON" : "OFF")
    putString("... ")
    
    if on {
        ledOn()
    } else {
        ledOff()
    }
}

// Test function to verify GPIO is working
func testGPIO() {
    putLine("=== GPIO Test Sequence ===")
    
    for i in 0..<5 {
        putString("Test ")
        putChar(UInt8(48 + UInt8(i)))
        putString(": ")
        
        setLED(on: true)
        delayMilliseconds(200)
        
        setLED(on: false)
        delayMilliseconds(200)
    }
    
    putLine("=== GPIO Test Complete ===")
    flushUART()
}

// Direct register access for debugging (bypass MMIO if needed)
func directGPIOTest() {
    putLine("=== Direct Register GPIO Test ===")
    
    let gpioBase: UInt = 0x60004000
    let gpioOutReg = UnsafeMutablePointer<UInt32>(bitPattern: gpioBase + 0x0004)!
    let gpioEnableReg = UnsafeMutablePointer<UInt32>(bitPattern: gpioBase + 0x0020)!
    
    putString("Direct ENABLE: 0x")
    printHex32(gpioEnableReg.pointee)
    putLine("")
    
    putString("Direct OUT: 0x")
    printHex32(gpioOutReg.pointee)
    putLine("")
    
    // Try direct manipulation
    putString("Setting bit directly... ")
    gpioOutReg.pointee |= (1 << LED_GPIO_PIN)
    putString("OUT now: 0x")
    printHex32(gpioOutReg.pointee)
    putLine("")
    
    delayMilliseconds(500)
    
    putString("Clearing bit directly... ")
    gpioOutReg.pointee &= ~(1 << LED_GPIO_PIN)
    putString("OUT now: 0x")
    printHex32(gpioOutReg.pointee)
    putLine("")
    
    putLine("=== Direct Test Complete ===")
    flushUART()
}