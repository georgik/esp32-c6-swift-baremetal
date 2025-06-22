func delayMicroseconds(_ microseconds: UInt32) {
    esp_rom_delay_us(microseconds)
}

func delayMilliseconds(_ milliseconds: UInt32) {
    esp_rom_delay_us(milliseconds * 1000)
}
