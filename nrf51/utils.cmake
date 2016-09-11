function(mcu_nrf5_startup_files VAR)
    if ("${MCU_NRF51_SDK_VERSION}" VERSION_LESS 12)
        set(startup "${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/gcc_startup_nrf51.s")
    else ()
        set(startup "${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/gcc_startup_nrf51.S")
    endif ()

    set(${VAR} ${startup} PARENT_SCOPE)
endfunction()

function(mcu_add_executable)
    message("mcu_add_executable: ARGN=${ARGN}")
    set(options)
    set(oneValueArgs TARGET SDK_CONFIG SOFTDEVICE)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARGS_TARGET)
        message(FATAL_ERROR "MCU: Missing required argument: TARGET")
    endif ()

    target_sources(${ARGS_TARGET} PUBLIC "${MCU_NRF51_SDK_PATH}/components/toolchain/system_nrf51.c")

    # 12 might be too old
    if ("${MCU_NRF51_SDK_VERSION}" VERSION_LESS 12)
        target_sources(${ARGS_TARGET} PUBLIC "${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/gcc_startup_nrf51.s")
    else ()
        target_sources(${ARGS_TARGET} PUBLIC "${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/gcc_startup_nrf51.S")
    endif ()

    target_compile_options(${ARGS_TARGET} PUBLIC -Wall -Werror -g3 -O3)

    # -Wall -Werror -O3 -g3
    if (${MCU_CHIP} MATCHES "nrf51.*")
        target_compile_options(${ARGS_TARGET} PUBLIC
            "-mcpu=cortex-m0"
            "-mthumb"
            "-mabi=aapcs"
            "-mfloat-abi=soft")
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
        message("set_target_properties(${ARGS_TARGET} PROPERTIES SDK_CONFIG ${SDK_CONFIG})")
    endif ()

    set_target_properties(${ARGS_TARGET} PROPERTIES SDK_CONFIG "${SDK_CONFIG}")

    if (ARGS_SOFTDEVICE)
        set_target_properties(${ARGS_TARGET} PROPERTIES MCU_SOFTDEVICE "${ARGS_SOFTDEVICE}")
    endif ()

    _nrf5_set_from_main_target(${ARGS_TARGET})
endfunction()

function(_nrf5_set_from_main_target T)
    message("_nrf5_set_from_main_target, T=${T}")
    _nrf_chip_values(CHIP_INCLUDES CHIP_DEFINES)
    target_include_directories(${T} PUBLIC ${CHIP_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${CHIP_DEFINES})

    target_include_directories(${T} PUBLIC
        ${MCU_NRF51_SDK_PATH}/components/device
        ${MCU_NRF51_SDK_PATH}/components/toolchain
        ${MCU_NRF51_SDK_PATH}/components/toolchain/gcc
        ${MCU_NRF51_SDK_PATH}/components/toolchain/cmsis/include
        )

    get_target_property(SDK_CONFIG ${T} SDK_CONFIG)
    if (SDK_CONFIG)
        # message("_nrf5_set_from_main_target: SDK_CONFIG=${SDK_CONFIG}")
        target_include_directories(${T} PRIVATE ${SDK_CONFIG})
    endif ()

    get_target_property(MCU_SOFTDEVICE ${T} MCU_SOFTDEVICE)
    _nrf_softdevice_includes(${MCU_SOFTDEVICE} SOFTDEVICE_INCLUDES SOFTDEVICE_DEFINES)
    target_include_directories(${T} PUBLIC ${SOFTDEVICE_INCLUDES})
    target_compile_definitions(${T} PUBLIC ${SOFTDEVICE_DEFINES})

    list(APPEND link_libraries -L${MCU_NRF51_SDK_PATH}/components/toolchain/gcc)

    if (SOFTDEVICE)
        set(ld ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/toolchain/armgcc/armgcc_s${SOFTDEVICE}_${MCU_CHIP}.ld)

        if (NOT EXISTS ${ld})
            message(FATAL_ERROR "No linker script defined for combination: softdevice=${SOFTDEVICE} and chip=${MCU_CHIP}: expected location: ${ld}")
            return()
        endif ()

        list(APPEND link_libraries -T${ld})
    else ()
        if (${MCU_CHIP} MATCHES "nrf51.*_xxaa")
            list(APPEND link_libraries -T${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/nrf51_xxaa.ld)
        elseif (${MCU_CHIP} MATCHES "nrf52.*_xxaa")
            list(APPEND link_libraries -T${MCU_NRF51_SDK_PATH}/components/toolchain/gcc/nrf52_xxaa.ld)
        else ()
            message(FATAL_ERROR "MCU: Unsupported nRF MCU chip: ${MCU_CHIP}")
        endif ()
    endif ()

    target_link_libraries(${T} PUBLIC ${link_libraries})
endfunction()

function(_nrf_chip_values INCLUDES_VAR DEFINES_VAR)
    if (${MCU_CHIP} MATCHES "nrf51.*")
        list(APPEND defines NRF51)
        if (${MCU_CHIP} MATCHES "nrf51822")
            list(APPEND defines NRF51822)
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
    message("_nrf_softdevice_includes: SOFTDEVICE=${SOFTDEVICE}")
    if (SOFTDEVICE)
        list(APPEND includes ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers)

        if (EXISTS ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf51)
            list(APPEND includes ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf51)
        endif ()

        if (EXISTS ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf52)
            list(APPEND includes ${MCU_NRF51_SDK_PATH}/components/softdevice/s${SOFTDEVICE}/headers/nrf52)
        endif ()

        list(APPEND defines S${SOFTDEVICE} SOFTDEVICE_PRESENT)
    else ()
        list(APPEND includes ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/nrf_soc_nosd)
    endif ()

    set(${INCLUDES_VAR} ${includes} PARENT_SCOPE)
    set(${DEFINES_VAR} ${defines} PARENT_SCOPE)
endfunction()

# Toolchain files are executed many times when detecting c/c++ compilers, but it will only read the cache on the first
# exeuction so the paths has to be saved to the environment as it is shared between executions.
function(mcu_nrf51_detect_sdk)
    if (MCU_NRF51_SDK_PATH)
        # message("MCU: NRF51 SDK already found: ${MCU_NRF51_SDK_PATH}")
        return()
    endif ()

    set(MCU_NRF51_SDK_PATH "$ENV{_MCU_NRF51_SDK_PATH}")

    if (MCU_NRF51_SDK_PATH)
        # message("MCU: NRF51 SDK already found from ENV: ${MCU_NRF51_SDK_PATH}")
        return()
    endif ()

    message("MCU: Detecting NRF51 SDK")

    if (NOT MCU_NRF51_SDK)
        set(MCU_NRF51_SDK "" CACHE PATH "" FORCE)
        message(FATAL_ERROR "MCU: MCU_NRF51_SDK parameter cannot be empty.")
        return()
    endif ()

    get_filename_component(MCU_NRF51_SDK_PATH "${MCU_NRF51_SDK}" ABSOLUTE)

    set(ENV{_MCU_NRF51_SDK_PATH} "${MCU_NRF51_SDK_PATH}")

    set(NOTES ${MCU_NRF51_SDK_PATH}/documentation/release_notes.txt)

    if (NOT EXISTS ${NOTES})
        message(FATAL_ERROR "MCU: Could not find 'documentation/release_notes.txt' under NRF SDK path: ${NOTES}")
    endif ()

    file(STRINGS ${NOTES} NOTES_LIST)
    list(GET NOTES_LIST 0 NOTES_0)

    if (NOTES_0 MATCHES "nRF5.? SDK [^0-9]*([\\.0-9]*)")
        set(MCU_NRF51_SDK_VERSION "${CMAKE_MATCH_1}")
    else ()
        message(FATAL_ERROR "MCU: Could not detect SDK version.")
        return()
    endif ()

    message("MCU: nRF51 SDK Path: ${MCU_NRF51_SDK_PATH} (Version: ${MCU_NRF51_SDK_VERSION})")

    set(MCU_NRF51_SDK_VERSION "${MCU_NRF51_SDK_VERSION}" CACHE STRING "MCU: nRF51 SDK version" FORCE)
    set(MCU_NRF51_SDK_PATH "${MCU_NRF51_SDK_PATH}" CACHE PATH "MCU: nRF51 SDK path" FORCE)
endfunction()

#[[
function(_nrf51_add_library MAIN_TARGET T)
    # message("_nrf51_add_library(${MAIN_TARGET} ${T} ARGN=${ARGN})")

    set(options)
    set(oneValueArgs EXCLUDE_SOURCES)
    set(multiValueArgs SOURCE_DIR)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    foreach (DIR IN LISTS ARGS_SOURCE_DIR)
        file(GLOB_RECURSE SOURCES ${DIR}/*.c)

        if (ARGS_EXCLUDE_SOURCES)
            list(FILTER SOURCES EXCLUDE REGEX ${ARGS_EXCLUDE_SOURCES})
        endif ()
        list(APPEND ALL_SOURCES ${SOURCES})

        file(GLOB_RECURSE HEADERS LIST_DIRECTORIES TRUE ${DIR}/*.h)
        list(APPEND ALL_HEADERS ${HEADERS})

        # Add all directories that contain header files as private include directories
        foreach (H IN LISTS HEADERS)
            get_filename_component(D ${H} DIRECTORY)
            list(APPEND INCLUDES ${D})
        endforeach ()
        list(SORT INCLUDES)
        list(APPEND ALL_INCLUDES ${INCLUDES})
    endforeach ()

    add_library(${T} ${type} ${ALL_SOURCES} ${ALL_HEADERS})
    target_include_directories(${T} PUBLIC ${ALL_INCLUDES})

    list(LENGTH ALL_SOURCES l)
    if (l EQUAL 0)
        set_target_properties(${T} PROPERTIES LINKER_LANGUAGE CXX)
    endif ()

    _nrf5_set_from_main_target(${MAIN_TARGET} ${T})
endfunction()
]]

# TODO: this is really a public function, move arguments to parsed arguments
#[[
function(_nrf5_gen_lib TARGET LIB)
    set(options)
    set(oneValueArgs ADD_TO)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(T ${TARGET}-${LIB})

    if (_MCU_NRF51_LIB_CREATED_${T})
        # message("MCU: already created: ${T}")

        if (ARGS_ADD_TO)
            target_link_libraries(${ARGS_ADD_TO} PUBLIC ${T})
        endif ()

        return()
    endif ()

    if (NOT LIB)
        message(FATAL_ERROR "MCU: Missing required argument: LIB")
    elseif (LIB STREQUAL ble)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/ble/common
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/ble/ble_advertising
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/ble/peer_manager)

        _nrf5_gen_lib(${TARGET} ble_flash ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} timer ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})

        # Dependency of peer_manager
        _nrf5_gen_lib(${TARGET} fds ADD_TO ${T})

        # 12+
        _nrf5_gen_lib(${TARGET} fstorage ADD_TO ${T})
    elseif (LIB STREQUAL ble_dfu)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/ble/ble_services/ble_dfu)

        _nrf5_gen_lib(${TARGET} ble ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} bootloader ADD_TO ${T})
    elseif (LIB STREQUAL ble_flash)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/ble_flash)

        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL bootloader AND MCU_NRF51_SDK_VERSION VERSION_GREATER 7)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/bootloader)

        _nrf5_gen_lib(${TARGET} ble ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} gpiote ADD_TO ${T})
        if (MCU_NRF51_SDK_VERSION VERSION_GREATER 7)
            _nrf5_gen_lib(${TARGET} section_vars ADD_TO ${T})
        endif ()
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL button)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/button)
        _nrf5_gen_lib(${TARGET} gpiote ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} hal ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} timer ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL delay AND MCU_NRF51_SDK_VERSION VERSION_GREATER 7)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/delay)
    elseif (LIB STREQUAL drv_common)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/common)
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL fds)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/fds)
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} fstorage ADD_TO ${T})
    elseif (LIB STREQUAL fstorage)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/fstorage)

        _nrf5_gen_lib(${TARGET} section_vars ADD_TO ${T})
    elseif (LIB STREQUAL gpiote)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/gpiote)
        _nrf5_gen_lib(${TARGET} drv_common ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} hal ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL hal)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/drivers_nrf/hal)
    elseif (LIB STREQUAL scheduler)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/scheduler)

        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
    elseif (LIB STREQUAL section_vars AND MCU_NRF51_SDK_VERSION VERSION_GREATER 7)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/experimental_section_vars)
    elseif (LIB STREQUAL sensorsim)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/sensorsim)
    elseif (LIB STREQUAL timer)
        # TODO: make this configurable, could probably be a target property

        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/timer
            EXCLUDE_SOURCES "app_timer_.*")
        target_sources(${T} PUBLIC ${MCU_NRF51_SDK_PATH}/components/libraries/timer/app_timer_appsh.c)

        _nrf5_gen_lib(${TARGET} util ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} delay ADD_TO ${T})
        _nrf5_gen_lib(${TARGET} scheduler ADD_TO ${T})
    elseif (LIB STREQUAL util)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/util
            EXCLUDE_SOURCES ".*cmock.*")

        _nrf5_gen_lib(${TARGET} log ADD_TO ${T})
    elseif (LIB STREQUAL log)
        _nrf51_add_library(${TARGET} ${T}
            SOURCE_DIR ${MCU_NRF51_SDK_PATH}/components/libraries/log)
        target_include_directories(${T} PUBLIC ${MCU_NRF51_SDK_PATH}/components/log)
    else ()
        message(FATAL_ERROR "MCU: Unsupported LIB: ${LIB}")
    endif ()

    if (ARGS_ADD_TO)
        target_link_libraries(${ARGS_ADD_TO} PUBLIC ${T})
    endif ()

    set(_MCU_NRF51_LIB_CREATED_${T} TRUE CACHE BOOL "" FORCE)
endfunction()
]]
