.orig x0

start:
    lea r0, interrupt_handler
    ; Set new interrupt handler address.
    out r0, 1
    ; Loop forever, unless an interrupt comes in.
forever:
    br forever


interrupt_handler:
    rti
    ; There is a bug in the assembler.
    ; It fails if I don't put another instruction in this handler.
    out r0, 0

.end
