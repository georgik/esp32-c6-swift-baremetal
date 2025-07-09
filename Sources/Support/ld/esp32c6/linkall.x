/* ESP32-C6 linker script - 3 segments with proper alignment */

MEMORY
{
    RAM : ORIGIN = 0x40800000, LENGTH = 500K
    ROM : ORIGIN = 0x42000000, LENGTH = 4M
    ROM_ENTRY : ORIGIN = 0x42010000, LENGTH = 4M - 64K  /* Next 64KB boundary */
    RTC_FAST : ORIGIN = 0x50000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS
{
    /* Segment 0: App header + main application code (first 64KB) */
    .text 0x42000020 : {
        /* App descriptor must be first */
        *(.rodata.esp_app_desc)

        /* Align and place all main code */
        . = ALIGN(4);
        *(.text .text.*)
        *(.rodata .rodata.*)

        /* Pad to end of 64KB boundary minus some margin */
        . = ALIGN(16);
    } > ROM

    /* Segment 1: RAM data (loaded from flash to RAM) */
    .data : {
        _sdata = .;
        *(.data .data.*)
        _edata = .;
    } > RAM AT > ROM

    _sidata = LOADADDR(.data);

    /* Segment 2: Entry vectors (separate 64KB region) */
    .entry_point : {
        . = ALIGN(4);
        *(.vectors .vectors.*)
        KEEP(*(.entry_point))
        . = ALIGN(16);
    } > ROM_ENTRY

    /* Uninitialized data */
    .bss (NOLOAD) : {
        _sbss = .;
        *(.bss .bss.*)
        *(COMMON)
        _ebss = .;
    } > RAM

    /* Stack and heap */
    .heap_stack (NOLOAD) : {
        . = ALIGN(8);
        _sheap = .;
        . += 0x1000;
        _eheap = .;
        . = ALIGN(8);
        _estack = .;
    } > RAM

    /* Discard problematic sections */
    /DISCARD/ : {
        *(.text_gap)
        *(.debug*)
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
        *(.gnu*)
        *(.riscv.attributes)
        *(.swift_modhash)
        *(.noinit*)
    }
}

_stack_start = ORIGIN(RAM) + LENGTH(RAM);

INCLUDE "rom-functions.x"