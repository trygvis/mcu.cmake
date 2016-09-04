function(mcu_add_executable TARGET)
    target_sources(${TARGET} PUBLIC
            "${MCU_NRF51_SDK_PATH}/components/toolchain/system_nrf51.c"
            "${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/gcc_startup_nrf51.S")
    target_include_directories(${TARGET} PUBLIC
            ${MCU_NRF51_SDK_PATH}/components/device
            ${MCU_NRF51_SDK_PATH}/components/toolchain
            ${MCU_NRF51_SDK_PATH}/components/toolchain/gcc)

    target_compile_definitions(${TARGET} PUBLIC NRF51)

    target_compile_options(${TARGET} PUBLIC "-mcpu=cortex-m0" "-mthumb" "-mabi=aapcs" "--std=gnu99" "-Wall" "-mfloat-abi=soft")

    target_include_directories(${TARGET} PUBLIC
            ${MCU_NRF51_SDK_PATH}/components/toolchain/cmsis/include)

    target_link_libraries(${TARGET} PUBLIC "-L${MCU_NRF51_SDK_PATH}/components/toolchain/gcc")
    target_link_libraries(${TARGET} PUBLIC "-T${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/nrf51_xxac.ld")
endfunction()

function(mcu_nrf51_add_softdevice TARGET SOFTDEVICE)

    if (SOFTDEVICE STREQUAL s130)
        string(TOUPPER D_SOFTDEVICE ${SOFTDEVICE})
        target_include_directories(${TARGET} PUBLIC ${MCU_NRF51_SDK_PATH}/components/softdevice/${SOFTDEVICE}/headers)
    else ()
        message(FATAL_ERROR "Unsupported softdevice: ${SOFTDEVICE}")
    endif ()

    target_compile_definitions(${TARGET} PUBLIC ${D_SOFTDEVICE})
    target_compile_definitions(${TARGET} PUBLIC SOFTDEVICE_PRESENT)
endfunction()

# Toolchain files are executed many times when detecting c/c++ compilers, but it will only read the cache on the first
# exeuction so the paths has to be saved to the environment as it is shared between executions.
function(mcu_nrf51_detect_sdk)
    if (MCU_NRF51_SDK_PATH)
        # message("NRF51 SDK already found: ${MCU_NRF51_SDK_PATH}")
        return()
    endif ()

    set(MCU_NRF51_SDK_PATH "$ENV{_MCU_NRF51_SDK_PATH}")

    if (MCU_NRF51_SDK_PATH)
        # message("NRF51 SDK already found from ENV: ${MCU_NRF51_SDK_PATH}")
        return()
    endif ()

    message("Detecting NRF51 SDK")

    if (NOT MCU_NRF51_SDK)
        message(FATAL_ERROR "MCU_NRF51_SDK parameter cannot be empty.")
    endif ()

    # message("MCU_NRF51_SDK=${MCU_NRF51_SDK}")
    get_filename_component(MCU_NRF51_SDK_PATH "${MCU_NRF51_SDK}" ABSOLUTE)
    # message("MCU_NRF51_SDK_PATH=${MCU_NRF51_SDK_PATH}")

    set(ENV{_MCU_NRF51_SDK_PATH} "${MCU_NRF51_SDK_PATH}")

    set(NOTES ${MCU_NRF51_SDK_PATH}/documentation/release_notes.txt)

    if (NOT EXISTS ${NOTES})
        message(FATAL_ERROR "Could not find 'documentation/release_notes.txt' under NRF SDK path: ${NOTES}")
    endif ()

    file(READ ${NOTES} NOTES LIMIT 100)

    # message("NOTES: ${NOTES}")
    message("MCU_NRF51_SDK_VERSION: ${MCU_NRF51_VERSION}")

    # string(SUBSTRING <string> <begin> <length> <output variable>)
    set(MCU_NRF51_SDK_PATH "${MCU_NRF51_SDK_PATH}" CACHE PATH "" FORCE)
endfunction()
