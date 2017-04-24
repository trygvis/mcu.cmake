.syntax unified
.cpu cortex-m3
.thumb

.section .text

.thumb_func
.global _Reset_Handler
_Reset_Handler:
    bl init_high
    b halt

.end
