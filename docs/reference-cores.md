# Scheduled reference cores

The `Core` and `Bus` namespaces retain the original scheduled RV32I API for small
tests and reference systems. It is separate from the sequential/pipeline signal
engines and has different timing and fault semantics.

| Component | Purpose |
|---|---|
| `Rv32iInjectedBusCore` | Execution with caller-owned `IRv32InstructionBus` and `IRv32DataBus` |
| `Rv32iBusCore` | Injected core plus synchronous ROM/RAM fixtures |
| `Rv32iReferenceCore` | Local-memory, step-driven reference wrapper |
| `Rv32iMinimalSystem` | 64 program words and 256 data bytes, zero-based helper addresses |
| `Rv32iUartMmioSystem` | Mapped RAM and internal UART loopback fixture |

One controlling process provisions memory, resets the core, and calls `Step()` or
`Run(maxSteps)`. A scheduled call completes before its result is consumed, but
this does not promise a single FPGA clock cycle. Run returns early on a halt.
Reset clears CPU state, not external program/data memories. Do not mutate shared
memory concurrently with execution.

The UART fixture maps program ROM at 0, data RAM at 0x00010000, UART transmit at
0x40000000 and status at 0x40000004. It has no external RX/TX pins. Its 64-byte
queues and capture buffer are bounded; a rejected transmit store faults. Captured
bytes indicate acceptance, not completion on the serial wire. `ClearData()`
clears queues/capture and receive errors but cannot retract a committed frame.
The minimal local-memory system does not use this mapped data address space.

`Rv32iInjectedBusCore<REGISTER_STORAGE>` accepts `Rv32iRegisterStorage.Array`,
`DistributedRam` or `BlockRam`; Array is its default. This older selection is
separate from the newer presets' `REGISTER_FILE_STYLE`. RAM register files require
reset before use, implement x0, and preserve their scheduled access contract.
A storage hint does not promise a particular physical mapping.

These reference cores implement base integer operations, branches/jumps, loads,
stores and FENCE. ECALL/EBREAK halt through their simple diagnostic trap model;
they do not enter a machine handler. Misalignment and unsupported instructions
fault. CSR, multiplication and interrupt support are provided by the newer
[core compositions](cores.md), not by these wrappers.
