
/* Minimal ESP32-C6 linker script for Embedded Swift baremetal */

MEMORY
{
  /* Adjust sizes according to C6 datasheet */
  IROM (rx) : ORIGIN = 0x42000000, LENGTH = 1M
  IRAM (rx) : ORIGIN = 0x40800000, LENGTH = 512K
  DRAM (rw) : ORIGIN = 0x3FC80000, LENGTH = 512K
}

ENTRY(_start)

SECTIONS
{
  .vectors : ALIGN(4)
  {
    KEEP(*(.vectors))
  } > IRAM

  .text : ALIGN(4)
  {
    *(.text*)
    *(.rodata*)
  } > IRAM

  .data : ALIGN(4)
  {
    *(.data*)
  } > DRAM AT > IROM

  .bss (NOLOAD) : ALIGN(4)
  {
    *(.bss*)
    *(COMMON)
  } > DRAM

  .heap (NOLOAD) : ALIGN(8)
  {
    __heap_start = .;
    . = . + 32K;
    __heap_end = .;
  } > DRAM

  .stack (NOLOAD) : ALIGN(8)
  {
    . = ALIGN(16);
    __stack_top = .;
    . = . + 8K;
    __stack_end = .;
  } > DRAM
}
