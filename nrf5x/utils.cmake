include(${CMAKE_CURRENT_LIST_DIR}/nrfjprog.cmake)

function(_nrf5_startup_files T VAR)
    get_target_property(MCU_NRF5X_CHIP_SERIES ${T} MCU_NRF5X_CHIP_SERIES)

    target_sources(${ARGS_TARGET} PUBLIC "${MCU_NRF5X_SDK_PATH}/components/toolchain/system_${MCU_NRF5X_CHIP_SERIES}.c")

    if ("${MCU_NRF5X_SDK_VERSION}" VERSION_LESS 12)
        set(startup "${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/gcc_startup_${MCU_NRF5X_CHIP_SERIES}.s")
    else ()
        set(startup "${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/gcc_startup_${MCU_NRF5X_CHIP_SERIES}.S")
    endif ()

    set(${VAR} ${startup} PARENT_SCOPE)
endfunction()

function(mcu_add_executable)
    # message("mcu_add_executable: ARGN=${ARGN}")

    set(options)
    set(oneValueArgs TARGET SDK_CONFIG SOFTDEVICE LINKER_SCRIPT)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: Missing required argument: TARGET")
    endif ()

    if (ARGS_LINKER_SCRIPT)
        if(NOT IS_ABSOLUTE "${ARGS_LINKER_SCRIPT}")
            set(ARGS_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_LINKER_SCRIPT}")
        endif()
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_LINKER_SCRIPT "${ARGS_LINKER_SCRIPT}")
    endif ()

    if (${MCU_CHIP} MATCHES "nrf51.*")
        set(chip_series nrf51)
    elseif (${MCU_CHIP} MATCHES "nrf52.*")
        set(chip_series nrf52)
    else ()
        message(FATAL_ERROR "MCU: Unsupported chip: ${MCU_CHIP}")
        return()
    endif ()

    if (chip_series)
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_NRF5X_CHIP_SERIES "${chip_series}")
    endif ()

    _nrf5_startup_files(${ARGS_TARGET} STARTUP_FILES)
    target_sources(${ARGS_TARGET} PUBLIC ${STARTUP_FILES})

    target_compile_options(${ARGS_TARGET} PUBLIC -Wall -Werror -g3 -O3)

    target_link_libraries(${ARGS_TARGET} PRIVATE -Wl,-Map=${ARGS_TARGET}.map)

    # -Wall -Werror -O3 -g3
    # "-ffunction-sections"
    # "-fdata-sections"
    # "-fno-strict-aliasing"
    # "-fno-builtin"
    # "--short-enums"

    if (${MCU_CHIP} MATCHES "nrf51.*")
        target_compile_options(${ARGS_TARGET} PUBLIC
            "-mcpu=cortex-m0"
            "-mthumb"
            "-mabi=aapcs"
            "-mfloat-abi=soft")
        target_link_libraries(${ARGS_TARGET} PRIVATE
            "-mcpu=cortex-m0"
            "-mthumb"
            "-mabi=aapcs"
            "-Wl,--gc-sections"
            )
    elseif (${MCU_CHIP} MATCHES "nrf52.*")
        target_compile_options(${ARGS_TARGET} PUBLIC
            "-mcpu=cortex-m4"
            "-mthumb"
            "-mabi=aapcs"
            "-mfloat-abi=hard"
            "-mfpu=fpv4-sp-d16"
            "-ffunction-sections"
            "-fdata-sections"
            "-fno-strict-aliasing"
            "-fno-builtin"
            "--short-enums")
        # -fshort-wchar
        target_compile_features(${ARGS_TARGET} PUBLIC c_static_assert)
        target_link_libraries(${ARGS_TARGET} PRIVATE
            "-mcpu=cortex-m4"
            "-mthumb"
            "-mabi=aapcs"
            "-mfloat-abi=hard"
            "-mfpu=fpv4-sp-d16"
            "-Wl,--gc-sections"
            # "--specs=nano.specs"
            )
        # target_link_libraries(${ARGS_TARGET} PUBLIC c nosys)
    endif ()

    if (ARGS_SDK_CONFIG)
        get_filename_component(SDK_CONFIG ${ARGS_SDK_CONFIG} ABSOLUTE)
        get_filename_component(SDK_CONFIG ${SDK_CONFIG} DIRECTORY)
    endif ()

    set_target_properties(${ARGS_TARGET} PROPERTIES SDK_CONFIG "${SDK_CONFIG}")

    if (ARGS_SOFTDEVICE)
        if ("${MCU_NRF5X_SDK_VERSION_MAJOR}" VERSION_EQUAL 12 AND ARGS_SOFTDEVICE STREQUAL 130)
            set(hex "${MCU_NRF5X_SDK_PATH}/components/softdevice/s130/hex/s130_nrf51_2.0.1_softdevice.hex")
        elseif ("${MCU_NRF5X_SDK_VERSION_MAJOR}" STREQUAL 12 AND ARGS_SOFTDEVICE STREQUAL 132)
            set(hex "${MCU_NRF5X_SDK_PATH}/components/softdevice/s132/hex/s132_nrf52_3.0.0_softdevice.hex")
        else ()
            message(WARNING "Unknown combination of SDK version (${MCU_NRF5X_SDK_VERSION}) and softdevice (${ARGS_SOFTDEVICE}). Some features might be unavailable.")
        endif ()

        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_SOFTDEVICE "${ARGS_SOFTDEVICE}")

        if (hex)
            set_target_properties(${ARGS_TARGET} PROPERTIES MCU_SOFTDEVICE_HEX "${hex}")
        endif ()
    endif ()

    _nrf5_set_from_main_target(${ARGS_TARGET})

    add_custom_command(TARGET ${ARGS_TARGET} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${ARGS_TARGET}> $<TARGET_FILE:${ARGS_TARGET}>.hex)
    add_custom_command(TARGET ${ARGS_TARGET} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${ARGS_TARGET}> $<TARGET_FILE:${ARGS_TARGET}>.bin)
    add_custom_command(TARGET ${ARGS_TARGET} POST_BUILD
        COMMAND ${CMAKE_NM} $<TARGET_FILE:${ARGS_TARGET}> > $<TARGET_FILE:${ARGS_TARGET}>.nm)

    _nrf5_try_add_nrfjprog_targets(${ARGS_TARGET})

endfunction()

function(_nrf5_set_from_main_target T)
    # message("_nrf5_set_from_main_target, T=${T}")

    get_target_property(SDK_CONFIG ${T} SDK_CONFIG)
    get_target_property(MCU_SOFTDEVICE ${T} MCU_SOFTDEVICE)
    get_target_property(MCU_LINKER_SCRIPT ${T} MCU_LINKER_SCRIPT)

    _nrf_chip_values(CHIP_INCLUDES CHIP_DEFINES)
    target_include_directories(${T} PUBLIC ${CHIP_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${CHIP_DEFINES})

    target_include_directories(${T} PUBLIC
        ${MCU_NRF5X_SDK_PATH}/components/device
        ${MCU_NRF5X_SDK_PATH}/components/toolchain
        ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc
        ${MCU_NRF5X_SDK_PATH}/components/toolchain/cmsis/include
        )

    if (SDK_CONFIG)
        # message("_nrf5_set_from_main_target: SDK_CONFIG=${SDK_CONFIG}")
        target_include_directories(${T} PRIVATE ${SDK_CONFIG})
    endif ()

    _nrf_softdevice_includes(${MCU_SOFTDEVICE} SOFTDEVICE_INCLUDES SOFTDEVICE_DEFINES)
    target_include_directories(${T} PUBLIC ${SOFTDEVICE_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${SOFTDEVICE_DEFINES})

    # Linker script

    if (NOT MCU_LINKER_SCRIPT)
        if (SOFTDEVICE)
            message("MCU: ${T}: No linker script set. Either use the LINKER_SCRIPT argument to mcu_add_executable() "
                "or set the MCU_LINKER_SCRIPT target property. The softdevice's configuration defines its memory usage "
                "and is application-specific.")

            set(ld ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/toolchain/armgcc/armgcc_s${SOFTDEVICE}_${MCU_CHIP}.ld)

            if (NOT EXISTS ${ld})
                message("The SDK has a template linker script that can be used as a starting point, but remember to "
                    "adjust the ORIGIN of the RAM area: ${ld}")
                return()
            endif ()

            message(FATAL_ERROR "MCU: Linker script is not configured for ${T}")
        else ()
            if (${MCU_CHIP} MATCHES "nrf51.*_xxaa")
                set(ld ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/nrf51_xxaa.ld)
            elseif (${MCU_CHIP} MATCHES "nrf52.*_xxaa")
                set(ld ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/nrf52_xxaa.ld)
            else ()
                message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${MCU_CHIP}")
            endif ()

            set_target_properties(${T} PROPERTIES MCU_LINKER_SCRIPT ${ld})
        endif ()
    endif ()

    target_link_libraries(${T} PUBLIC
        "-L\"${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc\""
        "-T\"$<TARGET_PROPERTY:MCU_LINKER_SCRIPT>\"")
endfunction()

function(_nrf_chip_values INCLUDES_VAR DEFINES_VAR)
    if (${MCU_CHIP} MATCHES "nrf51.*")
        list(APPEND defines NRF51)
        if (${MCU_CHIP} MATCHES "nrf51822")
            list(APPEND defines NRF51822)
        elseif (${MCU_CHIP} MATCHES "nrf51422")
            list(APPEND defines NRF51422)
        else ()
            message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${MCU_CHIP}")
        endif ()
    elseif (${MCU_CHIP} MATCHES "nrf52.*")
        list(APPEND defines NRF52)

        if (${MCU_CHIP} MATCHES "nrf52832_.*")
            list(APPEND defines NRF52832)
        else ()
            message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${MCU_CHIP}")
        endif ()
    else ()
        message(FATAL_ERROR "MCU: Unsupported MCU chip: ${MCU_CHIP}")
    endif ()

    set(${INCLUDES_VAR} ${includes} PARENT_SCOPE)
    set(${DEFINES_VAR} ${defines} PARENT_SCOPE)
endfunction()

function(_nrf_softdevice_includes SOFTDEVICE INCLUDES_VAR DEFINES_VAR)
    # message("_nrf_softdevice_includes: SOFTDEVICE=${SOFTDEVICE}")
    if (SOFTDEVICE)
        list(APPEND includes ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers)

        if (EXISTS ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf51)
            list(APPEND includes ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf51)
        endif ()

        if (EXISTS ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf52)
            list(APPEND includes ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf52)
        endif ()

        list(APPEND defines
            S${SOFTDEVICE}
            SOFTDEVICE_PRESENT
            BLE_STACK_SUPPORT_REQD)

        set(NRF_SD_BLE_API_VERSION 2)
        if (${SOFTDEVICE} MATCHES "132")
            set(NRF_SD_BLE_API_VERSION 3)
        endif ()
        list(APPEND defines NRF_SD_BLE_API_VERSION=${NRF_SD_BLE_API_VERSION})

    else ()
        list(APPEND includes ${MCU_NRF5X_SDK_PATH}/components/drivers_nrf/nrf_soc_nosd)
    endif ()

    set(${INCLUDES_VAR} ${includes} PARENT_SCOPE)
    set(${DEFINES_VAR} ${defines} PARENT_SCOPE)
endfunction()
