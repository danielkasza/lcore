`include "opcodes.sv"
`include "alu.sv"

module cpu(
    input clock,
    input irq,

    /* I/O Port
     * The I/O device cannot throttle I/O.
     * The input path is expected to be combinational.
     * The output is valid for 1 clock.
     *
     * Port 0 to 31 are reserved, and some of them have functions assigned:
     *  0: End of program. Should be provided by platform. Write-only.
     *  1: Interrupt handler address. Handled internally. Write-only.
     *  2: Standard input. Should be provided by platform.
     *     On read, this should provide the next input byte in the lower 8b.
     *     On read, if there is no data available, the top bit should be set.
     *     On write, the input byte should be discarded.
     *  3: Standard output. Should be provided by platform.
     *     On read, it should return a non-zero value if the hardware can accept an output byte.
     *     On write, the lower 8b should be sent.
     *  4: Interrupt status. Should be provided by platform. Read-only.
     *     If an interrupt is pending an unmasked, the corresponding bit should be set.
     *     Bit 0 is reserved for the standard input available interrupt.
     *     Bit 1 is reserved for the standard output ready interrupt.
     *  5: Interrupt mask. Should be provided by platform. Read-write.
     *     If a bit is set in this register, the corresponding interrupt should be enabled.
     *  6-31: RESERVED.
     * Ports 32 and up are available for the platform.
     */
    output [ 8:0] io_port,
    input  [15:0] data_in,
    output [15:0] data_out,
    output        data_out_valid
);

/* Unified memory. */
reg [15:0] mem [(64*1024)-1:0];

initial begin
    $readmemb("program.bin", mem);
end

/* Interrupts *********************************************************************************************************/
reg [15:0] interrupt_vector = 0;
reg [15:0] interrupt_retaddr = 0;
reg        interrupt_active = 0;

wire take_interrupt = (!interrupt_active) && irq;

/* Save new interrupt handler address if port 1 is being written. */
always @(posedge clock) begin
    if (io_port == 1 && data_out_valid) begin
        interrupt_vector <= data_out;
    end
end

/* Instruction Fetch stage. *******************************************************************************************/
reg [15:0] fetch_pc;

always @(*) begin
    fetch_pc = decode_pc + 1;
    /* Handle branch instructions. */
    if (execute & is_jmp) begin
        fetch_pc = alu_result;
    end
    /* Handle interrupts. */
    if (take_interrupt) begin
        fetch_pc = interrupt_vector;
    end
end

always @(posedge clock) begin
    instruction <= mem[fetch_pc];
    decode_pc <= fetch_pc;
end

/* Decode stage. ******************************************************************************************************/
reg [15:0] instruction = 0;
reg [15:0] decode_pc = -1; /* < The first instruction fetched will be 0. */
wire invalidate;

/* Decode all possible immediates. */
wire [15:0] imm5       = {{11{instruction[ 4]}}, instruction[ 4:0]};
wire [15:0] pcoffset9  = {{ 7{instruction[ 8]}}, instruction[ 8:0]};
wire [15:0] pcoffset11 = {{ 5{instruction[10]}}, instruction[10:0]};
wire [15:0] offset6    = {{10{instruction[ 5]}}, instruction[ 5:0]};

/* Decode and propagate common fields. */
always @(posedge clock) begin
    r_sr1 <= instruction[ 8:6];
    r_sr2 <= instruction[ 2:0];
    r_dst <= instruction[11:9];
end

/* Decode and propagate control signals. */
always @(posedge clock) begin
    if (invalidate) begin
        /* Issue a NOP. */
        alu_op <= alu::ADD;
        condition <= 3'b0;
        immediate <= 0;
        use_immediate <= 0;
        use_pc <= 0;
        is_rti <= 0;
        is_jmp <= 0;
        ex_op <= EX_NOP;
    end
    else casez(instruction)
        opcodes::add_rr: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::add_imm: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= imm5;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::and_rr: begin
                alu_op <= alu::AND;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::and_imm: begin
                alu_op <= alu::AND;
                condition <= 3'b111;
                immediate <= imm5;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::br: begin
                alu_op <= alu::ADD;
                condition <= instruction[11:9];
                immediate <= pcoffset9;
                use_immediate <= 1;
                use_pc <= 1;
                is_rti <= 0;
                is_jmp <= 1;
                ex_op <= EX_NOP;
            end
        opcodes::jmp: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 1;
                ex_op <= EX_NOP;
            end
        opcodes::jsr: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= pcoffset11;
                use_immediate <= 1;
                use_pc <= 1;
                is_rti <= 0;
                is_jmp <= 1;
                ex_op <= EX_NOP;
            end
        opcodes::jsrr: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 1;
                ex_op <= EX_NOP;
            end
        opcodes::ld: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= pcoffset9;
                use_immediate <= 1;
                use_pc <= 1;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_LOAD;
            end
        opcodes::ldr: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= offset6;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_LOAD;
            end
        opcodes::lea: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= pcoffset9;
                use_immediate <= 1;
                use_pc <= 1;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::xor_rr: begin
                alu_op <= alu::XOR;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::xor_imm: begin
                alu_op <= alu::XOR;
                condition <= 3'b111;
                immediate <= imm5;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::rti: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= interrupt_retaddr;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 1;
                is_jmp <= 1;
                ex_op <= EX_NOP;
            end
        opcodes::st: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= pcoffset9;
                use_immediate <= 1;
                use_pc <= 1;
                is_jmp <= 0;
                ex_op <= EX_STORE;
            end
        opcodes::str: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= offset6;
                use_immediate <= 1;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_STORE;
            end
        opcodes::in: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_IN;
            end
        opcodes::out: begin
                alu_op <= alu::ADD;
                condition <= 3'b111;
                immediate <= pcoffset9;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_OUT;
            end
        opcodes::lsl_rr: begin
                alu_op <= alu::LSL;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::lsr_rr: begin
                alu_op <= alu::LSR;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::mul_rr: begin
                alu_op <= alu::MUL;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::or_rr: begin
                alu_op <= alu::OR;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        opcodes::sub_rr: begin
                alu_op <= alu::SUB;
                condition <= 3'b111;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_DSTR;
            end
        default: begin
                /* Issue a NOP. */
                alu_op <= alu::ADD;
                condition <= 3'b0;
                immediate <= 0;
                use_immediate <= 0;
                use_pc <= 0;
                is_rti <= 0;
                is_jmp <= 0;
                ex_op <= EX_NOP;
            end
    endcase
end

/* Execute stage. *****************************************************************************************************/
reg [15:0] gprs[7:0];       /* < Registers. */
reg [ 2:0] cc = 3'b111;     /* < Condition codes {n,z,p}. */
reg [ 2:0] condition = 0;   /* < Instruction will execute if any of these condition bit is set. */
wire execute;               /* < Condition matched, should be executed. */
alu::op_t alu_op = 0;       /* < Alu operation to perform. */
reg [15:0] immediate = 0;   /* < Source immediate. */
reg use_immediate = 0;      /* < Second source operand is immediate. */
reg [ 2:0] r_sr1 = 0;       /* < First source register. */
reg use_pc = 0;             /* < First source is decode_pc. */
reg is_rti = 0;             /* < Return from interrupt. First source is 0, and interrupts have to be enabaled. */
reg [ 2:0] r_sr2 = 0;       /* < Second source register. */
reg [ 2:0] r_dst = 0;       /* < Destination register. */
reg is_jmp = 0;             /* < Instruction could cause a jump. */
typedef enum bit [2:0] {
    EX_NOP,
    /* Save ALU result to gprs[r_dst]. */
    EX_DSTR,
    /* Save PC to gprs[7]. */
    EX_CALL,
    /* Save memory access result to gprs[r_dst]. */
    EX_LOAD,
    /* Save gprs[r_dst] to memory. */
    EX_STORE,
    /* Save data_in to gprs[r_dst]. */
    EX_IN,
    /* Output gprs[r_dst] to data_out. */
    EX_OUT
} ex_op_t;
ex_op_t ex_op;

initial begin
    integer i;
    for (i=0; i<8; i++) begin
        gprs[i] = 0;
    end
end

wire [15:0] alu_result;
wire [ 2:0] alu_cc;

assign execute = (cc & condition) != 0;
assign invalidate = (is_jmp && execute) || take_interrupt;

assign io_port = immediate[8:0];
assign data_out = gprs[r_dst];
assign data_out_valid = (ex_op == EX_OUT);

wire [2:0] data_in_cc;
Cc Cc(.value(data_in), .cc(data_in_cc));

Alu Alu(
    .op(alu_op),
    .a(is_rti ? 0 : (use_pc ? decode_pc : gprs[r_sr1])),
    .b(use_immediate ? immediate : gprs[r_sr2]),
    .result(alu_result),
    .cc(alu_cc)
);

always @(posedge clock) begin
    if (take_interrupt) begin
        // This instruction will finish, but the decoded instruction is getting invalidated.
        // Save its address, so we can come back to it later.
        // There is a special case though. If we would be jumping to a different address, we have
        // to save its target instead.
        interrupt_retaddr <= (is_jmp && execute) ? alu_result : decode_pc;
        interrupt_active <= 1;
    end

    if (is_rti) begin
        interrupt_active <= 0;
    end

    if (execute) begin
        case (ex_op)
            default: ;
            EX_DSTR: begin
                    gprs[r_dst] <= alu_result;
                    cc <= alu_cc;
                end
            EX_CALL:  gprs[7] <= decode_pc;
            EX_LOAD: begin
                    gprs[r_dst] <= mem[alu_result];
                    cc <= cc_calc(mem[alu_result]);
                end
            EX_STORE: mem[alu_result] <= gprs[r_dst];
            EX_IN: begin
                    gprs[r_dst] <= data_in;
                    cc <= data_in_cc;
                end
            EX_OUT:   ; /* Combinational. */
        endcase
    end
end

endmodule