find_program(MCU_ARM_CC arm-none-eabi-gcc ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_CXX arm-none-eabi-g++ ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_OBJCOPY arm-none-eabi-objcopy ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_OBJDUMP arm-none-eabi-objdump ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_READELF arm-none-eabi-readelf ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_SIZE arm-none-eabi-size ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_NM arm-none-eabi-nm ${MCU_TOOLCHAIN_DIR}/bin)

#message("MCU_ARM_CC      = ${MCU_ARM_CC}")
#message("MCU_ARM_CXX     = ${MCU_ARM_CXX}")
#message("MCU_ARM_OBJCOPY = ${MCU_ARM_OBJCOPY}")
#message("MCU_ARM_SIZE    = ${MCU_ARM_SIZE}")

set(_CMAKE_TOOLCHAIN_PREFIX arm-none-eabi-)
include(CMakeFindBinUtils)

if (NOT MCU_ARM_CC OR NOT MCU_ARM_CXX OR NOT MCU_ARM_OBJCOPY OR NOT MCU_ARM_SIZE)
    message(FATAL_ERROR "Could not find required compiler tools.")
endif()

set(CMAKE_C_COMPILER ${MCU_ARM_CC} CACHE FILE "")
set(CMAKE_CXX_COMPILER ${MCU_ARM_CXX} CACHE FILE "")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 14)
