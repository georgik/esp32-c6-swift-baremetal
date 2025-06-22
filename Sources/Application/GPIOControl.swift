import MMIO
import Registers

let LED_GPIO_PIN: UInt32 = 8
let SIG_GPIO_OUT_IDX: UInt32 = 128  // GPIO simple output signal

func initializeLED() {
    putLine("=== ESP32-C6 GPIO8 Configuration ===")
    flushUART()

    putLine("Initial states:")
    putString("ENABLE: ")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: ")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")
    flushUART()

    putString("Step 1: ROM pad select... ")
    let padResult = esp_rom_gpio_pad_select_gpio(LED_GPIO_PIN)
    putString("result=")
    putChar(UInt8(48 + UInt8(padResult % 10)))
    putLine("")

    putString("Step 2: ROM output signal connection... ")
    esp_rom_gpio_connect_out_signal(LED_GPIO_PIN, SIG_GPIO_OUT_IDX, false, false)
    putLine("done")

    putString("Step 3: Setting ENABLE register... ")
    gpio.enable.modify { enable in
        let currentBits = UInt32(enable.raw.storage)
        let newBits = currentBits | (1 << LED_GPIO_PIN)
        enable = .init(.init(newBits))
    }
    putLine("done")

    putString("Step 4: Additional register configuration... ")
    gpio.enable_w1ts.write { enable_w1ts in
        enable_w1ts = .init(.init(1 << LED_GPIO_PIN))
    }
    putLine("done")

    putLine("Final states:")
    putString("ENABLE: ")
    printHex32(UInt32(gpio.enable.read().raw.storage))
    putLine("")
    putString("OUT: ")
    printHex32(UInt32(gpio.out.read().raw.storage))
    putLine("")
    flushUART()
}

func ledOn() {
    gpio.out.modify { out in
        let currentBits = UInt32(out.raw.storage)
        let newBits = currentBits | (1 << LED_GPIO_PIN)
        out = .init(.init(newBits))
    }
}

func ledOff() {
    gpio.out.modify { out in
        let currentBits = UInt32(out.raw.storage)
        let newBits = currentBits & ~(1 << LED_GPIO_PIN)
        out = .init(.init(newBits))
    }
}

// Enhanced LED control with debugging
func setLED(on: Bool) {
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
