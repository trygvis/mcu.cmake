#message("MCU: nrf5x.cmake:     MCU_NRF5X_SDK=${MCU_NRF5X_SDK}, MCU_TOOLCHAIN_DIR=${MCU_TOOLCHAIN_DIR}")
#message("MCU: nrf5x.cmake: env MCU_NRF5X_SDK=$ENV{_MCU_NRF5X_SDK_PATH}, MCU_TOOLCHAIN_DIR=$ENV{_MCU_TOOLCHAIN_DIR}")

function (_mcu_find_toolchain)
#    message("MCU: _mcu_find_toolchain: MCU_TOOLCHAIN_DIR=${MCU_TOOLCHAIN_DIR}, env=$ENV{_MCU_TOOLCHAIN_DIR}")

    if ("$ENV{_MCU_TOOLCHAIN_DIR}" STREQUAL "")
#        message("MCU: pushing MCU_TOOLCHAIN_DIR=${MCU_TOOLCHAIN_DIR} to env")
        set(ENV{_MCU_TOOLCHAIN_DIR} "${MCU_TOOLCHAIN_DIR}")
    endif ()

    if (MCU_TOOLCHAIN_DIR)
#        message("MCU: using existing MCU_TOOLCHAIN_DIR: ${MCU_TOOLCHAIN_DIR}")
        return()
    endif ()

    set(MCU_TOOLCHAIN_DIR "$ENV{_MCU_TOOLCHAIN_DIR}" PARENT_SCOPE)

    if (MCU_TOOLCHAIN_DIR)
#        message("MCU: Using MCU_TOOLCHAIN_DIR from ENV: ${MCU_TOOLCHAIN_DIR}")
        return()
    endif ()
endfunction()

# Toolchain files are executed many times when detecting c/c++ compilers, but it will only read the cache on the first
# exeuction so the paths has to be saved to the environment as it is shared between executions.
function(mcu_nrf5_detect_sdk)
    if (MCU_NRF5X_SDK_PATH)
#        message("MCU: NRF5x SDK already found: ${MCU_NRF5X_SDK_PATH}")
        return()
    endif ()

    set(MCU_NRF5X_SDK_PATH "$ENV{_MCU_NRF5X_SDK_PATH}")

    if (MCU_NRF5X_SDK_PATH)
#        message("MCU: NRF5x SDK already found from ENV: ${MCU_NRF5X_SDK_PATH}")
        return()
    endif ()

    message("MCU: Detecting NRF5x SDK in: " ${MCU_NRF5X_SDK})

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

    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)$" junk ${MCU_NRF5X_SDK_VERSION})
    set(MCU_NRF5X_SDK_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(MCU_NRF5X_SDK_VERSION_MINOR ${CMAKE_MATCH_2})
    set(MCU_NRF5X_SDK_VERSION_PATCH ${CMAKE_MATCH_3})
    message("MCU: major=${MCU_NRF5X_SDK_VERSION_MAJOR} minor=${MCU_NRF5X_SDK_VERSION_MINOR} patch=${MCU_NRF5X_SDK_VERSION_PATCH}")

    set(MCU_NRF5X_SDK_VERSION "${MCU_NRF5X_SDK_VERSION}" CACHE STRING "MCU: nRF5x SDK version" FORCE)
    set(MCU_NRF5X_SDK_VERSION_MAJOR "${MCU_NRF5X_SDK_VERSION_MAJOR}" CACHE STRING "MCU: nRF5x SDK version, major" FORCE)
    set(MCU_NRF5X_SDK_VERSION_MINOR "${MCU_NRF5X_SDK_VERSION_MINOR}" CACHE STRING "MCU: nRF5x SDK version, minor" FORCE)
    set(MCU_NRF5X_SDK_VERSION_PATCH "${MCU_NRF5X_SDK_VERSION_PATCH}" CACHE STRING "MCU: nRF5x SDK version, patch" FORCE)
    set(MCU_NRF5X_SDK_PATH "${MCU_NRF5X_SDK_PATH}" CACHE PATH "MCU: nRF5x SDK path" FORCE)
endfunction()

#if(MCU_NRF5X_LOADED)
#    message("MCU: nrf5x already loaded")
#    return()
#endif()
#
#set(MCU_NRF5X_LOADED TRUE CACHE BOOL INTERNAL)

mcu_nrf5_detect_sdk()

_mcu_find_toolchain()

find_program(MCU_ARM_CC arm-none-eabi-gcc ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_CXX arm-none-eabi-g++ ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_OBJCOPY arm-none-eabi-objcopy ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_SIZE_TOOL arm-none-eabi-size ${MCU_TOOLCHAIN_DIR}/bin)
find_program(MCU_ARM_NM arm-none-eabi-nm ${MCU_TOOLCHAIN_DIR}/bin)

set(_CMAKE_TOOLCHAIN_PREFIX arm-none-eabi-)
include(CMakeFindBinUtils)

#message("MCU_ARM_CC        = ${MCU_ARM_CC}")
#message("MCU_ARM_CXX       = ${MCU_ARM_CXX}")
#message("MCU_ARM_OBJCOPY   = ${MCU_ARM_OBJCOPY}")
#message("MCU_ARM_SIZE_TOOL = ${MCU_ARM_SIZE_TOOL}")

if (NOT MCU_ARM_CC OR NOT MCU_ARM_CXX OR NOT MCU_ARM_OBJCOPY OR NOT MCU_ARM_SIZE_TOOL)
    message(FATAL_ERROR "Could not find required compiler tools.")
endif()

# Old style, before 3.6
#include(CMakeForceCompiler)
#CMAKE_FORCE_C_COMPILER(${ARM_CC} GNU)
#CMAKE_FORCE_CXX_COMPILER(${ARM_CXX} GNU)

# New style, 3.6+
set(CMAKE_C_COMPILER ${MCU_ARM_CC} CACHE FILE "")
set(CMAKE_CXX_COMPILER ${MCU_ARM_CXX} CACHE FILE "")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# The ARM compilers today support this.
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 14)
