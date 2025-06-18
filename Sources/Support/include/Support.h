#pragma once

static inline __attribute((always_inline)) void nop() {
    asm volatile("nop");
}
