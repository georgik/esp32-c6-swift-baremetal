import MMIO
import Device
import GPIO

@main
struct Main {
    static func main() {
        // Enable GPIO peripheral (ESP32-C3 always has GPIO, no RCC enable required)

        let gpio = UnsafeMutablePointer<RegisterBlock>(bitPattern: 0x60004000)!.pointee

        // Configure GPIO2 as output (bit 2)
        gpio.enable_w1ts.write { $0.en |= 1 << 2 }

        var counter: UInt32 = 0

        while true {
            if counter % 2 == 0 {
                gpio.out_w1ts.write { $0.out |= 1 << 2 } // LED ON
            } else {
                gpio.out_w1tc.write { $0.out |= 1 << 2 } // LED OFF
            }

            delay()
            counter += 1
        }
    }
}

/// Very crude busy loop (replace with timer later)
func delay() {
    for _ in 0..<10_000_000 {
        _ = 0
    }
}

