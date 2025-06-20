/* ESP32-C6 Memory Layout */
MEMORY
{
    /* Flash memory - ESP32-C6 typically has 4MB+ */
    FLASH (rx) : ORIGIN = 0x42000000, LENGTH = 4M
}

/* Entry point */
ENTRY(_start)

/* Stack size */
PROVIDE(_stack_size = 8K);

/* Heap size for memory allocation */
PROVIDE(_heap_size = 32K);

/* Define sections */
SECTIONS
{
    .text :
    {
        *(.text)
        *(.text.*)
    } > FLASH

    .data :
    {
        *(.data)
        *(.data.*)
    } > RAM AT > FLASH

    .bss :
    {
        *(.bss)
        *(.bss.*)
    } > RAM

    /* Define heap and stack */
    .heap :
    {
        _heap_start = .;
        . += _heap_size;
        _heap_end = .;
    } > RAM

    .stack :
    {
        _stack_start = .;
        . += _stack_size;
        _stack_end = .;
    } > RAM
}