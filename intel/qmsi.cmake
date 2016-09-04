function(qmsi_init)
endfunction()

function(qmsi_create TARGET_SUFFIX)
    set(qmsi qmsi_${TARGET_SUFFIX})
    set(bmc qmsi_bmc_${TARGET_SUFFIX})
    message("Creating QMSI targets ${qmsi} and ${bmc}")

    file(GLOB_RECURSE qmsi_sources
            ${ISSM_DIR}/firmware/bsp/1.0/drivers/*.c
            ${ISSM_DIR}/firmware/bsp/1.0/sys/*.c)
    add_library(${qmsi} STATIC ${qmsi_sources})
    target_include_directories(${qmsi} PUBLIC "${ISSM_DIR}/firmware/bsp/1.0/include")
    target_include_directories(${qmsi} PUBLIC "${ISSM_DIR}/firmware/bsp/1.0/drivers/include")

    message("INTEL_QUARK_CHIP=${INTEL_QUARK_CHIP}")
    if (INTEL_QUARK_CHIP STREQUAL D2000)
        target_include_directories(${qmsi} PUBLIC "${ISSM_DIR}/firmware/bsp/1.0/soc/quark_d2000/include")
    elseif (INTEL_QUARK_CHIP STREQUAL SE)
        target_include_directories(${qmsi} PUBLIC "${ISSM_DIR}/firmware/bsp/1.0/soc/quark_se/include")
    endif ()

    file(GLOB_RECURSE bmc_sources ${ISSM_DIR}/firmware/bsp/1.0/board/drivers/bmc150/*.c)
    add_library(${bmc} STATIC ${bmc_sources})
    target_link_libraries(${bmc} PUBLIC ${qmsi})
    target_include_directories(${bmc} PUBLIC "${ISSM_DIR}/firmware/bsp/1.0/board/drivers")
endfunction()
