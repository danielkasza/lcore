.orig x0

start:
    ld r0, ff
loop:
    ; putchar
    out r0, 3
    add r0, r0, #-1
    brp loop
halt:
    ; exit
    out r0, 0
    br halt

ff .fill xff

.end
