# Eccelerators.RiscV

`Eccelerators.RiscV` provides reusable RV32I processor components for Livt
hardware-oriented projects. It combines ISA helpers, execution primitives,
reference cores, small memory fixtures, and compact platform wrappers so
applications can start with a simple RV32I system and grow toward mapped
bus/MMIO composition.

> 🧪 **A Livt and Livt Agents experiment**
>
> This repository is part of a broader series of experiments exploring how far
> hardware IP development can be taken with Livt and Livt Agents. It brings
> together IP blocks of different scale and complexity—from instruction decoders
> and arithmetic units to processor cores, bus interfaces, memories, and a
> UART-MMIO platform. The result is both a reusable RV32I package and a concrete,
> inspectable example of how substantial hardware-oriented systems can be
> designed, composed, tested, and documented with Livt-assisted workflows.

The package targets RV32I only. It intentionally excludes M/C/A/F/D/V
extensions, CSRs, interrupts, privilege modes, caches, MMU, debug support, and
pipelining.

## 🗺️ Where This Project Fits

RISC-V is a modular instruction-set family rather than one fixed processor
design. In `RV32I`, `RV` identifies RISC-V, `32` selects 32-bit integer
registers and addresses, and `I` identifies the standard base integer
instruction set.

A simplified view of the family is:

```text
RV32E                    reduced embedded base with 16 integer registers
  ↓
RV32I                    standard 32-bit integer base  ← this project
  ↓ add extensions such as M and C
RV32IMC                  multiply/divide and compressed instructions
  ↓ add CSRs, interrupts, privilege support, and platform infrastructure
Embedded RISC-V system
  ↓ add supervisor mode, virtual memory, and richer hardware
Application-class RISC-V system
```

This project is a compact, step-driven RV32I reference implementation. It
focuses on clear instruction behavior, reusable components, and approachable
examples rather than minimum hardware area, cycle-accurate microarchitecture,
or a production-ready RISC-V platform. Its documented simplifications and the
instruction-by-instruction support matrix are available in
[`docs/rv32i-support.md`](docs/rv32i-support.md).

## 📦 Package

```toml
[dependencies]
"Eccelerators.RiscV" = "0.1.0"
```

`Eccelerators.RiscV` currently depends on `Livt.IO` because the package ships a
UART MMIO demonstration platform. Pure local-memory examples do not require a
user application to interact with UART APIs.

## 🧩 Package API Shape

The supported 0.1.0 surface is intentionally small and explicit:

- `Eccelerators.RiscV.Isa`: RV32I constants, instruction field extraction,
  immediate decoding, control decoding, and word helpers.
- `Eccelerators.RiscV.Core.Rv32iReferenceCore`: full RV32I local-memory
  reference core.
- `Eccelerators.RiscV.Core.Rv32iBusCore`: convenience wrapper that composes the
  canonical execution engine with the package's synchronous ROM/RAM fixtures.
- `Eccelerators.RiscV.Core.Rv32iInjectedBusCore`: canonical full RV32I execution
  engine; it receives `IRv32InstructionBus` and `IRv32DataBus` implementations
  through its constructor.
- `Eccelerators.RiscV.Platform.Rv32iMinimalSystem`: recommended first wrapper
  with zero-based local program/data helper memories.
- `Eccelerators.RiscV.Platform.Rv32iUartMmioSystem`: UART/MMIO demonstration
  platform that composes the canonical core with mapped RAM/UART buses.
- `Eccelerators.RiscV.Bus.IRv32InstructionBus` and `IRv32DataBus`: package bus
  contracts for fetch and data access.
- `Eccelerators.RiscV.Bus.Rv32SimpleInstructionRom` and
  `Rv32SimpleDataRam`: synchronous ROM/RAM fixtures.
- `Eccelerators.RiscV.Bus.Rv32UartMmioDataBus`: demo data bus that maps RAM and
  a tiny UART transmit/status MMIO window.

## 📚 Namespaces

| Namespace | Purpose |
|---|---|
| `Eccelerators.RiscV.Isa` | RV32I constants, field extraction, immediates, decoding, and word helpers |
| `Eccelerators.RiscV.Core` | Register file, ALU, branch/load-store/trap helpers, and core implementations |
| `Eccelerators.RiscV.Bus` | RISC-V bus contracts, simple ROM/RAM fixtures, and demo MMIO adapters |
| `Eccelerators.RiscV.Platform` | Minimal systems and parent-application composition roots |

## 🧭 API Overview

### Canonical Core And Reference Wrapper

`Rv32iInjectedBusCore` is the single full RV32I execution engine. It owns the
register file, PC, decoding, ALU, branch, trap, and instruction-step behavior;
parent components supply instruction and data buses through its constructor.

`Rv32iBusCore` adds the package's simple ROM/RAM fixtures, while
`Rv32iReferenceCore` provides the step-driven local-memory reference API. Both
delegate instruction execution to `Rv32iInjectedBusCore`, preventing behavior
from drifting between core variants.

`Rv32iMinimalSystem` is the recommended first entry point. It exposes friendly
setup, run, and inspection helpers with local zero-based memories:

- `PROGRAM_WORDS = 64`
- `DATA_BYTES = 256`
- instruction indexes `0..63`
- data byte addresses `0..255`

It does not apply the mapped RAM/MMIO addresses used by the UART platform.

### Bus And Platform Fixtures

`IRv32InstructionBus` and `IRv32DataBus` define synchronous, same-call completion
contracts: requests finish before their methods return, after which result and
error state can be read. `Rv32SimpleInstructionRom` and `Rv32SimpleDataRam` are
fixed-size fixtures for tests, examples, and simple integrations.

`Rv32iBusCore` provides convenient program/data setup and inspection around an
`Rv32iInjectedBusCore` connected to the simple ROM/RAM fixtures.

`Rv32iInjectedBusCore` is the full RV32I reusable bus-contract variant. A parent
component owns the instruction and data buses, passes them into the constructor,
and then uses the same run, step, register, PC, and trap inspection API.

`Rv32iUartMmioSystem` demonstrates platform-controlled peripherals by connecting
the same canonical core to an instruction ROM and mapped RAM/UART data bus. It
maps:

| Address | Purpose |
|---|---|
| `0x0000_0000` | program ROM |
| `0x0001_0000` | data RAM base |
| `0x4000_0000` | UART TX byte register |
| `0x4000_0004` | UART status word register |

The UART system is compact in platform scope only: it provides a small fixed
memory map and one UART peripheral while retaining the full RV32I instruction
surface of `Rv32iInjectedBusCore`.

The processor still executes ordinary RV32I instructions. UART behavior appears
because byte stores to `0x4000_0000` are interpreted by the platform data bus.
For test setup and inspection, `Rv32iUartMmioSystem` provides mapped helpers
such as `LoadMappedDataByte` and `ReadMappedDataByte` in addition to raw RAM
offset helpers.

### ISA Simplifications

`FENCE` is a no-op except for PC advance. `ECALL` and `EBREAK` enter the
package's simple halt/trap model instead of full privileged exception handling.
Misaligned instruction fetches and unsupported memory accesses halt through the
package trap model. See [`docs/rv32i-support.md`](docs/rv32i-support.md) for
the instruction-by-instruction support matrix.

## 💡 Usage Examples

### Minimal Local-Memory System

This example loads a tiny program that writes `0x44` to data byte `0` and halts
with `EBREAK`:

```livt
namespace Example

using Eccelerators.RiscV.Isa
using Eccelerators.RiscV.Platform

component TinyRv32iExample
{
    system: Rv32iMinimalSystem

    new()
    {
        this.system = new Rv32iMinimalSystem()
        this.system.LoadInstruction(0, 0x04400093) // ADDI x1, x0, 0x44
        this.system.LoadInstruction(1, 0x00102023) // SW x1, 0(x0)
        this.system.LoadInstruction(2, 0x00100073) // EBREAK
    }

    public fn Run()
    {
        this.system.Run(8)
    }

    public fn GetResult() byte
    {
        return this.system.ReadDataByte(0)
    }

    public fn HaltedOnEbreak() bool
    {
        return this.system.GetTrapCause() == Rv32iConstants.TRAP_EBREAK
    }
}
```

### Reusable Bus-Injected Core

This example shows the advanced composition path: the parent owns the bus
components and passes them into the core constructor. A real system can provide
its own implementations of `IRv32InstructionBus` and `IRv32DataBus`.

```livt
namespace Example

using Eccelerators.RiscV.Bus
using Eccelerators.RiscV.Core

component InjectedRv32iExample
{
    instructionBus: Rv32SimpleInstructionRom
    dataBus: IRv32DataBus
    core: Rv32iInjectedBusCore

    new(dataBus: IRv32DataBus)
    {
        this.instructionBus = new Rv32SimpleInstructionRom()
        this.dataBus = dataBus
        this.core = new Rv32iInjectedBusCore(this.instructionBus, this.dataBus)
    }

    public fn Run(maxSteps: int)
    {
        this.core.Run(maxSteps)
    }
}
```

### UART MMIO Platform

This example sends one byte by executing RV32I stores to the UART MMIO address:

```livt
namespace Example

using Eccelerators.RiscV.Isa
using Eccelerators.RiscV.Platform

component TinyUartExample
{
    system: Rv32iUartMmioSystem

    new()
    {
        this.system = new Rv32iUartMmioSystem()
        this.system.LoadInstruction(0, 0x400000b7) // LUI x1, 0x40000
        this.system.LoadInstruction(1, 0x04100113) // ADDI x2, x0, 0x41 ('A')
        this.system.LoadInstruction(2, 0x00208023) // SB x2, 0(x1)
        this.system.LoadInstruction(3, 0x00100073) // EBREAK
    }

    public fn Run()
    {
        this.system.Run(8)
    }

    public fn GetFirstByte() byte
    {
        return this.system.GetCapturedUartByte(0)
    }

    public fn HaltedOnEbreak() bool
    {
        return this.system.GetTrapCause() == Rv32iConstants.TRAP_EBREAK
    }
}
```

Longer firmware notes and the checked-in counter example live in
[`docs/firmware.md`](docs/firmware.md) and [`examples/counter`](examples/counter).
Memory-map details live in [`docs/memory-map.md`](docs/memory-map.md).

## 🗂️ Layout

```text
src/Isa/        RV32I constants, decoding, immediates, and word helpers
src/Core/       execution primitives and core implementations
src/Bus/        bus contracts, simple memories, and demo MMIO adapters
src/Platform/   minimal systems and composition roots
tests/          package tests in Eccelerators.RiscV.Tests
docs/           architecture, memory-map, firmware, support, and testing notes
examples/       freestanding firmware examples
tools/          firmware-to-ROM guidance
```

## 🧪 Build and Test

Run the configured test components:

```sh
livt test
```

To force a clean regeneration without removing dependencies:

```sh
rm -rf out .livt/src.json .livt/ghdl
livt test
```

Do not use `livt clean` for the package release flow.

Additional notes:

- [Architecture](docs/architecture.md)
- [Memory models and mapped platform convention](docs/memory-map.md)
- [RV32I support matrix](docs/rv32i-support.md)
- [Firmware notes](docs/firmware.md)
- [Firmware-to-ROM workflow](tools/firmware-to-livt-rom.md)
- [Hardware notes](docs/hardware-notes.md)
- [Testing](docs/testing.md)

## 📝 Development Notes

- Keep public components under `namespace Eccelerators.RiscV`.
- Keep reusable ISA/core behavior in `Isa` and `Core`.
- Keep mapped RAM/MMIO behavior in bus-facing `Platform` components.
- Keep tests in `namespace Eccelerators.RiscV.Tests`.
- Prefer `Rv32iInjectedBusCore` when a parent system owns the bus implementations.
- Keep `Rv32iMinimalSystem` as the stable zero-based local-memory wrapper.
- Treat `Rv32UartMmioDataBus` as a demo MMIO fixture until a parent application
  supplies its own mapped bus.

## 🚀 Outlook

Future work should add wait-state-aware bus timing and broader platform bus
adapters. The package may also split optional `Livt.IO` platform integrations
into a companion package if users need a dependency-light core package.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
