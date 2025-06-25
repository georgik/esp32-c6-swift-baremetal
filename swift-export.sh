#!/bin/bash

SVD2Swift \
  --input ../esp32c6/svd/esp32c6.svd \
  --output Sources/Registers \
  --access-level public \
  --peripherals GPIO UART0 SPI0 SPI1 SPI2 I2C0 CLINT PMU LP_WDT TIMG0 LEDC RMT PCNT SYSTIMER IO_MUX PCR

