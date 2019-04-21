`include "cc.sv"

/* ALU interface types. */
package alu;

/* Operations supported by the ALU. */
typedef enum bit [2:0] {
    ADD,
    AND,
    XOR,
    LSL,
    LSR,
    MUL,
    OR,
    SUB
} op_t;
endpackage

/* ALU implementation. */
module Alu(
    input alu::op_t op,
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] result,
    output [2:0] cc
);

Cc Cc(.value(result), .cc(cc));

always @(*) begin
    case(op)
        alu::ADD:   result = a + b;
        alu::AND:   result = a & b;
        alu::XOR:   result = a ^ b; 
        alu::LSL:   result = a << b[3:0];
        alu::LSR:   result = a >> b[3:0];
        alu::MUL:   result = a * b;
        alu::OR:    result = a | b;
        alu::SUB:   result = a - b;
    endcase
end
endmodule
