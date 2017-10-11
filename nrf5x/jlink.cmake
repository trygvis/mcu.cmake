function(_nrf5_jlink_program VARIABLE EXE_UNIX EXE_WIN32)
    if (WIN32)
        set(EXE ${EXE_WIN32})
    else()
        set(EXE ${EXE_UNIX})
    endif ()

    find_program(${VARIABLE} ${EXE} VERBOSE)

    if (NOT ${${VARIABLE}} STREQUAL "${VARIABLE}-NOTFOUND")
        message(STATUS "MCU: found ${EXE}: ${${VARIABLE}}")
    else ()
        message(STATUS "MCU: ${EXE} not found")
    endif ()
endfunction()

_nrf5_jlink_program(MCU_JLINK JLinkExe JLink)
_nrf5_jlink_program(MCU_JLINKGDBSERVER JLinkGDBServer JLinkGDBServer)

function(_nrf5_try_add_jlink_targets T)
    if (MCU_JLINK)
        _nrf5_add_jlink_targets(${T})
    endif ()
endfunction()

function(_nrf5_add_jlink_targets T)
    get_target_property(MCU_NRF5X_CHIP_SERIES ${T} MCU_NRF5X_CHIP_SERIES)

    message(STATUS "Creating target ${T}-jlink")
    add_custom_target(${T}-jlink
        COMMAND ${MCU_JLINK} -if SWD -speed 4000 -device "${MCU_NRF5X_CHIP_SERIES}"
        COMMENT "Starting JLink")

    message(STATUS "Creating target ${T}-jlinkgdbserver")
    add_custom_target(${T}-jlinkgdbserver
        COMMAND ${MCU_JLINKGDBSERVER} -if SWD -speed 4000 -device "${MCU_NRF5X_CHIP_SERIES}"
        COMMENT "Starting JLinkGDBServer")
endfunction()
