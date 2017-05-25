ENTRY(_Reset_Handler)

MEMORY
{
  FLASH (rx)      : ORIGIN = 0x08000000, LENGTH = 64K
  RAM (xrw)       : ORIGIN = 0x20000000, LENGTH = 20k
  MEMORY_B1 (rx)  : ORIGIN = 0x60000000, LENGTH = 0K
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    /* Put the ISR section at the start of the flash area */
    .isr :
    {
        /* The first word has to be the initial stack pointer */
        LONG(__initial_stack_pointer);
        KEEP(*(.isr_vectors))
    } >FLASH
    ASSERT(SIZEOF(.isr) > 100, "The isr_vectors section is too small")
    ASSERT(SIZEOF(.isr) < 1000, "The isr_vectors section is too big")
    ASSERT(ADDR(.isr) == ORIGIN(FLASH), "The isr_vectors section was not placed at the start of the flash area")

    .text :
    {
        *(.text)
        KEEP(*(.text.*))
        *(.rodata*)
    } >FLASH

    .init_arrays :
    {
        _init_array_start = .;
        KEEP(*(.init_array))
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
        _init_array_end = .;
    } >FLASH

     . = ORIGIN(RAM);

    .data ALIGN(4) :
    {
        *(.data)
        *(.data.*)
    } >RAM AT >FLASH

    .bss ALIGN(4) (NOLOAD) :
    {
        *(.bss)
        *(.bss.*)
    } >RAM

    _copy_data_store = ADDR(.data);
    _copy_data_store_end = _copy_data_store + SIZEOF(.data);
    _copy_data_load = LOADADDR(.data);

    _bss_start = ADDR(.bss);
    _bss_end = _bss_start + SIZEOF(.bss);

    /* Stm32cube compatibility */
    _sbss = _bss_start;
    _ebss = _bss_end;
    _sdata = _copy_data_store;
    _edata = _copy_data_store_end;
    _sidata = _copy_data_load;

    /* The stack pointer has to be aligned on a 8 byte boundary for va_arg(<64 bit quantity>) to work. */
    __initial_stack_pointer = ALIGN(ORIGIN(RAM) + LENGTH(RAM) - 8, 8);
}
