ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 256
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 256
}

SECTIONS
{
    .text : {
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
    } > ROM

    .data : {
        __data_start = .;
        *(.data*)
        *(.sdata*)
        __data_end = .;
    } > RAM

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        __bss_end = .;
    } > RAM

    __stack_size = 64;
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);
    __stack_bottom = __stack_top - __stack_size;

    ASSERT(SIZEOF(.text) <= LENGTH(ROM), "counter firmware exceeds the 256-byte ROM")
    ASSERT(SIZEOF(.data) == 0, "startup does not initialize .data; use compile-time constants")
    ASSERT(__bss_end <= __stack_bottom, "counter firmware data and stack exceed the 256-byte RAM")
}
