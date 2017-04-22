#include <cstdint>
#include <cstddef>
#include <cstdio>
#include "mcu/init-impl.h"

// This is required to keep the compiler from replacing parts of a function with calls to library functions like memcpy.
# define disable_replace_with_library_calls \
    __attribute__ ((__optimize__ ("-fno-tree-loop-distribute-patterns")))

using namespace mcu;

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
void init_high()
{
    // Copy data from flash to ram
    size_t num = &_copy_data_store_end - &_copy_data_store;
    memcpy(&_copy_data_store, &_copy_data_load, num);

    // Clear the BSS segment
    memset(&_bss_start, 0, &_bss_end - &_bss_start);

    // Initialize c++ constructors
    for (constructor_t *fn = _init_array_start; fn < _init_array_end; fn++) {
        (*fn)();
    }

    main();
}

extern "C"
__attribute__((weak, used))
void HardFault_Handler_C()
{
    halt();
}

__attribute__((section(".isr_vectors"), used))
uint32_t isr_vectors[74] = {
        (uint32_t) _Reset_Handler,
        (uint32_t) NMI_Handler,
        (uint32_t) HardFault_Handler,
        (uint32_t) MemManage_Handler,
        (uint32_t) BusFault_Handler,
        (uint32_t) UsageFault_Handler,
        0,
        0,
        0,
        0,
        (uint32_t) SVC_Handler,
        (uint32_t) DebugMon_Handler,
        0,
        (uint32_t) PendSV_Handler,
        (uint32_t) SysTick_Handler,
        (uint32_t) WWDG_IRQHandler,
        (uint32_t) PVD_IRQHandler,
        (uint32_t) TAMPER_IRQHandler,
        (uint32_t) RTC_IRQHandler,
        (uint32_t) FLASH_IRQHandler,
        (uint32_t) RCC_IRQHandler,
        (uint32_t) EXTI0_IRQHandler,
        (uint32_t) EXTI1_IRQHandler,
        (uint32_t) EXTI2_IRQHandler,
        (uint32_t) EXTI3_IRQHandler,
        (uint32_t) EXTI4_IRQHandler,
        (uint32_t) DMA1_Channel1_IRQHandler,
        (uint32_t) DMA1_Channel2_IRQHandler,
        (uint32_t) DMA1_Channel3_IRQHandler,
        (uint32_t) DMA1_Channel4_IRQHandler,
        (uint32_t) DMA1_Channel5_IRQHandler,
        (uint32_t) DMA1_Channel6_IRQHandler,
        (uint32_t) DMA1_Channel7_IRQHandler,
        (uint32_t) ADC1_2_IRQHandler,
        (uint32_t) USB_HP_CAN1_TX_IRQHandler,
        (uint32_t) USB_LP_CAN1_RX0_IRQHandler,
        (uint32_t) CAN1_RX1_IRQHandler,
        (uint32_t) CAN1_SCE_IRQHandler,
        (uint32_t) EXTI9_5_IRQHandler,
        (uint32_t) TIM1_BRK_IRQHandler,
        (uint32_t) TIM1_UP_IRQHandler,
        (uint32_t) TIM1_TRG_COM_IRQHandler,
        (uint32_t) TIM1_CC_IRQHandler,
        (uint32_t) TIM2_IRQHandler,
        (uint32_t) TIM3_IRQHandler,
        (uint32_t) TIM4_IRQHandler,
        (uint32_t) I2C1_EV_IRQHandler,
        (uint32_t) I2C1_ER_IRQHandler,
        (uint32_t) I2C2_EV_IRQHandler,
        (uint32_t) I2C2_ER_IRQHandler,
        (uint32_t) SPI1_IRQHandler,
        (uint32_t) SPI2_IRQHandler,
        (uint32_t) USART1_IRQHandler,
        (uint32_t) USART2_IRQHandler,
        (uint32_t) USART3_IRQHandler,
        (uint32_t) EXTI15_10_IRQHandler,
        (uint32_t) RTCAlarm_IRQHandler,
        (uint32_t) USBWakeUp_IRQHandler,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
};
