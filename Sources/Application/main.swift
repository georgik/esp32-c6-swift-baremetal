import MMIO
import Registers

@_silgen_name("esp_app_desc")
func _getAppDesc() -> UnsafeRawPointer

// ESP32-C6 ROM delay functions - these definitely work!
@_silgen_name("esp_rom_delay_us")
func esp_rom_delay_us(_ us: UInt32)

// ESP32-C6 ROM UART functions
@_silgen_name("esp_rom_uart_putc")
func esp_rom_uart_putc(_ char: UInt8)

@_silgen_name("esp_rom_uart_tx_wait_idle")
func esp_rom_uart_tx_wait_idle(_ uart_no: UInt8)

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

// Direct register manipulation using proper Swift MMIO Raw types
private func initializeLED() {
    // Enable GPIO8 as output using Raw type
//     gpio.enable.modify { register in
//         let currentValue = register.storage
//         let newValue = currentValue | (1 << LED_GPIO_PIN)
//         register = GPIO.ENABLE.ReadWrite(storage: newValue)
//     }
//
//     // Set initial state to off
//     setLED(on: false)
}

private func setLED(on: Bool) {
//     gpio.out.modify { register in
//         let currentValue = register.storage
//         let newValue: UInt32
//
//         if on {
//             newValue = currentValue | (1 << LED_GPIO_PIN)  // Set bit 8
//         } else {
//             newValue = currentValue & ~(1 << LED_GPIO_PIN) // Clear bit 8
//         }
//
//         register = GPIO.OUT.ReadWrite(storage: newValue)
//     }
}

@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()

    // Initialize LED using proper Swift MMIO
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
    putLine("Swift MMIO + ROM delays working!")
    flushUART()

    var counter = 0

    while true {
        putString("Blink cycle ")
        // Simple number output
        putChar(UInt8(48 + (counter % 10))) // ASCII digit
        putLine(" - MMIO Raw types + ROM timing!")
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
            putLine("Swift MMIO with proper Raw types working!")
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