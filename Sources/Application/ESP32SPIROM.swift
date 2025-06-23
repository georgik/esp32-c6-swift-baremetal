// ESP32-C6 ROM SPI Functions
// These functions are provided by the ESP32-C6 ROM and linked via esp32c6.rom.api.ld

import MMIO

// SPI Flash ROM functions (already available in ROM)
@_silgen_name("esp_rom_spiflash_attach")
func esp_rom_spiflash_attach(_ config: UInt32, _ legacy: Bool) -> Int32

@_silgen_name("esp_rom_spiflash_write_enable")
func esp_rom_spiflash_write_enable() -> Int32

@_silgen_name("esp_rom_spiflash_common_cmd")
func esp_rom_spiflash_common_cmd(_ cmd: UnsafePointer<UInt8>) -> Int32

// SPI peripheral signal indices for ESP32-C6 GPIO matrix
enum SPISignals {
    // SPI0/SPI1 signals (for flash/PSRAM - usually not used for peripherals)
    static let FSPICLK_OUT_IDX: UInt32 = 63
    static let FSPID_OUT_IDX: UInt32 = 64
    static let FSPIQ_OUT_IDX: UInt32 = 65
    static let FSPICS0_OUT_IDX: UInt32 = 66

    // SPI2 signals (recommended for peripheral communication)
    static let SPI2_CLK_OUT_IDX: UInt32 = 67
    static let SPI2_MOSI_OUT_IDX: UInt32 = 68
    static let SPI2_MISO_IN_IDX: UInt32 = 69
    static let SPI2_CS_OUT_IDX: UInt32 = 70

    // GPIO simple signals
    static let GPIO_OUT_IDX: UInt32 = 128
}

// SPI Clock frequencies (in Hz)
enum SPIClockFreq {
    static let FREQ_1MHZ: UInt32 = 1_000_000
    static let FREQ_5MHZ: UInt32 = 5_000_000
    static let FREQ_10MHZ: UInt32 = 10_000_000
    static let FREQ_20MHZ: UInt32 = 20_000_000
    static let FREQ_40MHZ: UInt32 = 40_000_000
}

// SPI Modes
enum SPIMode {
    static let MODE_0: UInt8 = 0  // CPOL=0, CPHA=0
    static let MODE_1: UInt8 = 1  // CPOL=0, CPHA=1
    static let MODE_2: UInt8 = 2  // CPOL=1, CPHA=0
    static let MODE_3: UInt8 = 3  // CPOL=1, CPHA=1
}