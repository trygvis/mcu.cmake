function(openocd_init)
    set(openocd_bin "${ISSM_DIR}/tools/debugger/openocd/bin/openocd")
    export_variable(openocd_bin)
    set(openocd_scripts "${ISSM_DIR}/tools/debugger/openocd/scripts")
    export_variable(openocd_scripts)
endfunction()
