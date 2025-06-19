/* Minimal ESP32-C6 linker script for Embedded Swift baremetal */

/* Import the ESP32-C6 memory map and ROM defaults */
/* .x files from: https://github.com/esp-rs/esp-hal/tree/main/esp-hal/ld */
INCLUDE "memory.x"
INCLUDE "linkall.x"
INCLUDE "esp32c6.x"
INCLUDE "rom-functions.x"

ENTRY(_start)

SECTIONS
{
  .vectors : ALIGN(4)
  {
    KEEP(*(.vectors))
  } > RAM

  .text : ALIGN(4)
  {
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : ALIGN(4)
  {
    *(.data*)
  } > dram2_seg AT > ROM

  .bss (NOLOAD) : ALIGN(4)
  {
    *(.bss*)
    *(COMMON)
  } > dram2_seg

  .heap (NOLOAD) : ALIGN(8)
  {
    __heap_start = .;
    . = . + 32K;
    __heap_end = .;
  } > RTC_FAST

  .stack (NOLOAD) : ALIGN(8)
  {
    . = ALIGN(16);
    __stack_top = .;
    . = . + 8K;
    __stack_end = .;
  } > RAM
}
