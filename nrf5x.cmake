# Toolchain files are executed many times when detecting c/c++ compilers, but it will only read the cache on the first
# exeuction so the paths has to be saved to the environment as it is shared between executions.
function(mcu_nrf5_detect_sdk)
    if (MCU_NRF5X_SDK_PATH)
        # message("MCU: NRF5x SDK already found: ${MCU_NRF5X_SDK_PATH}")
        return()
    endif ()

    set(MCU_NRF5X_SDK_PATH "$ENV{_MCU_NRF5X_SDK_PATH}")

    if (MCU_NRF5X_SDK_PATH)
        # message("MCU: NRF5x SDK already found from ENV: ${MCU_NRF5X_SDK_PATH}")
        return()
    endif ()

    message("MCU: Detecting NRF5x SDK")

    if (NOT MCU_NRF5X_SDK)
        set(MCU_NRF5X_SDK "" CACHE PATH "" FORCE)
        message(FATAL_ERROR "MCU: MCU_NRF5X_SDK parameter cannot be empty.")
        return()
    endif ()

    get_filename_component(MCU_NRF5X_SDK_PATH "${MCU_NRF5X_SDK}" ABSOLUTE)

    set(ENV{_MCU_NRF5X_SDK_PATH} "${MCU_NRF5X_SDK_PATH}")

    set(NOTES ${MCU_NRF5X_SDK_PATH}/documentation/release_notes.txt)

    if (NOT EXISTS ${NOTES})
        message(FATAL_ERROR "MCU: Could not find 'documentation/release_notes.txt' under NRF SDK path: ${NOTES}")
    endif ()

    file(STRINGS ${NOTES} NOTES_LIST)
    list(GET NOTES_LIST 0 NOTES_0)

    if (NOTES_0 MATCHES "nRF5.? SDK [^0-9]*([\\.0-9]*)")
        set(MCU_NRF5X_SDK_VERSION "${CMAKE_MATCH_1}")
    else ()
        message(FATAL_ERROR "MCU: Could not detect SDK version.")
        return()
    endif ()

    message("MCU: nRF5x SDK Path: ${MCU_NRF5X_SDK_PATH} (Version: ${MCU_NRF5X_SDK_VERSION})")

    set(MCU_NRF5X_SDK_VERSION "${MCU_NRF5X_SDK_VERSION}" CACHE STRING "MCU: nRF5x SDK version" FORCE)
    set(MCU_NRF5X_SDK_PATH "${MCU_NRF5X_SDK_PATH}" CACHE PATH "MCU: nRF5x SDK path" FORCE)
endfunction()

set(MCU_NRF5X_LOADED TRUE CACHE BOOL INTERNAL)

mcu_nrf5_detect_sdk()

find_program(ARM_CC arm-none-eabi-gcc ${TOOLCHAIN_DIR}/bin)
find_program(ARM_CXX arm-none-eabi-g++ ${TOOLCHAIN_DIR}/bin)
find_program(ARM_OBJCOPY arm-none-eabi-objcopy ${TOOLCHAIN_DIR}/bin)
find_program(ARM_SIZE_TOOL arm-none-eabi-size ${TOOLCHAIN_DIR}/bin)
find_program(ARM_NM arm-none-eabi-nm ${TOOLCHAIN_DIR}/bin)

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
