# Core selection

The [preset declarations](../src/Presets) expose these structural parameters:

| Parameter | Default | Meaning |
|---|---|---|
| `MULTIPLIER` | required on Zmmul presets | `Rv32IterativeMultiplier` or `Rv32DspMultiplier` |
| `DIVIDER` | required on full-M presets | A provider such as `Rv32IterativeDivider` |
| `RESET_PC` | `0` | Reset and restart address satisfying the selected instruction alignment |
| `REGISTER_FILE_STYLE` | `MemoryStyle.Block` | Register-file storage mapping request |
| `INSTRUCTION_ALIGNMENT` | `RvInstructionAlignment.Word` | Architectural word or halfword PC alignment |
| `INSTRUCTIONS` | `Rv32WordInstructionFetch` | Framing provider over the physical fetch port |

The base presets implement RV32I. RV32E presets use the same execution contracts
with sixteen architectural registers and reject instructions naming x16 through
x31. Zmmul presets add MUL, MULH, MULHSU and MULHU. Full-M presets add DIV, DIVU,
REM and REMU. Bit-manipulation presets combine Zba, Zbb and Zbs through typed
decoder and integer-unit overlays. Zifencei presets add ordered instruction-fetch
synchronization.
RV32IC presets select `RvInstructionAlignment.Halfword` and
`Rv32cInstructionFetch`. The front end expands supported compressed integer
instructions into canonical RV32I words, while preserving their original
encoding and two-byte length for traps and retirement.
Machine presets additionally select Zicsr, machine exceptions, MRET and both
same-clock `timerPending` and `externalPending` inputs. Named machine presets use
hart ID zero; use explicit composition for another hart ID or CSR provider.
The multiplier is required explicitly because Livt 1.2.0 cannot currently use a
component type as a default generic value. The choice is still structural and
does not produce runtime selection logic.

## Sequential execution

`Rv32SequentialEngine` executes one instruction at a time. Its single-port register
bank reads operands on successive edges. Decode and integer arithmetic are
combinational; memory and multiplication wait for their explicit completion
protocols. The engine commits each successful instruction once.

There is no bypass network or speculative data access. Pause completes the current
instruction before becoming idle. This is a useful starting point when area and
simple integration matter more than overlapping instruction execution.

## Pipeline execution

`Rv32PipelineEngine` overlaps four logical stages: fetch, decode/register read,
execute, and memory/commit. Each stage keeps its payload stable while stalled.
The register bank duplicates storage for two simultaneous reads and broadcasts
writes to both copies.

Decode waits on older matching destinations. Same-edge register write/read
collisions explicitly forward the new value; there is no general execute-to-execute
bypass network. x0 and unused encoded source fields do not cause dependencies.

Only commit issues data transactions. Redirects and faults discard younger stages
and drain uncancellable instruction fetches. Instruction storage must therefore
be safe to read speculatively. A discarded fetch error has no architectural effect.
Pause drains admitted instructions, so several instructions may retire after run
is lowered.

Machine pipeline execution serializes CSR access and trap/interrupt boundaries.
An older synchronous fault takes priority over a pending interrupt. Multiplier
results and younger fetch responses must drain or be discarded before control
completion; they cannot produce a later stale retirement.

## Multiplication and division

`Rv32IterativeMultiplier` avoids DSP requirements. `Rv32DspMultiplier` decomposes
operands for DSP-oriented arithmetic and implements the same operation/result
contract with different latency. Engines stall on the completion port, so choosing
a provider does not change instruction semantics. Mapping still depends on the
FPGA and synthesis tools; a DSP choice is not an area or frequency guarantee.

`Rv32IterativeDivider` implements compact radix-2 division with the architectural
division-by-zero and signed-overflow results. `Rv32MUnit` composes multiplier and
divider providers behind `IRv32MPort`. Zmmul still leaves division illegal and
does not report full M. Compile software for the actual selected extensions.

## Software and fault policy

Use the `ilp32` ABI and initialize stack, data and BSS according to the application's
linker map. Instructions are little-endian RV32. Presets without C require
four-byte-aligned instruction addresses. RV32IC presets admit mixed 16-bit and
32-bit instructions on two-byte boundaries. Misaligned data halfword/word accesses
still fault. Loads into x0 still perform memory access checks and any permitted
device read.

FENCE is ordered by the drained/ordered memory path. Zifencei presets issue the
fetch synchronization handshake after older data effects complete and resume only
after the provider acknowledges it. Pipeline execution also invalidates younger
prefetched instructions. Other presets keep FENCE.I illegal.
Base and non-machine Zmmul presets stop diagnostically on faults, ECALL and EBREAK.
Machine presets instead enter the handler described in [machine support](machine.md).
Restart is required to leave a diagnostic halt.

Performance depends on dependencies, branches, multiplier choice and memory
response latency. Synchronous register storage has a clock edge of read latency
for every requested style. A different storage hint does not remove it. Qualify
resource use and routed timing for the complete application and target device.
