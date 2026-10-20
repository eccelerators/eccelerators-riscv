# Testing

Run all package tests with:

```sh
livt test
```

The current suite covers:

- RV32I constants and field extraction.
- I/S/B/U/J immediate decoding.
- Register file `x0` behavior.
- ALU, branch, and load/store helpers.
- Control decoding for representative legal and illegal instructions.
- Simple instruction ROM and data RAM bus fixture behavior.
- Minimal system and local-memory reference-wrapper execution.
- Full RV32I decode and core instruction matrices.
- Full `Rv32iBusCore` wrapper integration through synchronous ROM/RAM fixtures
  and package API examples.
- Canonical `Rv32iInjectedBusCore` execution with a caller-owned test data bus,
  pre-bus alignment traps, and a full instruction-surface matrix using simple
  bus fixtures.
- Compact programs running through `Rv32iReferenceCore`.
- UART MMIO hello-world execution through `Rv32iUartMmioSystem`.

The Livt.IO 1.2.0 migration was validated on 2026-10-20: 62 tests passed,
zero failed or skipped. The UART regression also checks serial loopback delivery
of two bytes (including zero), receive occupancy, and empty-receive behavior.

The three README examples were also extracted into an isolated consumer project
and checked for their documented local-memory, UART enqueue, and borrowed-bus
behavior: three passed, zero failed or skipped.
