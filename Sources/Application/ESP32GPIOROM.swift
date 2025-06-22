// ESP32-C6 ROM GPIO Functions
// These functions are provided by the ESP32-C6 ROM and linked via esp32c6.rom.api.ld

@_silgen_name("esp_rom_gpio_pad_select_gpio")
func esp_rom_gpio_pad_select_gpio(_ gpio_num: UInt32) -> Int32

@_silgen_name("esp_rom_gpio_pad_set_level")
func esp_rom_gpio_pad_set_level(_ gpio_num: UInt32, _ level: UInt32)

@_silgen_name("esp_rom_gpio_pad_pullup_only")  
func esp_rom_gpio_pad_pullup_only(_ gpio_num: UInt32)

@_silgen_name("esp_rom_gpio_pad_set_drv")
func esp_rom_gpio_pad_set_drv(_ gpio_num: UInt32, _ drv: UInt32)

@_silgen_name("esp_rom_gpio_pad_unhold")
func esp_rom_gpio_pad_unhold(_ gpio_num: UInt32)

@_silgen_name("esp_rom_gpio_connect_in_signal")
func esp_rom_gpio_connect_in_signal(_ gpio_num: UInt32, _ signal_idx: UInt32, _ inv: Bool)

@_silgen_name("esp_rom_gpio_connect_out_signal")
func esp_rom_gpio_connect_out_signal(_ gpio_num: UInt32, _ signal_idx: UInt32, _ out_inv: Bool, _ oen_inv: Bool)