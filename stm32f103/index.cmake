set(CMAKE_C_STANDARD "11")
set(CMAKE_CXX_STANDARD "14")

set(MCU_INIT_SOURCES "")
list(APPEND MCU_INIT_SOURCES "${MCU_BASEDIR}/stm32f103/src/init_low.s")
list(APPEND MCU_INIT_SOURCES "${MCU_BASEDIR}/stm32f103/src/init_high.cpp")
list(APPEND MCU_INIT_SOURCES "${MCU_BASEDIR}/stm32f103/src/default_handler.cpp")
list(APPEND MCU_INIT_SOURCES "${MCU_BASEDIR}/stm32f103/include/mcu/init.h")
set(MCU_INIT_INCLUDES "")
list(APPEND MCU_INIT_INCLUDES "${MCU_BASEDIR}/stm32f103/include")

function(mcu_add_executable)

    set(options)
    set(oneValueArgs TARGET LINKER_SCRIPT)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: Missing required argument: TARGET")
    endif ()

    # Linker script

    if (ARGS_LINKER_SCRIPT)
        if (NOT IS_ABSOLUTE "${ARGS_LINKER_SCRIPT}")
            set(ARGS_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_LINKER_SCRIPT}")
        endif ()
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_LINKER_SCRIPT "${ARGS_LINKER_SCRIPT}")
    endif ()

    _stm32_add_compiler_settings(${ARGS_TARGET} ${MCU_CHIP})

    target_link_libraries(${ARGS_TARGET} PUBLIC
            -mcpu=cortex-m3
            -mthumb
            -nostdlib
            -nostartfiles
            -Wl,--gc-sections
            )

    stm32_configure_linker_script(${ARGS_TARGET})

endfunction()

function(mcu_add_library)
    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: Missing required argument: TARGET")
    endif ()

    _stm32_add_compiler_settings(${ARGS_TARGET} ${MCU_CHIP})
endfunction()

function(_stm32_add_compiler_settings ARGS_TARGET MCU_CHIP)

    if (MCU_CHIP MATCHES "stm32f103.4" OR MCU_CHIP MATCHES "stm32f103.6")
        set(size_define STM32F10X_SM)
    elseif (MCU_CHIP MATCHES "stm32f103.8" OR MCU_CHIP MATCHES "stm32f103.b")
        set(size_define STM32F10X_MD)
    elseif (MCU_CHIP MATCHES "stm32f103.c" OR MCU_CHIP MATCHES "stm32f103.d" OR MCU_CHIP MATCHES "stm32f103.e")
        set(size_define STM32F10X_LD)
    else ()
        message(FATAL_ERROR "Unknown STM32 version: ${MCU_CHIP}")
    endif ()

    target_compile_definitions(${ARGS_TARGET} PUBLIC ${size_define})

    # Compile and linker options

    set(o_level "$<TARGET_PROPERTY:O_LEVEL>")
    target_compile_options(${ARGS_TARGET} PUBLIC
            "$<$<BOOL:${o_level}>:-O${o_level}>$<$<NOT:$<BOOL:${o_level}>>:-O3>")
    unset(o_level)

    target_compile_options(${ARGS_TARGET} PUBLIC
            -mcpu=cortex-m3
            -mthumb
            -g
            )

endfunction()

function(stm32_configure_linker_script T)
    get_target_property(MCU_LINKER_SCRIPT ${T} MCU_LINKER_SCRIPT)

    if (NOT MCU_LINKER_SCRIPT)
        set(ld "${MCU_BASEDIR}/stm32f103/stm32f103.ld")
        message("MCU: Using built-in linker script: ${ld}")

        set_target_properties(${T} PROPERTIES MCU_LINKER_SCRIPT ${ld})
    endif ()

    target_link_libraries(${T} PUBLIC
            "-T\"$<TARGET_PROPERTY:MCU_LINKER_SCRIPT>\"")
endfunction()
