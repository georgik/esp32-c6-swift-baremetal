MEMORY
{
    RAM : ORIGIN = 0x40800000, LENGTH = 500K
    ROM : ORIGIN = 0x42000000, LENGTH = 4M
    RTC_FAST : ORIGIN = 0x50000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS
{
    /* Single merged section starting from ROM origin */
    .text : {
        /* Pad to offset 0x20 where ESP32 expects app descriptor */
        . = 0x20;
        *(.rodata.esp_app_desc)  /* App descriptor at exactly offset 0x20 */
        
        /* Continue with normal code/data */
        *(.vectors .vectors.*)
        *(.text .text.*)
        
        /* Align and include rodata */
        . = ALIGN(4);
        *(.rodata .rodata.*)
    } > ROM

    .data : {
        *(.data .data.*)
        *(.data.wifi .data.wifi.*)
    } > RAM AT > ROM

    .bss (NOLOAD) : {
        *(.bss .bss.*)
        *(COMMON)
    } > RAM

    .noinit (NOLOAD) : {
        *(.noinit .noinit.*)
    } > RAM

    .shstrtab : { *(.shstrtab) }
    .strtab : { *(.strtab) }
    .symtab : { *(.symtab) }

    /DISCARD/ : {
        *(.debug*)
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
        *(.gnu*)
        *(.riscv.attributes)
        *(.swift_modhash)
        *(.wifi_log_*)
        *(.wifi_*)
    }
}
