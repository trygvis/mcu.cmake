include(ExternalProject)

ExternalProject_Add(elfstats
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/elfstats
    EXCLUDE_FROM_ALL TRUE
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}
    )
