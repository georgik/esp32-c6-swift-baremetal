/* Standalone ESP32-C6 linker script - no includes */

MEMORY
{
    /* ESP32-C6 memory layout */
    RAM : ORIGIN = 0x40800000, LENGTH = 500K
    ROM : ORIGIN = 0x42000000, LENGTH = 4M
    RTC_FAST : ORIGIN = 0x50000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS
{
    /* Single text section starting at ROM + 0x20 */
    .text 0x42000020 : {
        /* App descriptor must be first */
        *(.rodata.esp_app_desc)
        
        /* Align and place all executable code */
        . = ALIGN(4);
        *(.vectors .vectors.*)
        *(.text .text.*)
        
        /* Read-only data */
        . = ALIGN(4);
        *(.rodata .rodata.*)
    } > ROM

    /* Initialized data (copied from ROM to RAM at startup) */
    .data : {
        _sdata = .;
        *(.data .data.*)
        _edata = .;
    } > RAM AT > ROM
    
    _sidata = LOADADDR(.data);

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
        . += 0x1000; /* 4KB heap */
        _eheap = .;
        . = ALIGN(8);
        _estack = .;
    } > RAM

    /* Completely discard all problematic sections */
    /DISCARD/ : {
        *(.text_gap)
        *(.data.wifi*)
        *(.wifi*)
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

/* Define required symbols */
_stack_start = ORIGIN(RAM) + LENGTH(RAM);