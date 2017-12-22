include(${CMAKE_CURRENT_LIST_DIR}/nrfjprog.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/jlink.cmake)

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
    set(oneValueArgs
        # Common options
        TARGET LINKER_SCRIPT CHIP STARTUP_FILES
        # nRF specific options
        SDK_CONFIG SOFTDEVICE)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: Missing required argument: TARGET")
    endif ()

    if (ARGS_CHIP)
        set(chip ${ARGS_CHIP})
    else ()
        set(chip ${MCU_CHIP})
    endif ()
    set_target_properties(${ARGS_TARGET} PROPERTIES MCU_CHIP "${MCU_CHIP}")

    if (ARGS_LINKER_SCRIPT)
        if (NOT IS_ABSOLUTE "${ARGS_LINKER_SCRIPT}")
            set(ARGS_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_LINKER_SCRIPT}")
        endif ()
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_LINKER_SCRIPT "${ARGS_LINKER_SCRIPT}")
    endif ()

    if (${chip} MATCHES "nrf51.*")
        set(chip_series nrf51)
    elseif (${chip} MATCHES "nrf52.*")
        set(chip_series nrf52)
    else ()
        message(FATAL_ERROR "MCU: Unsupported chip: ${chip}")
        return()
    endif ()

    if (chip_series)
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_NRF5X_CHIP_SERIES "${chip_series}")
    endif ()

    if (NOT DEFINED ARGS_STARTUP_FILES)
        set(ARGS_STARTUP_FILES "auto")
    endif ()

    if (ARGS_STARTUP_FILES STREQUAL "auto")
        _nrf5_startup_files(${ARGS_TARGET} STARTUP_FILES)
        target_sources(${ARGS_TARGET} PUBLIC ${STARTUP_FILES})
    endif ()

    target_compile_options(${ARGS_TARGET} PUBLIC -Wall -Werror -g3 -O3)

    target_link_libraries(${ARGS_TARGET} PRIVATE -Wl,-Map=${ARGS_TARGET}.map)

    # -Wall -Werror -O3 -g3
    # "-ffunction-sections"
    # "-fdata-sections"
    # "-fno-strict-aliasing"
    # "-fno-builtin"
    # "--short-enums"

    if (${chip} MATCHES "nrf51.*")
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
    elseif (${chip} MATCHES "nrf52.*")
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
            set_target_properties(${ARGS_TARGET} PROPERTIES MCU_NRF_SD_BLE_API_VERSION "2")
        elseif ("${MCU_NRF5X_SDK_VERSION_MAJOR}" STREQUAL 12 AND ARGS_SOFTDEVICE STREQUAL 132)
            set(hex "${MCU_NRF5X_SDK_PATH}/components/softdevice/s132/hex/s132_nrf52_3.0.0_softdevice.hex")
            set_target_properties(${ARGS_TARGET} PROPERTIES MCU_NRF_SD_BLE_API_VERSION "3")
        elseif ("${MCU_NRF5X_SDK_VERSION_MAJOR}" STREQUAL 14 AND ARGS_SOFTDEVICE STREQUAL 132)
            set(hex "${MCU_NRF5X_SDK_PATH}/components/softdevice/s132/hex/s132_nrf52_5.0.0_softdevice.hex")
            set_target_properties(${ARGS_TARGET} PROPERTIES MCU_NRF_SD_BLE_API_VERSION "5")
        else ()
            message(WARNING "Unknown combination of SDK version (${MCU_NRF5X_SDK_VERSION}) and softdevice (${ARGS_SOFTDEVICE}). Some features might be unavailable.")
        endif ()

        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_SOFTDEVICE "${ARGS_SOFTDEVICE}")

        if (hex)
            file(RELATIVE_PATH hex_rel "${CMAKE_CURRENT_LIST_DIR}" "${hex}")
            message(STATUS "MCU: Softdevice configuration for ${T}")
            message(STATUS "    Version ${ARGS_SOFTDEVICE}")
            message(STATUS "    Hex     ${hex_rel}")
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
    _nrf5_try_add_jlink_targets(${ARGS_TARGET})

endfunction()

function(_nrf5_set_from_main_target T)
    # message("_nrf5_set_from_main_target, T=${T}")

    get_target_property(sdk_config ${T} SDK_CONFIG)
    get_target_property(softdevice ${T} MCU_SOFTDEVICE)
    get_target_property(mcu_linker_script ${T} MCU_LINKER_SCRIPT)

    _nrf_chip_values(${chip} CHIP_INCLUDES CHIP_DEFINES)
    target_include_directories(${T} PUBLIC ${CHIP_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${CHIP_DEFINES})

    target_include_directories(${T} PUBLIC
        ${MCU_NRF5X_SDK_PATH}/components/device
        ${MCU_NRF5X_SDK_PATH}/components/toolchain
        ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc
        ${MCU_NRF5X_SDK_PATH}/components/toolchain/cmsis/include
        )

    if (sdk_config)
        # message("_nrf5_set_from_main_target: sdk_config=${sdk_config}")
        target_include_directories(${T} PRIVATE ${sdk_config})
    endif ()

    _nrf_softdevice_includes(${softdevice} ${T} SOFTDEVICE_INCLUDES SOFTDEVICE_DEFINES)
    target_include_directories(${T} PUBLIC ${SOFTDEVICE_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${SOFTDEVICE_DEFINES})

    # Linker script

    if (NOT mcu_linker_script)
        if (softdevice)
            message("MCU: ${T}: No linker script set. Either use the LINKER_SCRIPT argument to mcu_add_executable() "
                "or set the MCU_LINKER_SCRIPT target property. The softdevice's configuration defines its memory usage "
                "and is application-specific.")

            set(ld ${MCU_NRF5X_SDK_PATH}/components/softdevice/s${softdevice}/toolchain/armgcc/armgcc_s${softdevice}_${chip}.ld)

            if (NOT EXISTS ${ld})
                message("The SDK has a template linker script that can be used as a starting point, but remember to "
                    "adjust the ORIGIN of the RAM area: ${ld}")
                return()
            endif ()

            message(FATAL_ERROR "MCU: Linker script is not configured for ${T}")
        else ()
            if (${chip} MATCHES "nrf51.*_xxaa")
                set(ld ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/nrf51_xxaa.ld)
            elseif (${chip} MATCHES "nrf51.*_xxac")
                set(ld ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/nrf51_xxac.ld)
            elseif (${chip} MATCHES "nrf52.*_xxaa")
                set(ld ${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc/nrf52_xxaa.ld)
            else ()
                message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${chip}")
            endif ()

            set_target_properties(${T} PROPERTIES MCU_LINKER_SCRIPT ${ld})
            message(STATUS "MCU: ${T}: Linker script: ${ld}")
        endif ()
    endif ()

    target_link_libraries(${T} PUBLIC
        "-L\"${MCU_NRF5X_SDK_PATH}/components/toolchain/gcc\""
        "-T\"$<TARGET_PROPERTY:MCU_LINKER_SCRIPT>\"")
    # TODO: here it would be useful to have a dependency on the LD script so the target is relinked when it changes.
endfunction()

function(_nrf_chip_values chip INCLUDES_VAR DEFINES_VAR)
    if (${chip} MATCHES "nrf51.*")
        list(APPEND defines NRF51)
        if (${chip} MATCHES "nrf51822")
            list(APPEND defines NRF51822)
        elseif (${chip} MATCHES "nrf51422")
            list(APPEND defines NRF51422)
        else ()
            message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${chip}")
        endif ()
    elseif (${chip} MATCHES "nrf52.*")
        list(APPEND defines NRF52)

        if (${chip} MATCHES "nrf52832_.*")
            list(APPEND defines NRF52832)
        else ()
            message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${chip}")
        endif ()
    else ()
        message(FATAL_ERROR "MCU: Unsupported MCU chip: ${chip}")
    endif ()

    set(${INCLUDES_VAR} ${includes} PARENT_SCOPE)
    set(${DEFINES_VAR} ${defines} PARENT_SCOPE)
endfunction()

function(_nrf_softdevice_includes SOFTDEVICE T INCLUDES_VAR DEFINES_VAR)
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

        get_target_property(tmp ${T} MCU_NRF_SD_BLE_API_VERSION)

        if (tmp)
            list(APPEND defines NRF_SD_BLE_API_VERSION=${tmp})
        endif ()

    else ()
        list(APPEND includes ${MCU_NRF5X_SDK_PATH}/components/drivers_nrf/nrf_soc_nosd)
    endif ()

    set(${INCLUDES_VAR} ${includes} PARENT_SCOPE)
    set(${DEFINES_VAR} ${defines} PARENT_SCOPE)
endfunction()
