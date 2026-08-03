    .section .text.start
    .globl _start

_start:
    la sp, __stack_top
    call main
    ebreak

1:
    jal x0, 1b
