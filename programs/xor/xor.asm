.orig x0

start:
    add r0, r0, #15
    xor r0, r0, r0
    brnp fail
    out r0, #0
fail:
    br fail

.end
