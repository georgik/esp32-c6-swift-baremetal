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

func printHex32(_ value: UInt32) {
    putString("0x")
    for i in (0..<8).reversed() {
        let nibble = (value >> (i * 4)) & 0xF
        if nibble < 10 {
            putChar(48 + UInt8(nibble))  // '0'-'9'
        } else {
            putChar(65 + UInt8(nibble - 10))  // 'A'-'F'
        }
    }
}