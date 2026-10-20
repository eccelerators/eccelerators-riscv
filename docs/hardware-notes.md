# Hardware Notes

`Eccelerators.RiscV` currently provides readable RV32I reference components, not
an optimized soft CPU.

## Core Style

- `Rv32iInjectedBusCore` is the canonical full RV32I execution engine for parent
  systems that own their instruction and data bus implementations.
- `Rv32iBusCore` composes that engine with the package's synchronous simple
  ROM/RAM fixtures.
- `Rv32iReferenceCore` provides the step-driven local-memory reference API for
  tests, education, and early composition.
- `Rv32iMinimalSystem` is the recommended first entry point for parent
  applications that want a convenient zero-based local-memory wrapper.
- `Rv32iUartMmioSystem` is compact in mapped-platform scope but composes the full
  `Rv32iInjectedBusCore` with mapped RAM/UART buses. It exists to show MMIO
  composition with `Livt.IO.LoopbackUart<64, 64>`, not to define a reduced instruction subset.

## Timing And Latency

- The simple ROM/RAM fixtures are synchronous: request/load/store completes
  in the same Livt function call.
- `Rv32iMinimalSystem` exposes 64 local program words and 256 local data bytes.
- `Run(maxSteps)` executes bounded instruction steps for simulation and tests.
- The current design does not model wait states, arbitration, caches, branch
  prediction, pipelining, interrupts, or privilege transitions.

## Reset And Trap Behavior

- Reset sets `pc` to `0x0000_0000`, clears the register file, and clears trap
  state.
- Register `x0` always reads as zero and ignores writes.
- `FENCE` acts as a no-op except for PC advance.
- `ECALL` and `EBREAK` halt through the package's simple trap model.
- Misaligned `JAL`, `JALR`, and taken-branch targets trap on the originating
  instruction before the PC or link register is updated.
- Misaligned instruction fetch and halfword/word data access trap before an
  instruction or data bus request is issued. Range and MMIO mapping failures
  report a bus error.

## Synthesis Notes

- The first core prioritizes reviewability and testability over area, frequency,
  or latency.
- The current synchronous bus fixtures are intended for tests,
  examples, and simple integrations. Add explicit bus components when a design
  needs wait states, arbitration, or external memory timing.

## Future Optimization Path

- Consider moving optional platform integrations that depend on `Livt.IO` into a
  companion package if package consumers need a dependency-light core package.
- Add wait-state-aware bus timing once real external memory integrations need it.
- Add a separate pipelined core only after the RV32I reference behavior remains
  fully green.

## Register Storage (0.1.2)

The injected core accepts `Rv32iRegisterStorage.Array` (default),
`DistributedRam`, or `BlockRam` as a compile-time parameter. The RAM-backed
implementations explicitly clear all registers on CPU reset and complete reads
and writes before returning. Their timing may differ from array access.
Physical resource mapping must be checked for the selected FPGA and tool flow.
