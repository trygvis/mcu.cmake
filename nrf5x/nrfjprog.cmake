if (NOT MCU_NRFJPROG AND NOT NRFJPROG STREQUAL "NRFJPROG-NOTFOUND")
    find_program(MCU_NRFJPROG nrfjprog VERBOSE DOC "Path to nrfjprog")

    if (MCU_NRFJPROG)
        message("MCU: found nrfjprog: ${MCU_NRFJPROG}")
    else ()
        message("MCU: nrfjprog not found")
    endif ()
endif ()

function(_nrf5_try_add_nrfjprog_targets T)
    if (MCU_NRFJPROG)
        _nrf5_add_nrfjprog_targets(${T})
    endif ()
endfunction()

function(_nrf5_add_nrfjprog_targets T)
    get_target_property(MCU_SOFTDEVICE ${T} MCU_SOFTDEVICE)
    get_target_property(MCU_NRF5X_CHIP_SERIES ${T} MCU_NRF5X_CHIP_SERIES)

    message(STATUS "Creating target ${T}-flash")
    add_custom_target(${T}-flash
            COMMAND ${MCU_NRFJPROG} -f ${MCU_NRF5X_CHIP_SERIES} --sectorerase --program $<TARGET_FILE:${T}>.hex
            COMMAND ${MCU_NRFJPROG} -f ${MCU_NRF5X_CHIP_SERIES} --reset
            DEPENDS ${T} $<TARGET_FILE:${T}>.hex
            COMMENT "Flashing: ${T}")

    get_target_property(MCU_SOFTDEVICE ${T} MCU_SOFTDEVICE)
    get_target_property(MCU_SOFTDEVICE_HEX ${T} MCU_SOFTDEVICE_HEX)
    if (MCU_SOFTDEVICE AND MCU_SOFTDEVICE_HEX)
        message(STATUS "Creating target ${T}-flash-softdevice")
        add_custom_target(${T}-flash-softdevice
                COMMAND ${MCU_NRFJPROG} -f ${MCU_NRF5X_CHIP_SERIES} --chiperase --program ${MCU_SOFTDEVICE_HEX}
                COMMAND ${MCU_NRFJPROG} -f ${MCU_NRF5X_CHIP_SERIES} --reset
                DEPENDS ${T} $<TARGET_FILE:${T}>.hex
                COMMENT "Flashing soft device: ${MCU_SOFTDEVICE_HEX}")
    endif ()
endfunction()
