# Memory Models

## Local Minimal System

`Rv32iMinimalSystem` is a convenience wrapper around the full RV32I reference
core. Its helper API uses local zero-based memory:

| Local Index Or Address | Purpose |
|---|---|
| instruction index `0` - `63` | 64 local program words |
| data byte address `0` - `255` | 256 local data bytes |

This wrapper is meant for tests, examples, and first integrations. It does not
decode `0x0001_0000` as RAM or `0x4000_0000` as MMIO.

## Mapped Platform Convention

Bus-facing platform components use this package memory-map convention:

| Address Range | Purpose |
|---|---|
| `0x0000_0000` - `0x0000_00ff` | program ROM |
| `0x0001_0000` - `0x0001_00ff` | data RAM |
| `0x4000_0000` | UART TX data register |
| `0x4000_0004` | UART status register |
| `0x4000_0008` and above | reserved MMIO region |

Mapped platform code should preserve the map above unless a parent application
documents a different one.

## UART MMIO Demo

`Rv32iUartMmioSystem` demonstrates that peripherals are selected by the platform
memory map, not by changing the RV32I instruction semantics. It runs
`Rv32iInjectedBusCore` with `Rv32UartMmioDataBus`. Firmware writes a byte to
`0x4000_0000` with `SB` to queue one UART transmit byte. A word load from
`0x4000_0004` returns `1` when transmit space is available and `0` otherwise.

Only byte stores are accepted by the UART TX register in this package demo.
Data-bus widths must be one, two, or four bytes. Other widths and unmapped MMIO
addresses report a bus error without modifying RAM or MMIO state.

The UART system exposes both raw fixture-offset helpers and mapped helpers for
test setup and inspection. Use `LoadMappedDataByte` and `ReadMappedDataByte`
when working with documented addresses such as `0x0001_0000`.
