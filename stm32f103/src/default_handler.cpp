#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <stm32f10x.h>
#include <core_cm3.h>

#include "mcu/init.h"

__attribute__((used))
struct {
    uint32_t CFSR;
    uint32_t HFSR;
    uint32_t DFSR;
    uint32_t AFSR;
//    uint32_t MMAR;
    uint32_t BFAR;
} Default_Handler_Info;

#define dbg_printf printf

extern "C"
__attribute__((used))
void Default_Handler()
{
    Default_Handler_Info = {
        CFSR: SCB->CFSR,
        HFSR: SCB->HFSR,
        DFSR: SCB->DFSR,
        AFSR: SCB->AFSR,
        BFAR: SCB->BFAR,
    };

    dbg_printf("Default handler:\n");

    dbg_printf("HFSR: 0x%08lx\n", Default_Handler_Info.HFSR);
    if (Default_Handler_Info.HFSR & SCB_HFSR_DEBUGEVT) {
        dbg_printf("      HFSR.DEBUGEVT\n");
    }
    if (Default_Handler_Info.HFSR & SCB_HFSR_FORCED) {
        dbg_printf("      HFSR.FORCED\n");
    }
    if (Default_Handler_Info.HFSR & SCB_HFSR_VECTTBL) {
        dbg_printf("      HFSR.VECTTBL\n");
    }

    dbg_printf("CFSR: 0x%08lx\n", Default_Handler_Info.CFSR);
    if (Default_Handler_Info.CFSR & SCB_CFSR_DIVBYZERO) {
        dbg_printf("      UFSR.DIVBYZERO\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_UNALIGNED) {
        dbg_printf("      UFSR.UNALIGED\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_NOCP) {
        dbg_printf("      UFSR.NOCP\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_INVPC) {
        dbg_printf("      UFSR.INVPC\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_INVSTATE) {
        dbg_printf("      UFSR.INVSTATE\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_UNDEFINSTR) {
        dbg_printf("      UFSR.UNDEFINSTR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_BFARVALID) {
        dbg_printf("      BFSR.BFARVALID\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_STKERR) {
        dbg_printf("      BFSR.STKERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_UNSTKERR) {
        dbg_printf("      BFSR.UNSTKERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_IMPRECISERR) {
        dbg_printf("      BFSR.IMPRECISERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_PRECISERR) {
        dbg_printf("      BFSR.PRECISERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_IBUSERR) {
        dbg_printf("      BFSR.IBUSERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_MMARVALID) {
        dbg_printf("      MMFSR.MMARVALID\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_MSTKERR) {
        dbg_printf("      MMFSR.MSTKERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_MUNSTKERR) {
        dbg_printf("      MMFSR.MUNSTKERR\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_DACCVIOL) {
        dbg_printf("      MMFSR.DACCVIOL\n");
    }
    if (Default_Handler_Info.CFSR & SCB_CFSR_IACCVIOL) {
        dbg_printf("      MMFSR.IACCVIOL\n");
    }
    dbg_printf("DFSR: 0x%08lx\n", Default_Handler_Info.DFSR);
    dbg_printf("AFSR: 0x%08lx\n", Default_Handler_Info.AFSR);

    if (Default_Handler_Info.CFSR & SCB_CFSR_BFARVALID) {
        dbg_printf("BFAR: 0x%08lx\n", Default_Handler_Info.BFAR);
    } else {
        dbg_printf("BFAR: <invalid>\n");
    }

    dbg_printf("NVIC:\n");
    for (size_t i = 0; i < sizeof(NVIC->IABR) / sizeof(NVIC->IABR[0]); i++) {
        dbg_printf("  IABR[%d]: 0x%08lx\n", i, NVIC->IABR[i]);
    }

    halt();
}

void _Reset_Handler() __attribute__ ((weak, alias("Default_Handler")));

void NMI_Handler() __attribute__ ((weak, alias("Default_Handler")));

void HardFault_Handler() __attribute__ ((weak, alias("Default_Handler")));

void MemManage_Handler() __attribute__ ((weak, alias("Default_Handler")));

void BusFault_Handler() __attribute__ ((weak, alias("Default_Handler")));

void UsageFault_Handler() __attribute__ ((weak, alias("Default_Handler")));

void SVC_Handler() __attribute__ ((weak, alias("Default_Handler")));

void DebugMon_Handler() __attribute__ ((weak, alias("Default_Handler")));

void PendSV_Handler() __attribute__ ((weak, alias("Default_Handler")));

void SysTick_Handler() __attribute__ ((weak, alias("Default_Handler")));

void WWDG_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void PVD_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TAMPER_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void RTC_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void FLASH_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void RCC_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI0_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI1_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI3_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI4_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel1_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel3_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel4_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel5_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel6_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void DMA1_Channel7_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void ADC1_2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USB_HP_CAN1_TX_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USB_LP_CAN1_RX0_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void CAN1_RX1_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void CAN1_SCE_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI9_5_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM1_BRK_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM1_UP_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM1_TRG_COM_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM1_CC_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM3_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void TIM4_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void I2C1_EV_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void I2C1_ER_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void I2C2_EV_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void I2C2_ER_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void SPI1_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void SPI2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USART1_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USART2_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USART3_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void EXTI15_10_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void RTCAlarm_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));

void USBWakeUp_IRQHandler() __attribute__ ((weak, alias("Default_Handler")));
