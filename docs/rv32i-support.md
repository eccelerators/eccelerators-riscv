# RV32I Support

The first implementation targets RV32I only. The package intentionally excludes
M/C/A/F/D/V extensions, CSRs, interrupts, privilege modes, MMU, caches, debug,
and pipelining.

| Instruction | Implemented | Decode Tested | Core Tested | Notes |
|---|---:|---:|---:|---|
| LUI | yes | yes | yes | Upper immediate |
| AUIPC | yes | yes | yes | PC-relative upper immediate |
| JAL | yes | yes | yes | Writes link register; misaligned targets trap before writeback |
| JALR | yes | yes | yes | Clears target bit 0; misaligned targets trap before writeback |
| BEQ | yes | yes | yes | Taken/not-taken and misaligned taken targets covered |
| BNE | yes | yes | yes | Negative branch offset covered |
| BLT | yes | yes | yes | Signed comparison |
| BGE | yes | yes | yes | Signed comparison |
| BLTU | yes | yes | yes | Unsigned comparison |
| BGEU | yes | yes | yes | Unsigned comparison |
| LB | yes | yes | yes | Sign extends |
| LH | yes | yes | yes | Sign extends, misalignment traps |
| LW | yes | yes | yes | Misalignment traps |
| LBU | yes | yes | yes | Zero extends |
| LHU | yes | yes | yes | Zero extends, misalignment traps |
| SB | yes | yes | yes | Byte lane update |
| SH | yes | yes | yes | Halfword lane update, misalignment traps |
| SW | yes | yes | yes | Word update, misalignment traps |
| ADDI | yes | yes | yes | Immediate add |
| SLTI | yes | yes | yes | Signed less-than |
| SLTIU | yes | yes | yes | Unsigned less-than |
| XORI | yes | yes | yes | Immediate XOR |
| ORI | yes | yes | yes | Immediate OR |
| ANDI | yes | yes | yes | Immediate AND |
| SLLI | yes | yes | yes | Shift amount masked to 5 bits |
| SRLI | yes | yes | yes | Logical right shift |
| SRAI | yes | yes | yes | Arithmetic right shift |
| ADD | yes | yes | yes | Register add |
| SUB | yes | yes | yes | Register subtract |
| SLL | yes | yes | yes | Register shift amount masked to 5 bits |
| SLT | yes | yes | yes | Signed less-than |
| SLTU | yes | yes | yes | Unsigned less-than |
| XOR | yes | yes | yes | Register XOR |
| SRL | yes | yes | yes | Logical right shift |
| SRA | yes | yes | yes | Arithmetic right shift |
| OR | yes | yes | yes | Register OR |
| AND | yes | yes | yes | Register AND |
| FENCE | yes | yes | yes | No-op except PC advance |
| ECALL | yes | yes | yes | Simple trap cause, no privilege entry |
| EBREAK | yes | yes | yes | Simple trap cause |

## Simplifications

- No interrupts.
- No CSRs.
- No privilege levels.
- No memory protection.
- No caches.
- No branch prediction.
- No pipelining.
- No unaligned instruction fetch.
- Misaligned halfword/word data loads and stores trap.
- `FENCE` is a no-op.
- `ECALL` and `EBREAK` halt instead of entering an exception handler.
