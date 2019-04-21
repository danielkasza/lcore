.orig x0

start:
    ; Set new interrupt handler address.
    lea r0, interrupt_handler
    out r0, 1
    ; Enable standard input interrupt.
    ld  r0, interrupt_mask
    out r0, 5
    ; Enter idle loop.
idle:
    br idle
    out r0, 0
    out r0, 0
    out r0, 0

interrupt_mask .fill 1

interrupt_handler:
    ; Read standard input
    in r0, 2
    ; Discard what was read
    out r0, 2
    ; Write to standard output
    out r0, 3
    rti
    ; There is a bug in the assembler.
    ; It fails if I don't put another instruction in this handler.
    out r0, 0

.end
