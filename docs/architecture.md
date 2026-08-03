# Eccelerators.RiscV Architecture

The package is split into four layers.

`Eccelerators.RiscV.Isa` contains stateless RV32I semantics: constants,
instruction-field extraction, immediate decoding, and control decoding.

`Eccelerators.RiscV.Core` contains reusable execution primitives and the
constructor-injected `Rv32iInjectedBusCore`. It is the canonical execution
engine and is written for readability and tests first. It is not a pipelined or
optimized soft CPU. `Rv32iControlDecoder` is its source of instruction legality,
instruction class, branch/load/store kind, and ALU operation.

`Eccelerators.RiscV.Bus` contains instruction/data bus contracts and
RISC-V-specific test memory adapters.

`Eccelerators.RiscV.Platform` contains composition roots such as minimal systems,
memory-map glue, MMIO bridges, and firmware loading examples.

## Core Composition

`Rv32iInjectedBusCore` owns all architectural execution state and behavior:
registers, PC, decode, ALU and branch dispatch, load/store requests, and traps.
It receives `IRv32InstructionBus` and `IRv32DataBus` components through its
constructor. Other package cores and systems compose this engine instead of
implementing their own instruction dispatch.

`Rv32iBusCore` connects the canonical engine to `Rv32SimpleInstructionRom` and
`Rv32SimpleDataRam`. It adds simulation-friendly zero-based instruction and data
helpers without duplicating ISA behavior.

`Rv32iReferenceCore` provides the established step-driven reference API over
`Rv32iBusCore`. It remains the full RV32I local-memory behavior baseline.

`Rv32iMinimalSystem` is a thin platform wrapper around the reference core's local
program and data memories. It preserves the core's setup and inspection API with
zero-based storage: 64 instruction words and 256 data bytes. It is not a mapped
MMIO platform.

`Rv32iUartMmioSystem` is a compact platform demonstration that connects
`Rv32iInjectedBusCore` directly to a simple instruction ROM and the mapped
`Rv32UartMmioDataBus`. Compact refers to its fixed memory map and small
peripheral set, not to a reduced instruction subset. It keeps the core
instruction flow ordinary while binding the `0x4000_0000` MMIO address to a
`Livt.IO.Uart` transmit register. This shows the intended composition model:
parent applications change system behavior by choosing data-bus and MMIO
components, not by changing the execution engine or ISA primitives.

The injected-bus tests verify caller-owned bus composition and the full RV32I
instruction surface. Reference, simple-bus, and UART platform tests then verify
the corresponding wrapper and bus integration behavior.

## Bus Timing Assumptions

The initial bus fixtures use same-call completion:

- `Request`, `Load`, and `Store` finish synchronously before returning.
- Result data and error state are valid immediately after the method returns.
- `HasError()` reports range or alignment errors for the most recent operation.
- A new request/load/store clears the previous error before evaluating the new
  operation.
- `GetInstruction()` and `GetReadData()` return zero after an error.
- The UART MMIO demo accepts `SB` writes to `0x4000_0000` synchronously and
  exposes transmit-ready status through a word load from `0x4000_0004`.

The core uses a minimal trap model:

| Cause | Meaning |
|---|---|
| 0 | none |
| 1 | illegal instruction |
| 2 | ecall |
| 3 | ebreak |
| 4 | instruction misaligned |
| 5 | load/store misaligned |
| 6 | bus or memory range error |

This is not full privileged exception handling.
