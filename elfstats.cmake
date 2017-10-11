include(ExternalProject)

set(MCU_ELFSTATS_BIN "${CMAKE_BINARY_DIR}")
#message("MCU_ELFSTATS_BIN=${MCU_ELFSTATS_BIN}")

ExternalProject_Add(elfstats
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/elfstats
    EXCLUDE_FROM_ALL TRUE
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}")

function(mcu_elfstats_create_targets TARGET)

    add_dependencies(${TARGET} elfstats)

    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND "${MCU_ELFSTATS_BIN}/bin/elfstats" -f ${TARGET})

endfunction()
