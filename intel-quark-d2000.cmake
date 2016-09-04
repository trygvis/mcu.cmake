if (${INTEL_QUARK_TOOLCHAIN_LOADED})
    return()
endif ()
set(INTEL_QUARK_TOOLCHAIN_LOADED TRUE)

include(CMakeForceCompiler)

set(TRIPLE "i586-intel-elfiamcu")

if (NOT IS_DIRECTORY "${ISSM_DIR}")
    message(FATAL_ERROR "ISSM_DIR has to be set to a directory:" ${ISSM_DIR})
    set(ISSM_DIR CACHE PATH "The path to Intes ISSM")
endif ()

if (NOT INTEL_QUARK_CHIP)
    set(INTEL_QUARK_CHIP CACHE STRING "The Intel Quark chip to build for")
    message(FATAL_ERROR "INTEL_QUARK_CHIP has to be set before including the toolchain file")
endif ()

get_filename_component(toolchain_dir "${CMAKE_TOOLCHAIN_FILE}" DIRECTORY)

macro(export_variable NAME)
    set(${NAME} "${${NAME}}" PARENT_SCOPE)
endmacro()

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR intel)
set(CMAKE_CROSSCOMPILING 1)

set(TARGET_FLAGS "-march=lakemont -mtune=lakemont -miamcu -msoft-float")
set(BASE_FLAGS "-std=c90 -Wall -Wextra -Werror -Wno-unused-parameter")

set(INCLUDES "")

# TODO: these directories should be validated
#list(APPEND includes "${ISSM_DIR}/firmware/bsp/1.0/include")
#list(APPEND includes "${ISSM_DIR}/firmware/bsp/1.0/board/drivers")

if (INTEL_QUARK_CHIP STREQUAL D2000)
    include("${toolchain_dir}/intel/d2000.cmake")
    d2000_init()

    include("${toolchain_dir}/intel/openocd.cmake")
    openocd_init()

    include("${toolchain_dir}/intel/gdb.cmake")
    gdb_init()

    include("${toolchain_dir}/intel/qmsi.cmake")
    qmsi_init()
elseif (INTEL_QUARK_CHIP STREQUAL SE)
#    list(APPEND includes "${ISSM_DIR}/firmware/bsp/1.0/soc/quark_se/include")
endif ()

# IPP Library
#file(GLOB_RECURSE ipp_sources ${ISSM_DIR}/firmware/lib/ipp/1.0.0/*.c)
add_library(ipp STATIC IMPORTED)
set_property(TARGET ipp PROPERTY IMPORTED_LOCATION "${ISSM_DIR}/firmware/lib/ipp/1.0.0/lib/libippsq.a")
#target_include_directories(ipp PUBLIC "${ISSM_DIR}/firmware/lib/ipp/1.0.0/include")
set_property(TARGET ipp APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${ISSM_DIR}/firmware/lib/ipp/1.0.0/include")
#target_compile_definitions(ipp PUBLIC -D__IPP_ENABLED__)
#target_compile_options(ipp PUBLIC -Wno-empty-body)
#target_link_libraries(ipp INTERFACE qmsi)

# Compilation
# -O0
# -g
# -DDEBUG
# -fmessage-length=0
# -I../include
# -fno-asynchronous-unwind-tables
# -I../drivers
# -I../drivers/include
#
# -DSPI_IRQ_MST
# -I../soc/quark_d2000/include
# -c
# -o ../drivers/debug/quark_d2000/obj/qm_i2c.o
# ../drivers/qm_i2c.c

# Linking
# i586-intel-elfiamcu-gcc
# -nostdlib
# -L./bsp/build/debug/quark_d2000/libqmsi/lib
# -Xlinker -T./bsp/soc/quark_d2000/quark_d2000.ld
# -Xlinker -A
# -Xlinker --oformat
# -Xlinker -Map=./debug/quark_d2000/obj/accel_test.map
# -o ./debug/quark_d2000/obj/accel_test.elf
# ./debug/quark_d2000/obj/main.o
# ./bsp/sys/debug/quark_d2000/obj/app_entry.o
# ./bsp/sys/debug/quark_d2000/obj/newlib-syscalls.o
# ./bsp/board/drivers/debug/quark_d2000/obj/bmc150.o
# -L/home/trygvis/intel/issm_2016.0.019/firmware/lib/ipp/1.0.0/lib
# -lippsq
# -lc
# -lnosys
# -lsoftfp
# -lgcc
# -lqmsi

set(o_level "$<TARGET_PROPERTY:O_LEVEL>")
add_compile_options("$<$<BOOL:${o_level}>:-O${o_level}>$<$<NOT:$<BOOL:${o_level}>>:-O3>")
unset(o_level)

#include_directories("${includes}")
set(CMAKE_C_FLAGS "${BASE_FLAGS} ${TARGET_FLAGS} " CACHE STRING "c flags")
set(CMAKE_CXX_FLAGS "${BASE_FLAGS} ${TARGET_FLAGS} -fno-exceptions -fno-rtti -felide-constructors -std=c++14" CACHE STRING "c++ flags")

# ${CMAKE_C_FLAGS} is prepended to this string
set(LD_FILE)
set(linker_flags "")
set(linker_flags "${linker_flags} -nostdlib")
set(linker_flags "${linker_flags} -Xlinker -A")
set(linker_flags "${linker_flags} -Xlinker --oformat")

#set(LINKER_LIBS "-larm_cortexM4l_math -lm")

# http://stackoverflow.com/questions/16588097/cmake-separate-linker-and-compiler-flags
set(CMAKE_EXE_LINKER_FLAGS "${linker_flags}" CACHE STRING "linker flags" FORCE)
#unset(linker_flags)

set(GCC "${ISSM_DIR}/tools/compiler/bin/${TRIPLE}-gcc")
#set(GCC "/usr/bin/clang++-3.9")

if (NOT EXISTS "${GCC}")
    message(FATAL_ERROR "Could not find ${TRIPLE}-gcc. Is $ISSM_DIR set correctly?")
endif ()

# No C++ support for D2000
# set(GXX "${ISSM_DIR}/tools/compiler/bin/${TRIPLE}-g++")
# if(NOT EXISTS "${GXX}")
#     message(FATAL_ERROR "Could not find ${TRIPLE}-g++. Is $ISSM_DIR set correctly?")
# endif()
# cmake_force_cxx_compiler("${GXX}" GNU)

cmake_force_c_compiler("${GCC}" GNU)
#cmake_force_c_compiler("${GCC}" LLVM)

# search for programs in the build elfinfo directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

function(toolchain_target TARGET)
    add_dependencies("${TARGET}" elfinfo)
    target_link_libraries("${TARGET}" PUBLIC ipp)
    target_link_libraries("${TARGET}" PUBLIC softfp)
    target_link_libraries("${TARGET}" PUBLIC c)
    target_link_libraries("${TARGET}" PUBLIC g)
    target_compile_definitions("${TARGET}" PUBLIC -D__IPP_ENABLED__)
    target_link_libraries("${TARGET}" PUBLIC "-Xlinker" "-T${ld_file}")
endfunction()

# elfinfo tools

get_filename_component(ELFINFO_SOURCE_DIR "${toolchain_dir}/elfinfo" ABSOLUTE)
get_filename_component(ELFINFO_INSTALL_DIR "${CMAKE_BINARY_DIR}/elfinfo" ABSOLUTE)

include(ExternalProject)
ExternalProject_Add(elfinfo
        SOURCE_DIR "${ELFINFO_SOURCE_DIR}"
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${ELFINFO_INSTALL_DIR})

function(add_extra_commands target_name)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-objdump -D ${target_name} > ${target_name}-info/${target_name}.asm)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-nm -C ${target_name} > ${target_name}-info/${target_name}.nm)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-size ${target_name} > ${target_name}-info/${target_name}.size)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-readelf -a ${target_name} > ${target_name}-info/${target_name}.readelf)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-objcopy -O ihex ${target_name} ${target_name}-info/${target_name}.hex)
    # add_custom_command(TARGET ${target_name} POST_BUILD
    #         COMMAND mkdir -p ${target_name}-info && arm-none-eabi-objcopy -O binary ${target_name} ${target_name}-info/${target_name}.bin)

    foreach(area ${mcu_text_areas})
        set(text_segments "${text_segments}" "-t" "${area}")
    endforeach()
    foreach(area ${mcu_data_areas})
        set(data_segments "${data_segments}" "-d" "${area}")
    endforeach()

    add_custom_command(TARGET ${target_name} DEPENDS elfinfo POST_BUILD
            COMMAND "${ELFINFO_INSTALL_DIR}/bin/elfinfo" -f ${target_name} ${text_segments} ${data_segments})

    add_custom_target(${target_name}-openocd
            DEPENDS ${target_name}
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
            COMMAND ${openocd_bin} -s ${openocd_scripts} -f board/quark_d2000_onboard.cfg)

    add_custom_target(${target_name}-gdb
            DEPENDS ${target_name}
            COMMAND ${gdb_bin}
                -ex "target remote localhost:3333"
                -ex "monitor gdb_breakpoint_override hard"
                -ex "set remotetimeout 30"
                -ex "monitor clk32M"
                -ex "monitor reset halt"
                ${target_name}
            )
endfunction()
