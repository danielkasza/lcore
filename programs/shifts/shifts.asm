.orig x0

    ld r3, four
test_lsl:
    ld r0, lsl_test_val
    ld r1, lsl_test_expected
    lsl r0, r0, r3
    xor r0, r0, r1
    brnp fail
test_lsr:
    ld r0, lsr_test_val
    ld r1, lsr_test_expected
    lsr r0, r0, r3
    xor r0, r0, r1
    brnp fail
done:
    out r0, #0
fail:
    br fail

lsl_test_val       .fill xFFFF
lsl_test_expected  .fill xFFF0
lsr_test_val      .fill xF000
lsr_test_expected .fill x0F00
rshfa_test_val      .fill xF000
rshfa_test_expected .fill xFF00
four                .fill 4

.end
