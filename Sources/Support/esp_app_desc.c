#include <stdint.h>

// ESP32 app descriptor structure - matches ESP-IDF format
typedef struct {
    uint32_t magic_word;        ///< Magic word ESP_APP_DESC_MAGIC_WORD
    uint32_t secure_version;    ///< Secure version
    uint32_t reserv1[2];       ///< Reserved bytes
    char version[32];           ///< Application version
    char project_name[32];      ///< Project name
    char time[16];              ///< Compile time
    char date[16];              ///< Compile date
    char idf_ver[32];           ///< Version IDF
    uint8_t app_elf_sha256[32]; ///< sha256 of elf file
    uint32_t reserv2[20];       ///< Reserved bytes
} esp_app_desc_t;

// Magic word (0xabcd5432)
#define ESP_APP_DESC_MAGIC_WORD 0xabcd5432

// Place the app descriptor in the special section
__attribute__((section(".rodata.esp_app_desc")))
static const esp_app_desc_t app_desc_data = {
    .magic_word = ESP_APP_DESC_MAGIC_WORD,
    .secure_version = 0,
    .reserv1 = {0, 0},
    .version = "1.0.0",
    .project_name = "SwiftBlink",
    .time = __TIME__,
    .date = __DATE__,
    .idf_ver = "v5.0",
    .app_elf_sha256 = {0},
    .reserv2 = {0}
};

// Function to return the address of the app descriptor
void* esp_app_desc(void) {
    return (void*)&app_desc_data;
}


// Minimal libc functions required by Swift embedded runtime

#include <stddef.h>

void* memset(void* s, int c, size_t n) {
    unsigned char* p = (unsigned char*)s;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return s;
}

void* memcpy(void* dest, const void* src, size_t n) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

void* memmove(void* dest, const void* src, size_t n) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;

    if (d < s) {
        while (n--) {
            *d++ = *s++;
        }
    } else {
        d += n;
        s += n;
        while (n--) {
            *--d = *--s;
        }
    }
    return dest;
}

int memcmp(const void* s1, const void* s2, size_t n) {
    const unsigned char* p1 = (const unsigned char*)s1;
    const unsigned char* p2 = (const unsigned char*)s2;
    while (n--) {
        if (*p1 != *p2) {
            return *p1 - *p2;
        }
        p1++;
        p2++;
    }
    return 0;
}


extern void swift_main(void);


__attribute__((section(".entry_point"))) void _start(void) {
    // Disable RWDT (Real-time Watchdog Timer) before launching the app
    // ESP32-C6 LP_WDT (RWDT) register addresses
    #define LP_WDT_BASE         0x600B1C00
    #define LP_WDT_WDTCONFIG0   (LP_WDT_BASE + 0x0)
    #define LP_WDT_WDTFEED      (LP_WDT_BASE + 0x14)
    #define LP_WDT_WDTWPROTECT  (LP_WDT_BASE + 0x18)
    #define WDT_WKEY            0x50D83AA1
    
    // Access registers as volatile pointers
    volatile uint32_t* wdt_protect = (volatile uint32_t*)LP_WDT_WDTWPROTECT;
    volatile uint32_t* wdt_config0 = (volatile uint32_t*)LP_WDT_WDTCONFIG0;
    volatile uint32_t* wdt_feed = (volatile uint32_t*)LP_WDT_WDTFEED;
    
    // Step 1: Unlock RWDT write protection
    *wdt_protect = WDT_WKEY;
    
    // Step 2: Read current config and disable RWDT
    uint32_t current_config = *wdt_config0;
    // Clear enable bit (bit 31) and flashboot bit (bit 12)
    current_config &= ~((1U << 31) | (1U << 12));
    *wdt_config0 = current_config;
    
    // Step 3: Feed the watchdog once to reset counter
    *wdt_feed = 1;
    
    // Step 4: Re-enable write protection
    *wdt_protect = 0;

    // Call Swift main function
    swift_main();

    while (1) {
        // Just burn CPU cycles
        for (volatile int i = 0; i < 1000000; i++) {
            // Do nothing
        }
    }

}

#include <stddef.h>
#include <stdint.h>

// Stub implementation of arc4random_buf for embedded systems
// This is used internally by Swift's hashing mechanism
void arc4random_buf(void *buf, size_t nbytes) {
    // Simple pseudo-random implementation for embedded use
    // Not cryptographically secure, but sufficient for hashing
    uint8_t *bytes = (uint8_t *)buf;
    static uint32_t seed = 0x12345678;

    for (size_t i = 0; i < nbytes; i++) {
        // Simple linear congruential generator
        seed = seed * 1103515245 + 12345;
        bytes[i] = (uint8_t)(seed >> 16);
    }
}

// Additional stub for arc4random if needed
uint32_t arc4random(void) {
    static uint32_t seed = 0x87654321;
    seed = seed * 1103515245 + 12345;
    return seed;
}
