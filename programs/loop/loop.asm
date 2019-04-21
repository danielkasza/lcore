.orig x0

loop:
    add r0, r0, #1
    brnp loop
halt:
    br halt

.end
