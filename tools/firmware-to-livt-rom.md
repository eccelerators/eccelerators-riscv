# Firmware To Livt ROM

This document describes a manual ROM conversion flow for optional firmware
experiments. Normal `livt test` does not depend on these tools.

See the package [firmware notes](../docs/firmware.md) for the supported RV32I
toolchain assumptions, memory model, and startup requirements.

## Build ELF

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

## Inspect And Extract

```sh
riscv32-unknown-elf-objdump -d firmware.elf > firmware.disasm
riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin
riscv32-unknown-elf-size firmware.elf
wc -c firmware.bin
```

The checked-in counter linker script limits ROM and RAM to the platform's
256-byte regions and fails the link if either region overflows. It also requires
`.data` to remain empty because the minimal startup does not copy initialized
data into RAM. With that layout, `firmware.bin` contains only the contiguous ROM
image; it must not exceed 256 bytes.

RV32I instruction memory is little-endian. Convert each group of four bytes into
a 32-bit instruction word before loading `Rv32SimpleInstructionRom` or
`Rv32iUartMmioSystem`. The mapped counter firmware targets the UART system, not
the zero-based `Rv32iMinimalSystem` data-memory model.

Example byte order:

```text
binary bytes: 93 00 40 04
Livt word:    0x04400093
```

Then load words in order:

```livt
system.LoadInstruction(0, 0x04400093)
system.LoadInstruction(1, 0x00100073)
```

Keep generated ROM words checked in when they are part of tests, so normal tests
do not require the external toolchain.
