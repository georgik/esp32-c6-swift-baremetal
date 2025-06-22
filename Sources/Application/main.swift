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

// ESP32-C6 ROM GPIO functions - found in the linker files!
@_silgen_name("esp_rom_gpio_pad_select_gpio")
func esp_rom_gpio_pad_select_gpio(_ gpio_num: UInt32) -> Int32

// Additional ROM GPIO functions from ESP32-C6 ROM
@_silgen_name("gpio_pad_select_gpio")
func gpio_pad_select_gpio(_ gpio_num: UInt32) -> Int32

// Constants
let LED_GPIO_PIN: UInt32 = 8

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

func delaySeconds(_ seconds: UInt32) {
    delayMilliseconds(seconds * 1000)
}

// GPIO using Swift MMIO with unlabeled initializers
private func initializeLED() {
    // First, configure the GPIO pad using ROM function
    let result = esp_rom_gpio_pad_select_gpio(LED_GPIO_PIN)

    // Now use Swift MMIO with unlabeled initializers
    // Enable GPIO8 as output - use the generated gpio instance
    gpio.enable.modify { enable in
        // Convert Raw type to UInt32 for bit operations
        let currentBits = UInt32(enable.raw.storage)
        let newBits = currentBits | (1 << LED_GPIO_PIN)
        enable = .init(.init(newBits))
    }

    // Set initial state to off
    setLED(on: false)
}

private func setLED(on: Bool) {
    gpio.out.modify { out in
        // Convert Raw type to UInt32 for bit operations
        let currentBits = UInt32(out.raw.storage)
        let newBits: UInt32

        if on {
            newBits = currentBits | (1 << LED_GPIO_PIN)  // Set bit 8
        } else {
            newBits = currentBits & ~(1 << LED_GPIO_PIN) // Clear bit 8
        }

        out = .init(.init(newBits))
    }
}

@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()

    // Initialize LED using ROM + Swift MMIO
    initializeLED()

    // Simple bare metal main loop with ROM-based timing
    while true {
        setLED(on: true)
        delayMilliseconds(200)  // 200ms on
        setLED(on: false)
        delayMilliseconds(800)  // 800ms off (1 second total)
    }
}

@_cdecl("swift_main")
public func swiftMain() {
    // Print startup message
    putLine("Hello from Swift on ESP32-C6!")
    putLine("ROM GPIO + Swift MMIO registers!")
    flushUART()

    var counter = 0

    while true {
        putString("Blink cycle ")
        // Simple number output
        putChar(UInt8(48 + (counter % 10))) // ASCII digit
        putLine(" - ROM pad select + MMIO registers!")
        flushUART()

        // Demonstrate different LED patterns
        // Fast blink
        setLED(on: true)
        delayMicroseconds(100_000)  // 100ms
        setLED(on: false)
        delayMicroseconds(100_000)

        // Slow blink
        setLED(on: true)
        delayMicroseconds(500_000)  // 500ms
        setLED(on: false)
        delayMicroseconds(500_000)

        counter += 1
        if counter >= 10 {
            putLine("ROM + Swift MMIO combination working!")
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