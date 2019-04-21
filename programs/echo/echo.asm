.orig x0

loop:
    ; Read standard input
    in r0, 2
    ; Loop back if no data
    brn loop
    ; Discard what was read
    out r0, 2
    ; Write to standard output
    out r0, 3
    br loop

.end
