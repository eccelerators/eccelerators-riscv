# Core selection

The six [preset declarations](../src/Presets) expose these structural parameters:

| Parameter | Default | Meaning |
|---|---|---|
| `MULTIPLIER` | required on Zmmul presets | `Rv32IterativeMultiplier` or `Rv32DspMultiplier` |
| `RESET_PC` | `0` | Four-byte-aligned reset and restart address |
| `REGISTER_FILE_STYLE` | `MemoryStyle.Block` | Register-file storage mapping request |

The base presets implement RV32I. Zmmul presets add MUL, MULH, MULHSU and MULHU.
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

## Multiplication

`Rv32IterativeMultiplier` avoids DSP requirements. `Rv32DspMultiplier` decomposes
operands for DSP-oriented arithmetic and implements the same operation/result
contract with different latency. Engines stall on the completion port, so choosing
a provider does not change instruction semantics. Mapping still depends on the
FPGA and synthesis tools; a DSP choice is not an area or frequency guarantee.

Zmmul is not the full M extension: DIV, DIVU, REM and REMU remain illegal and
`misa.M` remains zero. Compile software for the actual selected extensions.

## Software and fault policy

Use the `ilp32` ABI and initialize stack, data and BSS according to the application's
linker map. Instructions are fixed-width, little-endian RV32; instruction addresses
are four-byte aligned. Misaligned halfword/word accesses fault. Loads into x0 still
perform memory access checks and any permitted device read.

FENCE is ordered by the drained/ordered memory path. FENCE.I is unsupported.
Base and non-machine Zmmul presets stop diagnostically on faults, ECALL and EBREAK.
Machine presets instead enter the handler described in [machine support](machine.md).
Restart is required to leave a diagnostic halt.

Performance depends on dependencies, branches, multiplier choice and memory
response latency. Synchronous register storage has a clock edge of read latency
for every requested style. A different storage hint does not remove it. Qualify
resource use and routed timing for the complete application and target device.
