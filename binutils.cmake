function(mcu_binutils_create_dump_targets TARGET)
    if (MCU_ARM_OBJDUMP)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_OBJDUMP} -D ${TARGET} > ${TARGET}-info/${TARGET}.asm
                BYPRODUCTS ${TARGET}-info/${TARGET}.asm)
    endif ()

    if (MCU_ARM_NM)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_NM} -C ${TARGET} > ${TARGET}-info/${TARGET}.nm
                BYPRODUCTS ${TARGET}-info/${TARGET}.nm)
    endif ()

    if (MCU_ARM_SIZE)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_SIZE} ${TARGET} > ${TARGET}-info/${TARGET}.size
                BYPRODUCTS ${TARGET}-info/${TARGET}.size)
    endif ()

    if (MCU_ARM_READELF)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_READELF} -a ${TARGET} > ${TARGET}-info/${TARGET}.readelf
                BYPRODUCTS ${TARGET}-info/${TARGET}.readelf)
    endif ()

    if (MCU_ARM_OBJCOPY)
        set(hex ${TARGET}-info/${TARGET}.hex)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_OBJCOPY} -O ihex ${TARGET} ${hex}
                BYPRODUCTS ${hex})
        set_target_properties(${TARGET} PROPERTIES MCU_OUTPUT_NAME_HEX ${hex})

        set(bin ${TARGET}-info/${TARGET}.bin)
        add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET}-info
                COMMAND ${MCU_ARM_OBJCOPY} -O binary ${TARGET} ${bin}
                BYPRODUCTS ${bin})
        set_target_properties(${TARGET} PROPERTIES MCU_OUTPUT_NAME_BIN ${bin})
    endif ()
endfunction()
