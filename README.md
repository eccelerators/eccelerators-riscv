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
"Eccelerators.RiscV" = "0.1.2"
```

`Eccelerators.RiscV` depends on registry package `Livt.IO` version `1.2.0` for
its UART MMIO demonstration platform. Pure local-memory examples do not require a
user application to interact with UART APIs. The UART demo uses
`LoopbackUart<64, 64>` and the scheduled `IBufferedUart` API.

Run `livt sync` after adding the dependency to resolve the published package
and its dependencies. See [CHANGELOG.md](CHANGELOG.md) for release changes.

## 🧩 Package API Shape

The supported 0.1.2 surface is intentionally small and explicit:

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
fixed-size fixtures for tests, examples, and simple integrations. Here,
“same-call completion” means a result is ready when the scheduled call returns;
it does not promise completion in one FPGA clock cycle.

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

### Ownership, Initialization, And Execution

The parent application owns the buses supplied to `Rv32iInjectedBusCore`; the
core borrows those instances and owns its execution state. Keep each bus alive
for the core's lifetime. The core and peripherals inherit the selected Livt
clock/reset context. The UART baud calculation must use the actual clock rate.

Use one controlling process to load program/data memory, reset the processor,
and call `Step()` or `Run(maxSteps)`. Do not reload shared memories or reset the
core concurrently with instruction execution. `Reset()` resets the PC, register
file, and trap state; it does not clear or reload the supplied memories. Use
`ClearProgram()`, `ClearData()`, and the loading helpers explicitly as needed.

`Step()` executes one instruction unless the core is halted. `Run(maxSteps)`
executes at most that many instruction steps and returns early on a halt.
Neither method promises a fixed cycle count or one instruction per clock.
The parent decides when the processor advances, which lets Livt control boot,
firmware provisioning, single stepping, and restart.

### Register Storage Selection

`Rv32iInjectedBusCore<REGISTER_STORAGE>` selects its register-file implementation
at compile time. Omitting the argument preserves the original `Array` default;
existing constructors and platform wrappers remain source-compatible.

| `Rv32iRegisterStorage` | Owned implementation | Intended mapping |
|---|---|---|
| `Array` | `Rv32iRegisterFile` | Original array; no specific RAM resource promised |
| `DistributedRam` | `Rv32iRamRegisterFile<MemoryStyle.Distributed>` | Synchronous RAM requesting distributed storage |
| `BlockRam` | `Rv32iRamRegisterFile<MemoryStyle.Block>` | Synchronous RAM requesting block storage |

For example, declare and construct the injected core with
`Rv32iInjectedBusCore<Rv32iRegisterStorage.DistributedRam>`. Only the selected
register-file component is constructed. All implementations satisfy
`IRv32iRegisterFile`: x0 reads zero, writes to x0/invalid indices are ignored,
invalid reads return zero, and `Reset()` zeros all 32 cells before returning.
The core invokes register reset during construction and every CPU reset.
A standalone RAM register file also requires `Reset()` before use, including
after hardware reset, because its underlying RAM retains cells across reset.

RAM-backed access is scheduled and may change instruction latency. The style
expresses implementation intent; synthesis decides the final physical resource.
In particular, synchronous distributed-style RAM may map to block RAM on a
specific FPGA/tool flow. Use implementation reports to establish actual mapping.
Select the injected core when a platform needs this configuration; the convenience
wrappers continue using the default array-backed core.

### UART Acceptance And Completion

The packaged UART platform is an **internal loopback fixture** with no external
RX/TX pins. `GetCapturedUartByte()` inspects bytes accepted for transmission;
it does not prove that a frame has finished on the serial wire. Applications
that need a physical UART provide a pin-bound bus adapter to the injected core.

The fixture has 64-byte receive/transmit queues and a 64-byte capture buffer.
A byte store to the TX register attempts to enqueue one byte. A full transmit
queue or capture buffer rejects the store and sets the bus error; the core
handles that error through its trap model. The status register reports a
snapshot of transmit queue space, not a reservation or capture-buffer space.
`GetUartAvailableBytes()` reports receive occupancy. `ReceiveUartByte()` removes
one received byte, or returns zero when empty; check occupancy to distinguish
an empty receive from a received zero byte.

`ClearData()` on the UART system clears mapped RAM, captured output, queued
UART data, and receive error counters. Clearing queued transmit data does not
truncate an active or already committed frame, so its loopback byte may still
arrive afterward. Coordinate clearing with the application's UART activity.

### ISA Simplifications

`FENCE` is a no-op except for PC advance. `ECALL` and `EBREAK` enter the
package's simple halt/trap model instead of full privileged exception handling.
Misaligned instruction fetches and unsupported memory accesses halt through the
package trap model. See [`docs/rv32i-support.md`](docs/rv32i-support.md) for
the instruction-by-instruction support matrix.

## 💡 Usage Examples

### Minimal Local-Memory System

This example loads a tiny program that writes `0x44` to data byte `0` and halts
with `EBREAK`. A parent calls `LoadProgram()` and then `Run()`; construction
only creates the owned system:

```livt
namespace Example

using Eccelerators.RiscV.Isa
using Eccelerators.RiscV.Platform

/**
 * Owns a local-memory system whose program is provisioned explicitly at runtime.
 */
component TinyRv32iExample
{
	// Owned processor, program memory, and data/peripheral fixtures.
	system: Rv32iMinimalSystem

	/**
	 * Creates the owned system; LoadProgram supplies its executable content.
	 */
	new()
	{
		this.system = new Rv32iMinimalSystem()
	}

	/**
	 * Clears program/data fixtures, resets the CPU, and loads the demonstration.
	 * Call only while the parent is not running the processor.
	 */
	public fn LoadProgram()
	{
		this.system.ClearProgram()
		this.system.ClearData()
		this.system.Reset()
		this.system.LoadInstruction(0, 0x04400093) // ADDI x1, x0, 0x44
		this.system.LoadInstruction(1, 0x00102023) // SW x1, 0(x0)
		this.system.LoadInstruction(2, 0x00100073) // EBREAK
	}

	/**
	 * Executes at most eight instructions after LoadProgram; returns on halt.
	 */
	public fn Run()
	{
		this.system.Run(8)
	}

	/**
	 * Reads data byte zero; the completed example leaves 0x44 here.
	 */
	public fn GetResult() byte
	{
		return this.system.ReadDataByte(0)
	}

	/**
	 * Reports whether execution stopped at the program's EBREAK instruction.
	 */
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

/**
 * Owns instruction memory and borrows the parent's data bus for instruction execution.
 */
component InjectedRv32iExample
{
	// Owned program fixture and execution engine.
	instructionBus: Rv32SimpleInstructionRom
	core: Rv32iInjectedBusCore<Rv32iRegisterStorage.DistributedRam>

	// Borrowed from the parent; must remain available while the core is used.
	dataBus: IRv32DataBus

	/**
	 * Creates program memory and binds the core to the parent-owned data bus.
	 */
	new(dataBus: IRv32DataBus)
	{
		this.instructionBus = new Rv32SimpleInstructionRom()
		this.dataBus = dataBus
		this.core = new Rv32iInjectedBusCore<Rv32iRegisterStorage.DistributedRam>(this.instructionBus, this.dataBus)
	}

	/**
	 * Loads one instruction at word index 0..63 while execution is stopped.
	 */
	public fn LoadInstruction(index: int, instruction: uint)
	{
		this.instructionBus.LoadInstruction(index, instruction)
	}

	/**
	 * Restarts CPU state at address zero, preserving both bus memories.
	 */
	public fn Reset()
	{
		this.core.Reset()
	}

	/**
	 * Executes at most maxSteps instructions; nonpositive bounds do no work.
	 * The parent must provision program/data content before calling this.
	 */
	public fn Run(maxSteps: int)
	{
		this.core.Run(maxSteps)
	}
}
```

### UART MMIO Platform

This example enqueues one byte by executing RV32I stores to the UART MMIO
address. A parent calls `LoadProgram()` and then `Run()`:

```livt
namespace Example

using Eccelerators.RiscV.Isa
using Eccelerators.RiscV.Platform

/**
 * Owns an internal UART-loopback system for an MMIO transmission example.
 */
component TinyUartExample
{
	// Owned processor, program memory, and data/peripheral fixtures.
	system: Rv32iUartMmioSystem

	/**
	 * Creates the owned system; LoadProgram supplies its executable content.
	 */
	new()
	{
		this.system = new Rv32iUartMmioSystem()
	}

	/**
	 * Clears program/data fixtures, resets the CPU, and loads the demonstration.
	 * Call only while the parent is not running the processor.
	 */
	public fn LoadProgram()
	{
		this.system.ClearProgram()
		this.system.ClearData()
		this.system.Reset()
		this.system.LoadInstruction(0, 0x400000b7) // LUI x1, 0x40000
		this.system.LoadInstruction(1, 0x04100113) // ADDI x2, x0, 0x41 ('A')
		this.system.LoadInstruction(2, 0x00208023) // SB x2, 0(x1)
		this.system.LoadInstruction(3, 0x00100073) // EBREAK
	}

	/**
	 * Executes at most eight instructions after LoadProgram; returns on halt.
	 */
	public fn Run()
	{
		this.system.Run(8)
	}

	/**
	 * Reads the first accepted TX byte; this does not wait for wire completion.
	 */
	public fn GetFirstByte() byte
	{
		return this.system.GetCapturedUartByte(0)
	}

	/**
	 * Reports whether execution stopped at the program's EBREAK instruction.
	 */
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

For a fresh build, use the supported cleanup command:

```sh
livt clean
livt test
```

Release validation on 2026-10-20: **67 tests passed, zero failed or skipped**,
using registry dependency `Livt.IO 1.2.0`. All three README examples also
compiled and passed behavior checks in an isolated consumer project. Coverage
includes the instruction
matrices, bus/platform integrations, and physical UART serialization through
the simulated loopback receiver, including a zero byte. These are simulation
results; FPGA resource use, maximum clock frequency, and board behavior require
separate measurements of the consuming design.

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

The default register file and simple memory fixtures use arrays. Explicit RAM
register storage is available on the injected core; final physical mapping
remains a synthesis result. Choose explicit memory
components in application-owned buses where storage mapping is a requirement,
and check synthesis reports for the resulting hardware.

## 🚀 Outlook

Future work should add wait-state-aware bus timing and broader platform bus
adapters. The package may also split optional `Livt.IO` platform integrations
into a companion package if users need a dependency-light core package.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
