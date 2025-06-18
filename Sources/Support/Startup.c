#include <stdint.h>

extern int main(void);

// Symbols from linker script
extern uint32_t __stack_top;

// Reset entry point
__attribute__((naked)) void _start(void) {
    asm volatile("la sp, __stack_top");
    main();
    while (1) {}
}

// Minimal interrupt vector table
__attribute__((section(".vectors")))
void *vector_table[32] = {
    (void *) &__stack_top,  // Initial stack pointer
    _start                  // Reset handler
};

