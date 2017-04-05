cmake_minimum_required(VERSION 2.8.2)

project(elfstats C CXX)

include(CheckIncludeFiles)
include(CheckLibraryExists)

check_include_files("sys/types.h" HAVE_SYS_TYPES_H)

if(NOT HAVE_SYS_TYPES_H)
  message(FATAL_ERROR "Missing sys/types.h. You should install package libc6-dev or similar.")
endif()

check_library_exists(elf elf_version "" HAVE_LIB_ELF)

if(NOT HAVE_LIB_ELF)
  message(FATAL_ERROR "Missing library libelf. You should install package libelf-dev or similar.")
endif()

add_executable(elfstats elfstats.cpp)
target_link_libraries(elfstats PUBLIC elf)

install(TARGETS elfstats DESTINATION bin)
