.syntax unified
.cpu cortex-m3
.thumb

.section .text

.thumb_func
.global breakpoint
breakpoint:
    BKPT
    bx lr

.end
