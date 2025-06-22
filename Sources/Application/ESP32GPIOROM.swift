@_silgen_name("esp_rom_gpio_pad_select_gpio")
func esp_rom_gpio_pad_select_gpio(_ gpio_num: UInt32) -> Int32

@_silgen_name("esp_rom_gpio_connect_out_signal")
func esp_rom_gpio_connect_out_signal(_ gpio_num: UInt32, _ signal_idx: UInt32, _ out_inv: Bool, _ oen_inv: Bool)
