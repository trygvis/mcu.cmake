#ifndef INIT_IMPL_H
#define INIT_IMPL_H

#ifndef MCUCMAKE_USING_STM32CUBE
#define MCUCMAKE_USING_STM32CUBE 0
#endif

#if MCUCMAKE_USING_STM32CUBE
#include <stm32f1xx.h>
#else
#include <stm32f10x.h>
#endif

#include "mcu/init.h"

#endif
