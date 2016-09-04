function(d2000_init)
    list(APPEND includes "${ISSM_DIR}/firmware/bsp/1.0/soc/quark_d2000/include")
    set(includes "${includes}" PARENT_SCOPE)
    set(ld_file "${ISSM_DIR}/firmware/bsp/1.0/soc/quark_d2000/quark_d2000.ld" PARENT_SCOPE)

    list(APPEND mcu_text_areas 0x00180000:20k)
    export_variable(mcu_text_areas)

    list(APPEND mcu_data_areas 0x00280000:5k)
    export_variable(mcu_data_areas)
endfunction()
