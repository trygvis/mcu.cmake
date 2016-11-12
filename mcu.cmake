if (NOT MCU_CHIP)
    message(FATAL_ERROR "Missing required argument CHIP.")
elseif (MCU_CHIP MATCHES "nrf5.*")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/nrf5x.cmake")

    include(${CMAKE_CURRENT_LIST_DIR}/nrf5x/nrfjprog.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/nrf5x/utils.cmake)
elseif (MCU_CHIP MATCHES D2000)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/intel-quark-d2000.toolchain.cmake")
else ()
    message(FATAL_ERROR "Unsupported MCU_CHIP setting: ${MCU_CHIP}")
endif ()

include(${CMAKE_CURRENT_LIST_DIR}/mcu_include_directories_from_sources.cmake)

# Required on Windows
set(CMAKE_SYSTEM_NAME Generic)
