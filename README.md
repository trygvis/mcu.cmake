# About

`mcu.cmake` is a CMake library/toolchain helping with integrating the chip vendors SDKs into your CMake-based builds.

## Goals and considerations

* Make microcontroller projects look and feel as much as possible as any other c/c++ project.
* Use as much as possible of the chip vendor's SDK without requiring any changes to the SDK code.
* Make the CMake code as uniform as feasible between platforms, but allow for platform-specific options and features.

# Recommended layout

For single target builds:

  * A top-level CMake file for your project that sets the current target.
  * A copy of mcu.cmake under the project directory
  * A single build directory


    /CMakeLists.txt
    /mcu.cmake/
    /build/

To build the project the developers would execute something like this:

    git clone --recursive
    mkdir build
    cd build
    cmake ..

For builds that can build for different targets:

  * A top-level CMake file with all general rules
  * A copy of mcu.cmake under the project directory
  * A per-configuration settings file that is used when creating the build directory
  * A build directory per configuration


    /CMakeLists.txt
    /mcu.cmake/
    /target-a.cmake
    /target-b.cmake
    /build-a
    /build-b

To build the project the developers would execute something like this:

    git clone --recursive
    mkdir build
    cd build
    cmake -C ../target-a.cmake ..
