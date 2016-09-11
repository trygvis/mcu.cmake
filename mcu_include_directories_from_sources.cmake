function(mcu_include_directories_from_sources)
    set(options)
    set(oneValueArgs SOURCES_VAR HEADERS_VAR INCLUDES_VAR)
    set(multiValueArgs SOURCE_DIR EXCLUDE)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(ALL_SOURCES)
    set(ALL_HEADERS)
    set(ALL_INCLUDES)

    foreach (DIR IN LISTS ARGS_SOURCE_DIR)
        file(GLOB_RECURSE SOURCES ${DIR}/*.c)

        foreach (E IN LISTS ARGS_EXCLUDE)
            list(FILTER SOURCES EXCLUDE REGEX ${E})
        endforeach ()
        list(APPEND ALL_SOURCES ${SOURCES})

        file(GLOB_RECURSE HEADERS LIST_DIRECTORIES TRUE ${DIR}/*.h)
        list(APPEND ALL_HEADERS ${HEADERS})

        # Add all directories that contain header files as private include directories
        foreach (H IN LISTS HEADERS)
            get_filename_component(D ${H} DIRECTORY)
            list(APPEND INCLUDES ${D})
        endforeach ()
        list(APPEND ALL_INCLUDES ${INCLUDES})
    endforeach ()

    if (ARGS_SOURCES_VAR AND ALL_SOURCES)
        list(SORT ALL_SOURCES)
        list(REMOVE_DUPLICATES ALL_SOURCES)
        set(${ARGS_SOURCES_VAR} ${ALL_SOURCES} PARENT_SCOPE)
    endif ()

    if (ARGS_HEADERS_VAR AND ALL_HEADERS)
        list(SORT ALL_HEADERS)
        list(REMOVE_DUPLICATES ALL_HEADERS)
        set(${ARGS_HEADERS_VAR} ${ALL_HEADERS} PARENT_SCOPE)
    endif ()

    if (ARGS_INCLUDES_VAR AND ALL_INCLUDES)
        list(SORT ALL_INCLUDES)
        list(REMOVE_DUPLICATES ALL_INCLUDES)
        set(${ARGS_INCLUDES_VAR} ${ALL_INCLUDES} PARENT_SCOPE)
    endif ()
endfunction()
