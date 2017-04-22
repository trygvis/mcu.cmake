cmake_minimum_required(VERSION 3.6)

if (NOT MCU_CHIP)
    set(MCU_CHIP stm32f103xb)
endif ()

include(mcu.cmake/mcu.cmake)

# mcu.cmake has to be included before project() is called
project(my-project C CXX ASM)

# From here on the setup is as normal as possible
set(CMAKE_CXX_STANDARD 14)
