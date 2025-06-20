MEMORY
{
    RAM : ORIGIN = 0x40800000, LENGTH = 500K
    ROM : ORIGIN = 0x42000020, LENGTH = 4M - 32
    RTC_FAST : ORIGIN = 0x50000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS
{
    .text : {
        *(.vectors .vectors.*)
        *(.text .text.*)
    } > ROM

    .rodata : {
        *(.rodata .rodata.*)
    } > ROM

    .data : {
        *(.data .data.*)
        /* Explicitly include WiFi data but don't create separate region */
        *(.data.wifi .data.wifi.*)
    } > RAM AT > ROM

    .bss (NOLOAD) : {
        *(.bss .bss.*)
        *(COMMON)
    } > RAM

    .noinit (NOLOAD) : {
        *(.noinit .noinit.*)
    } > RAM

    /* Keep essential sections */
    .shstrtab : { *(.shstrtab) }
    .strtab : { *(.strtab) }
    .symtab : { *(.symtab) }

    /* Discard debug and unwanted sections, but not system ones */
    /DISCARD/ : {
        *(.debug*)
        *(.comment*)
        *(.note*)
        *(.eh_frame*)
        *(.gnu*)
        *(.riscv.attributes)
        *(.swift_modhash)
        /* Specifically discard WiFi stuff we don't want in this iteration */
        *(.wifi_log_*)
        *(.wifi_*)
    }


}
