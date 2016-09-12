if (MCU_NRFJPROG OR NRFJPROG STREQUAL "NRFJPROG-NOTFOUND")
    return()
endif ()

find_program(MCU_NRFJPROG nrfjprog VERBOSE)
set(MCU_NRFJPROG ${MCU_NRFJPROG} CACHE FILE "Path to nrfjprog")

if (MCU_NRFJPROG)
    message("MCU: found nrfjprog: ${MCU_NRFJPROG}")
else ()
    message("MCU: nrfjprog not found")
endif ()

function(_nrf51_try_add_nrfjprog_targets T)
    if (MCU_NRFJPROG)
        _nrf51_add_nrfjprog_targets(${T})
    endif ()
endfunction()

function(_nrf51_add_nrfjprog_targets T)
    if (${MCU_CHIP} MATCHES "nrf51.*")
        set(chip_series nrf51)
    elseif (${MCU_CHIP} MATCHES "nrf52.*")
        set(chip_series nrf52)
    else ()
        return()
    endif ()

    add_custom_target(${T}-flash
        COMMAND ${MCU_NRFJPROG} -f ${chip_series} --sectorerase --program $<TARGET_FILE:${T}>.hex
        COMMAND ${MCU_NRFJPROG} -f ${chip_series} --reset
        DEPENDS $<TARGET_FILE:${T}>.hex
        COMMENT "Flashing: ${T}")

    #[[
    get_target_property(MCU_SOFTDEVICE ${T} MCU_SOFTDEVICE)
    if (MCU_SOFTDEVICE)
        add_custom_target(${T}-flash-softdevice
            COMMAND ${MCU_NRFJPROG} -f ${chip_series} --chiperase --program
            COMMAND ${MCU_NRFJPROG} -f ${chip_series} --reset
            DEPENDS $<TARGET_FILE:${T}>.hex
            COMMENT "Flashing: ${T}")
    endif ()
    ]]
endfunction()
