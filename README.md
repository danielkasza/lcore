# _LCORE_ - Pipelined LC-3 CPU

Daniel Kasza - daniel@kasza.hu

_LCORE_ is a small, pipelined implementation of the LC-3 CPU architecture. The CPU uses a 3-stage pipeline:
1. __IF__ - Instruction Fetch
2. __DE__ - DEcode
3. __EX__ - EXecute

Branch prediction is not implemented, so branches are always treated as not taken.
When a branch is taken, the EX stage tells the IF stage which instruction to fetch next, and the DE stage invalidates the instruction that was fetched on the previous cycle by replacing it with a no-op.
This means that taking a branch has a 1 cycle penalty.

Source registers are fetched during the EX stage.

## Differences from LC-3

* `STI` and `LDI` instructions are not supported because the do not fit in the pipeline.
* Traps are not supported.
* Memory mapped I/O is replaced with a dedicated I/O port.
* `NOT` instruction is replaced with a more generic `XOR` instruction. `NOT` is a special case of this.
* Reserved opcode is used to implement bit shift instructions. This extension is borrowed from LC-3b.
