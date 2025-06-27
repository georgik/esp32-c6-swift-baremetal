
# ESP32-C6 Bare Metal Swift Console Example

This project demonstrates **Embedded Swift** running bare metal on the ESP32-C6 RISC-V microcontroller. It showcases console output using ESP32 ROM UART functions, proving that Swift can run efficiently on resource-constrained embedded systems without an operating system.

![ESP32-C6 Embedded Swift Wokwi](Documentation/Images/esp32-c6-embedded-swift-wokwi.webp)

## What it does

The application:
- Runs bare metal Swift code on ESP32-C6 (RISC-V architecture)
- Send graphics to SPI display
- Uses ESP32 ROM UART functions for reliable console communication
- Uses GPIO to drive led

## Architecture Overview

This project is composed of several key components:

### 1. **Swift Application Layer**
- **`Sources/Application/main.swift`**: Main Swift application with console output functions
- Uses `@_cdecl("swift_main")` to provide C-compatible entry point
- Implements UART communication using ESP32 ROM functions

### 2. **Hardware Abstraction Layer**
- **`Sources/Registers/`**: Generated MMIO register definitions for ESP32-C6 peripherals
- **`Sources/Support/`**: C support code and linker scripts
- Uses Apple's [swift-mmio](https://github.com/apple/swift-mmio) library for type-safe hardware access
- Uses Espressif [SVDs](https://github.com/espressif/svd)
- Uses ESP-RS [ESP-HAL linker scripts](https://github.com/esp-rs/esp-hal/tree/main/esp-hal/ld/esp32c6)

### 3. **Build System**
- **Embedded Swift**: Uses Swift's experimental embedded mode (`-enable-experimental-feature Embedded`)
- **RISC-V Target**: Compiles for `riscv32-none-none-elf` architecture
- **Custom Linker Scripts**: ESP32-C6 specific memory layout and ROM function mapping
- **Makefile-based**: Simple build system for embedded development

### 4. **Console Communication**
The project demonstrates two approaches to UART communication:
- **ESP32 ROM Functions** (current implementation): Uses proven ROM UART functions
- **Direct Register Access**: Alternative using generated MMIO register definitions

## Technical Details

### Memory Layout
- Uses ESP32-C6 specific linker scripts in `Sources/Support/ld/esp32c6/`
- Maps Swift code to appropriate memory regions
- Links against ESP32 ROM functions for UART operations

### Swift Embedded Features
- **No Standard Library**: Bare metal environment without Foundation/stdlib
- **No Garbage Collector**: Manual memory management suitable for embedded systems
- **Whole Module Optimization**: Optimized for size and performance
- **Static Linking**: Everything compiled into a single binary

### Hardware Requirements
- ESP32-C6 development board (ESP32-C6-DevKitC-1 recommended)
- USB cable for programming and console output

## Build Requirements

- **Swift 6.2 nightly** or later with Embedded Swift support
- [espflash](https://github.com/esp-rs/espflash)  - single binary flasher
  - installation: `cargo install espflash`

## Building and Running

### Build the project:
```bash
make
```

### Flash to ESP32-C6:
```bash
make flash
```

### Monitor console output:
```bash
espflash monitor
```

Expected output:
```
ESP32-C6
Registers and configuration

=== Watchdog Status Analysis ===
Checking watchdog status BEFORE disabling:
TIMG0 MWDT enabled: false, config0: 0x0x00448000
TIMG1 MWDT enabled: false, config0: 0x0x0004C000
RWDT (LP_WDT) enabled: false, config0: 0x0x00012214

==> Disabling all watchdogs...

Checking watchdog status AFTER disabling:
TIMG0 MWDT enabled: false, config0: 0x0x00000000
TIMG1 MWDT enabled: false, config0: 0x0x00000000
RWDT (LP_WDT) enabled: false, config0: 0x0x00012214

Watchdog disabling complete.

Watchdog control registers:
- TIMG0 base: 0x60008000 (MWDT0 control)
- TIMG1 base: 0x60009000 (MWDT1 control)
- LP_WDT base: 0x600B1C00 (RWDT control)
- Key register field: wdtconfig0.wdt_en (bit 31)
=== End Watchdog Analysis ===
=== Boot Diagnostics ===
Reset reason (code 1): Power-on reset
=== End Boot Diagnostics ===
Initial states:
ENABLE: 0x0x00000000
OUT: 0x0x00000000
Step 1: Configuring IO_MUX... (initial: 0x0x60002000) configured: 0x0x60002801
Step 2: ROM pad select... result=6
Step 3: ROM pad unhold... done
Step 4: ROM set drive strength... done
Step 5: ROM output signal connection... done
Step 6: Setting ENABLE register... done
Step 7: Initialize output to LOW... [OK] LED OFF confirmed: 0x0x00000000
done
Final states:
ENABLE: 0x0x00000100
OUT: 0x0x00000000
IO_MUX final: 0x0x60002801
=== GPIO Initialization Complete ===
Initializing SPI for display communication...
=== Starting Display Application ===
STEP 1: Power and Wiring Diagnostics...
=== GPIO Power and Wiring Diagnostics ===
```

### Convert to image format

If you need the image format, you can use the following target

```bash
make elf2image
```

## Simulation Support

This project includes **Wokwi Simulator** support for testing without physical hardware:

1. Install [Wokwi Simulator plugin](https://plugins.jetbrains.com/plugin/23826-wokwi-simulator) for CLion
2. Open the project and run simulation
3. View console output in the simulator

![ESP32-C6 Embedded Swift Wokwi](Documentation/Images/esp32-c6-embedded-swift-wokwi.webp)

## Project Structure

```
esp32-c6-blink/
├── Sources/
│   ├── Application/
│   │   └── main.swift              # Main Swift application
│   ├── Registers/
│   │   └── UART0.swift            # Generated UART register definitions
│   └── Support/
│       ├── include/               # C headers
│       ├── ld/                    # Linker scripts
│       └── esp_app_desc.c         # ESP32 app descriptor
├── Makefile                       # Build system
├── Package.swift                  # Swift package definition
├── esp32-c6-elf.json            # Embedded Swift compiler configuration
└── README.md                      # This file
```

## Exporting registers

Registers are based on [ESP-PACS](https://github.com/esp-rs/esp-pacs/).

Prerequisites: SVD2Swift
```shell
git clone https://github.com/apple/swift-mmio.git --shallow-submodules --depth 10
cd swift-mmio
swift build --product SVD2Swift
```

Command for exporting registers to Swift (`swift-export.sh`):

```shell
git clone git@github.com:esp-rs/esp-pacs.git
cd esp32-c6-swift-baremetal

SVD2Swift \
  --input ../esp-pacs/esp32c6/svd/esp32c6.svd \
  --output Sources/Registers \
  --access-level public \
  --peripherals GPIO UART0 SPI0
```

## Key Technologies

- **[Embedded Swift](https://github.com/swiftlang/swift/tree/main/docs/EmbeddedSwift)**: Swift's embedded compilation mode
- **[Swift MMIO](https://github.com/apple/swift-mmio)**: Type-safe hardware register access
- **ESP32-C6**: RISC-V based microcontroller with WiFi/Bluetooth
- **Bare Metal**: No operating system, direct hardware control
