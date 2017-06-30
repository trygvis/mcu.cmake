#include <cstdint>
#include <cstddef>
#include <cstdio>
#include "mcu/init-impl.h"

// This is required to keep the compiler from replacing parts of a function with calls to library functions like memcpy.
# define disable_replace_with_library_calls \
    __attribute__ ((__optimize__ ("-fno-tree-loop-distribute-patterns")))

/**
 * Symbols that are defined by the linker
 */
extern "C"
{
extern uint8_t _copy_data_load, _copy_data_store, _copy_data_store_end;
extern uint8_t _bss_start, _bss_end;

typedef void(*constructor_t)();
extern constructor_t _init_array_start[], _init_array_end[];
}

extern "C"
__attribute__((used))
void __cxa_pure_virtual()
{
    halt();
}

extern "C"
__attribute__((used))
void __aeabi_unwind_cpp_pr0()
{
}

extern "C"
__attribute__((used))
void __aeabi_unwind_cpp_pr1()
{
}

extern "C"
__attribute__((used))
void __aeabi_unwind_cpp_pr2()
{
}

namespace std {
void __throw_bad_function_call() {
    halt();
}
}

extern "C"
__attribute__((used))
disable_replace_with_library_calls
void *memset(void *dst, int i, size_t n)
{
    auto *d = static_cast<uint8_t *>(dst);
    auto c = (uint8_t) i;
    while (n > 0) {
        *d = c;
        d++;
        n--;
    }
    return dst;
}

extern "C"
__attribute__((used))
disable_replace_with_library_calls
void *memcpy(void *destination, void *source, size_t num)
{
    auto *d = (uint8_t *) destination;
    auto *s = (uint8_t *) source;
    for (size_t i = 0; i < num; i++) {
        d[i] = s[i];
    }
    return destination;
}

extern "C"
__attribute__((used))
disable_replace_with_library_calls
int memcmp(const void *a_ptr, const void *b_ptr, size_t num) {
    int result;

    auto a = static_cast<const unsigned char *>(a_ptr);
    auto b = static_cast<const unsigned char *>(b_ptr);
    result = 0;
    while ((num > 0) && (result == 0)) {
        result = *a - *b;
        num--;
        a++;
        b++;
    }
    return result;
}

extern "C"
__attribute__((used))
disable_replace_with_library_calls
size_t strlen(const char *s)
{
    size_t size = 0;

    while (*s++ != 0) {
        size++;
    }

    return size;
}

extern "C"
__attribute__((used))
void __libc_init_array()
{
    // Initialize c++ constructors
    for (constructor_t *fn = _init_array_start; fn < _init_array_end; fn++) {
        (*fn)();
    }
}

extern "C"
__attribute__((used))
void init_high()
{
    // Copy data from flash to ram
    size_t num = &_copy_data_store_end - &_copy_data_store;
    memcpy(&_copy_data_store, &_copy_data_load, num);

    // Clear the BSS segment
    memset(&_bss_start, 0, &_bss_end - &_bss_start);

    __libc_init_array();

    main();
}

extern "C"
__attribute__((weak, used))
void HardFault_Handler_C()
{
    halt();
}
