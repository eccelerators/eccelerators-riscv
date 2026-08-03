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
