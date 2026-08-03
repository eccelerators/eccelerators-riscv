# Firmware

The first firmware flow targets freestanding RV32I programs. Normal package
tests do not require a local RISC-V toolchain; the commands here are for humans
or optional integration checks.

## Toolchain

Use a bare-metal RISC-V toolchain that supports RV32I:

```sh
riscv32-unknown-elf-gcc \
  -march=rv32i \
  -mabi=ilp32 \
  -ffreestanding \
  -nostdlib \
  -T linker.ld \
  start.S main.c \
  -o firmware.elf
```

Avoid standard library calls unless a runtime is explicitly provided. Plain
RV32I has no multiply/divide extension, so avoid C expressions likely to pull in
unsupported helper routines.

See the [firmware-to-ROM workflow](../tools/firmware-to-livt-rom.md) for the
optional ELF inspection, binary extraction, and Livt ROM-loading steps.

## Memory Model

Mapped platform memory-map convention:

| Address | Purpose |
|---|---|
| `0x0000_0000` | reset vector and program ROM |
| `0x0001_0000` | data RAM |
| `0x4000_0000` | UART TX MMIO byte register |
| `0x4000_0004` | UART status MMIO word register |

The packaged UART platform provides 256 bytes of ROM and 256 bytes of RAM. Its
RAM occupies `0x0001_0000` through `0x0001_00ff`; the initial stack pointer is
the first address above that range, so the stack grows downward into RAM. The
counter linker script reserves 64 bytes at the top of RAM for that stack.

`Rv32iMinimalSystem` and `Rv32iReferenceCore` use zero-based instruction and
data helper methods instead. Use mapped platform wrappers for firmware that
expects RAM at `0x0001_0000` or MMIO at `0x4000_0000`.

## Minimal Program Shape

The checked-in `examples/counter` program targets the mapped UART platform path:
it writes increasing byte values to `0x4000_0000`, which
`Rv32iUartMmioSystem` maps to UART transmit. Use generated instruction words or
a ROM initializer derived from the ELF/binary output. The UART address is a
compile-time constant, so the example has no initialized `.data` to copy from
ROM into RAM.

Startup code must:

- define `_start` at the reset vector;
- initialize the stack pointer;
- call `main`;
- end with `ebreak` so the reference core halts with a visible trap cause.

The minimal startup does not initialize `.data` or clear `.bss`. The example
linker script rejects initialized `.data`; extend both startup and the linker
layout together before adding initialized global or static variables.

## UART Hello World Shape

The `Rv32iUartMmioSystem` test uses a hand-encoded ROM program equivalent to:

```asm
    lui  x1, 0x40000
    addi x2, x0, 'H'
    sb   x2, 0(x1)
    addi x2, x0, 'e'
    sb   x2, 0(x1)
    addi x2, x0, 'l'
    sb   x2, 0(x1)
    addi x2, x0, 'l'
    sb   x2, 0(x1)
    addi x2, x0, 'o'
    sb   x2, 0(x1)
    addi x2, x0, 10
    sb   x2, 0(x1)
    ebreak
```

The processor only executes normal RV32I instructions through `Rv32iBusCore`.
The UART behavior appears because the platform data bus maps byte stores at
`0x4000_0000` to `Livt.IO.Uart.Transmit`.
