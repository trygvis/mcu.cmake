set(MCU_BASEDIR "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "The mcu.cmake installation path" FORCE)
message("MCU_BASEDIR=${MCU_BASEDIR}")

if (NOT MCU_CHIP)
    message(FATAL_ERROR "Missing required argument MCU_CHIP.")
elseif (MCU_CHIP MATCHES "nrf5.*")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/nrf5x.cmake")

    include(${CMAKE_CURRENT_LIST_DIR}/nrf5x/nrfjprog.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/nrf5x/utils.cmake)
elseif (MCU_CHIP MATCHES D2000)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/intel-quark-d2000.toolchain.cmake")
elseif (MCU_CHIP MATCHES "stm32f103.*")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/stm32f103/toolchain.cmake")
    include(${CMAKE_CURRENT_LIST_DIR}/stm32f103/index.cmake)
else ()
    message(FATAL_ERROR "Unsupported MCU_CHIP setting: ${MCU_CHIP}")
endif ()

include(${CMAKE_CURRENT_LIST_DIR}/mcu_include_directories_from_sources.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/binutils.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/elfstats.cmake)

set(MCU_ELFSTATS_MODE AUTO)
set(MCU_BINUTILS_MODE AUTO)
set(MCU_LTO_MODE AUTO)

# Required on Windows
set(CMAKE_SYSTEM_NAME Generic)
