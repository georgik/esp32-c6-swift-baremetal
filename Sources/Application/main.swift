import MMIO
import Registers

@_silgen_name("esp_app_desc")
func _getAppDesc() -> UnsafeRawPointer

@_cdecl("_start")
public func _start() -> Never {
    // Force reference to app descriptor
    _ = _getAppDesc()


    // Simple bare metal main loop
    while true {
        setLED(on: true)
        busyWait(cycles: 5_000_000)
        setLED(on: false)
        busyWait(cycles: 15_000_000)
    }
}

// Simple LED control
private func setLED(on: Bool) {
    let gpioBase = UnsafeMutablePointer<UInt32>(bitPattern: 0x60004000)!
    if on {
        gpioBase.pointee |= (1 << 8)
    } else {
        gpioBase.pointee &= ~(1 << 8)
    }
}

private func busyWait(cycles: UInt32) {
    var counter: UInt32 = 0
    while counter < cycles {
        counter += 1
        _ = counter
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

// Declare ESP32-C6 ROM UART functions
@_silgen_name("esp_rom_uart_putc")
func esp_rom_uart_putc(_ char: UInt8)

@_silgen_name("esp_rom_uart_tx_wait_idle")
func esp_rom_uart_tx_wait_idle(_ uart_no: UInt8)

@_silgen_name("esp_rom_uart_tx_one_char")
func esp_rom_uart_tx_one_char(_ char: UInt8) -> Int32

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

@_cdecl("swift_main")
public func swiftMain() {
    // Add a small delay to let the system stabilize
    for _ in 0..<1000000 { }

    // Print a hello message
    putLine("Hello from Swift on ESP32-C6!")
    flushUART()

    var counter = 0

    // Loop with periodic output
    while true {
        putLine("Swift is running...")
        flushUART()

        // Simple delay
        for _ in 0..<5000000 {
            // Empty loop body for delay
        }

        counter += 1
        if counter >= 10 {
            putLine("Completed 10 iterations, continuing...")
            flushUART()
            counter = 0
        }
    }
}