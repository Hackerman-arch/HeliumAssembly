.section .data
buf: .space 256
buf2: .space 257
.section .text
.global _start
_start:
mov x0,#0
ldr x1,=buf
mov x2,#256
mov x8, #63
svc #0
mov x0,#1
ldr x1,=buf
mov x2,#256
mov x8, #64
svc #0
mov x0, #0
mov x8, #93
svc #0
