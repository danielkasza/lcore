.orig x0

test_lshf:
    ld r0, lshf_test_val
    ld r1, lshf_test_expected
    lshf r0, r0, 4
    xor r0, r0, r1
    brnp fail
test_rshfl:
    ld r0, rshfl_test_val
    ld r1, rshfl_test_expected
    rshfl r0, r0, 4
    xor r0, r0, r1
    brnp fail
test_rshfa:
    ld r0, rshfa_test_val
    ld r1, rshfa_test_expected
    rshfa r0, r0, 4
    xor r0, r0, r1
    brnp fail
done:
    out r0, #0
fail:
    br fail

lshf_test_val       .fill xFFFF
lshf_test_expected  .fill xFFF0
rshfl_test_val      .fill xF000
rshfl_test_expected .fill x0F00
rshfa_test_val      .fill xF000
rshfa_test_expected .fill xFF00

.end
