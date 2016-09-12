set(MCU_NRF51_LOADED TRUE CACHE BOOL INTERNAL)

include(${CMAKE_CURRENT_LIST_DIR}/nrf51/utils.cmake)

mcu_nrf51_detect_sdk()

find_program(ARM_CC arm-none-eabi-gcc ${TOOLCHAIN_DIR}/bin)
find_program(ARM_CXX arm-none-eabi-g++ ${TOOLCHAIN_DIR}/bin)
find_program(ARM_OBJCOPY arm-none-eabi-objcopy ${TOOLCHAIN_DIR}/bin)
find_program(ARM_SIZE_TOOL arm-none-eabi-size ${TOOLCHAIN_DIR}/bin)

set(_CMAKE_TOOLCHAIN_PREFIX arm-none-eabi-)
include(CMakeFindBinUtils)

#message("ARM_CC=${ARM_CC}")
#message("ARM_CXX=${ARM_CXX}")
#message("ARM_OBJCOPY=${ARM_OBJCOPY}")
#message("ARM_SIZE_TOOL=${ARM_SIZE_TOOL}")

# Old style, before 3.6
#include(CMakeForceCompiler)
#CMAKE_FORCE_C_COMPILER(${ARM_CC} GNU)
#CMAKE_FORCE_CXX_COMPILER(${ARM_CXX} GNU)

# New style, 3.6+
set(CMAKE_C_COMPILER ${ARM_CC} CACHE FILE "")
set(CMAKE_CXX_COMPILER ${ARM_CXX} CACHE FILE "")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
