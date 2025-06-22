
import MMIO
import Registers

@_silgen_name("esp_app_desc")
func _getAppDesc() -> UnsafeRawPointer

// ESP32-C6 ROM delay functions
@_silgen_name("esp_rom_delay_us")
func esp_rom_delay_us(_ us: UInt32)

// ESP32-C6 ROM UART functions
@_silgen_name("esp_rom_uart_putc")
func esp_rom_uart_putc(_ char: UInt8)

@_silgen_name("esp_rom_uart_tx_wait_idle")
func esp_rom_uart_tx_wait_idle(_ uart_no: UInt8)

// ESP32-C6 ROM GPIO functions - using only known working ones
@_silgen_name("esp_rom_gpio_pad_select_gpio")
func esp_rom_gpio_pad_select_gpio(_ gpio_num: UInt32) -> Int32

@_silgen_name("esp_rom_gpio_connect_out_signal")
func esp_rom_gpio_connect_out_signal(_ gpio_num: UInt32, _ signal_idx: UInt32, _ out_inv: Bool, _ oen_inv: Bool)

// Constants
let LED_GPIO_PIN: UInt32 = 8
let SIG_GPIO_OUT_IDX: UInt32 = 128  // GPIO simple output signal

// UART helper functions
func putChar(_ char: UInt8) {
    esp_rom_uart_putc(char)
}

func putString(_ string: StaticString) {
    string.withUTF8Buffer { buffer in
        for byte in buffer {
            putChar(byte)
        }
    }
}

func putLine(_ string: StaticString) {
    putString(string)
    putChar(13) // CR
    putChar(10) // LF
}

func flushUART() {
    esp_rom_uart_tx_wait_idle(0) // UART0
}

// ROM-based delay functions
func delayMicroseconds(_ microseconds: UInt32) {
    esp_rom_delay_us(microseconds)
}

func delayMilliseconds(_ milliseconds: UInt32) {
    esp_rom_delay_us(milliseconds * 1000)
}

// Simple hex printing without String operations
private func printHex32(_ value: UInt32) {
    putString("0x")
    // Print each hex digit directly
    for i in (0..<8).reversed() {
        let nibble = (value >> (i * 4)) & 0xF
        if nibble < 10 {
            putChar(48 + UInt8(nibble))  // '0'-'9'
        } else {
            putChar(65 + UInt8(nibble - 10))  // 'A'-'F'
        }
    }
}

// Enhanced GPIO configuration with debugging
private func initializeLED() {
    putLine("=== ESP32-C6 GPIO8 Configuration ===")
    flushUART()

    // Debug: Print initial register states
    putLine("Initial states:")
    putString("ENABLE: ")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: ")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")
    flushUART()

    // Step 1: ROM pad configuration
    putString("Step 1: ROM pad select... ")
    let padResult = esp_rom_gpio_pad_select_gpio(LED_GPIO_PIN)
    putString("result=")
    putChar(UInt8(48 + UInt8(padResult % 10)))
    putLine("")

    // Step 2: ROM signal matrix connection
    putString("Step 2: ROM output signal connection... ")
    esp_rom_gpio_connect_out_signal(LED_GPIO_PIN, SIG_GPIO_OUT_IDX, false, false)
    putLine("done")

    // Step 3: Configure ENABLE register (critical for output direction)
    putString("Step 3: Setting ENABLE register... ")
    gpio.enable.modify { enable in
        let currentBits = UInt32(enable.raw.storage)
        let newBits = currentBits | (1 << LED_GPIO_PIN)
        enable = .init(.init(newBits))
    }
    putLine("done")

    // Step 4: Try setting additional registers if available
    putString("Step 4: Additional register configuration... ")

    // Try enable_w1ts (Write-1-to-Set) register
    gpio.enable_w1ts.write { enable_w1ts in
        enable_w1ts = .init(.init(1 << LED_GPIO_PIN))
    }
    putLine("enable_w1ts set")

    // Step 5: Initialize output state
    putString("Step 5: Setting initial output state... ")
    setLED(on: false)
    putLine("OFF")

    // Debug: Print final register states
    putLine("Final states:")
    putString("ENABLE: ")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: ")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")

    putLine("=== GPIO8 Configuration Complete ===")
    flushUART()
}

// Enhanced LED control with debugging
private func setLED(on: Bool) {
    if on {
        // Try multiple methods to set the pin

        // Method 1: Direct OUT register
        gpio.out.modify { out in
            let currentBits = UInt32(out.raw.storage)
            let newBits = currentBits | (1 << LED_GPIO_PIN)
            out = .init(.init(newBits))
        }

        // Method 2: Write-1-to-Set register if available
        gpio.out_w1ts.write { out_w1ts in
            out_w1ts = .init(.init(1 << LED_GPIO_PIN))
        }

    } else {
        // Method 1: Direct OUT register
        gpio.out.modify { out in
            let currentBits = UInt32(out.raw.storage)
            let newBits = currentBits & ~(1 << LED_GPIO_PIN)
            out = .init(.init(newBits))
        }

        // Method 2: Write-1-to-Clear register if available
        gpio.out_w1tc.write { out_w1tc in
            out_w1tc = .init(.init(1 << LED_GPIO_PIN))
        }
    }
}

@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()

    // Initialize LED with enhanced debugging
    initializeLED()

    // Simple main loop with status output
    var cycle = 0
    while true {
        if cycle % 10 == 0 {
            putString("LED ON (cycle ")
            putChar(UInt8(48 + (cycle / 10) % 10))
            putLine(")")
            flushUART()
        }

        setLED(on: true)
        delayMilliseconds(200)
        setLED(on: false)
        delayMilliseconds(800)

        cycle += 1
    }
}

@_cdecl("swift_main")
public func swiftMain() {
    putLine("ESP32-C6 Enhanced GPIO Debug Example!")
    putLine("Detailed register analysis and configuration")
    flushUART()

    // IMPORTANT: Initialize the LED first!
    initializeLED()

    var counter = 0

    while true {
        putString("Debug cycle ")
        putChar(UInt8(48 + (counter % 10)))
        putLine("")

        // Print current register states during operation
        if counter % 5 == 0 {
            putLine("Current states:")
            putString("ENABLE: ")
            printHex32(UInt32(gpio.enable.read().raw.storage))
            putLine("")
            putString("OUT: ")
            printHex32(UInt32(gpio.out.read().raw.storage))
            putLine("")
        }
        flushUART()

        // Test pattern
        setLED(on: true)
        delayMicroseconds(100_000)
        setLED(on: false)
        delayMicroseconds(100_000)

        setLED(on: true)
        delayMicroseconds(500_000)
        setLED(on: false)
        delayMicroseconds(500_000)

        counter += 1
        if counter >= 20 {
            putLine("=== Register Analysis Complete ===")
            flushUART()
            counter = 0
        }
    }
}

@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
    memptr.pointee = nil
    return 12 // ENOMEM
}

@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}