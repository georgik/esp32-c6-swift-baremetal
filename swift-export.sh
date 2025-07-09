#!/bin/bash

../swift-mmio/.build/arm64-apple-macosx/debug/SVD2Swift \
  --input ../esp-pacs/esp32c6/svd/esp32c6.base.svd \
  --output Sources/Registers \
  --access-level public \
  --peripherals GPIO UART0 SPI0 SPI1 SPI2 I2C0 PMU LP_WDT TIMG0 LEDC RMT PCNT SYSTIMER IO_MUX PCR MODEM_SYSCON MODEM_LPCON INTERRUPT_CORE0

