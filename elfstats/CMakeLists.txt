cmake_minimum_required(VERSION 2.8.2)

project(elfstats CXX)

add_executable(elfstats elfstats.cpp)
target_link_libraries(elfstats PUBLIC elf)

install(TARGETS elfstats DESTINATION bin)
