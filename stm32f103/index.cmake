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
        message(FATAL_ERROR "MCU: mcu_add_executable: Missing required argument: TARGET")
    endif ()

    # Work around LTO bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=69866
    set_source_files_properties("${MCU_BASEDIR}/stm32f103/src/init_high.cpp" PROPERTIES COMPILE_FLAGS -fno-lto)
    set_source_files_properties("${MCU_BASEDIR}/stm32f103/src/default_handler.cpp" PROPERTIES COMPILE_FLAGS -fno-lto)

    _mcu_stm32_configure_target_options(${ARGS_TARGET})

    target_link_libraries(${ARGS_TARGET} PUBLIC
        -mcpu=cortex-m3
        -mthumb
        -nostdlib
        -nostartfiles
        -Wl,--gc-sections
        )

    # Linker script

    if (ARGS_LINKER_SCRIPT)
        if (NOT IS_ABSOLUTE "${ARGS_LINKER_SCRIPT}")
            set(ARGS_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_LINKER_SCRIPT}")
        endif ()
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_LINKER_SCRIPT "${ARGS_LINKER_SCRIPT}")
    endif ()

    _mcu_stm32_configure_linker_script(${ARGS_TARGET})

    if(MCU_BINUTILS_MODE STREQUAL AUTO)
        mcu_binutils_create_dump_targets(${ARGS_TARGET})
    endif()
    if(MCU_ELFSTATS_MODE STREQUAL AUTO)
        mcu_elfstats_create_targets(${ARGS_TARGET})
    endif()

endfunction()

function(mcu_add_library)
    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: mcu_add_library: Missing required argument: TARGET")
    endif ()

    _mcu_stm32_configure_target_options(${ARGS_TARGET})

endfunction()

function(_mcu_stm32_configure_target_options T)
    if (MCU_CHIP MATCHES "stm32f103.4" OR MCU_CHIP MATCHES "stm32f103.6")
        set(size_define STM32F10X_SM)
    elseif (MCU_CHIP MATCHES "stm32f103.8" OR MCU_CHIP MATCHES "stm32f103.b")
        set(size_define STM32F10X_MD)
    elseif (MCU_CHIP MATCHES "stm32f103.c" OR MCU_CHIP MATCHES "stm32f103.d" OR MCU_CHIP MATCHES "stm32f103.e")
        set(size_define STM32F10X_LD)
    else ()
        message(FATAL_ERROR "MCU: mcu_add_executable: Unknown STM32 version: ${MCU_CHIP}")
    endif ()

    target_compile_definitions(${T} PUBLIC ${size_define})

    set(o_level "$<TARGET_PROPERTY:O_LEVEL>")
    target_compile_options(${T} PUBLIC
        "$<$<BOOL:${o_level}>:-O${o_level}>$<$<NOT:$<BOOL:${o_level}>>:-O3>")
    unset(o_level)

    target_compile_options(${T} PUBLIC
        -mcpu=cortex-m3
        -mthumb
        -g
        )

    if(MCU_LTO_MODE STREQUAL AUTO)
        target_compile_options(${T} PRIVATE
            -flto
            )
    endif()

endfunction()

function(_mcu_stm32_configure_linker_script T)
    get_target_property(MCU_LINKER_SCRIPT ${T} MCU_LINKER_SCRIPT)

    if (NOT MCU_LINKER_SCRIPT)
        set(ld "${MCU_BASEDIR}/stm32f103/stm32f103.ld")
        message("MCU: Using built-in linker script: ${ld}")

        set_target_properties(${T} PROPERTIES MCU_LINKER_SCRIPT ${ld})
    endif ()

    target_link_libraries(${T} PUBLIC
        "-T\"$<TARGET_PROPERTY:MCU_LINKER_SCRIPT>\"")
endfunction()
