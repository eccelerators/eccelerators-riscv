# Eccelerators.RiscV

Composable RISC-V processors for FPGA applications written in Livt. Start with a
named core, or construct an engine and its providers explicitly. Both approaches
use the same reusable components; resource choices are compile-time parameters.

Reusable signal contracts are in `Eccelerators.RiscV.Core`; standard instruction
encodings, semantics, decoders and execution providers are in
`Eccelerators.RiscV.Isa`. `Rv32SequentialEngine` and `Rv32PipelineEngine` consume
the same narrow provider interfaces, so explicit compositions can substitute
cohesive providers while the engines retain architectural commit.

Version **0.3.0** removes the scheduled reference layer and uses separate
instruction-fetch and load/store ports with a system-level composition,
retaining the sequential and pipeline core presets. See the
[release notes](CHANGELOG.md#030---2026-11-08) for migration guidance.

## Choose a core

All presets are in `Eccelerators.RiscV.Presets` and borrow separate instruction
and data providers implementing `flip IRv32FetchPort` and
`flip IRv32LoadStorePort`, respectively.

| Features | Sequential engine | Pipeline engine |
|---|---|---|
| RV32I | `Rv32iSequentialCore` | `Rv32iPipelineCore` |
| RV32I + Zmmul | `Rv32iZmmulSequentialCore` | `Rv32iZmmulPipelineCore` |
| RV32I + Zmmul + Zicsr, machine traps and interrupts | `Rv32iZmmulSequentialMachineCore` | `Rv32iZmmulPipelineMachineCore` |

The sequential engine favors a compact implementation. The pipeline overlaps
fetch, decode/read, execution and commit. Both use synchronous register files;
`REGISTER_FILE_STYLE` defaults to `MemoryStyle.Block`. Every Zmmul preset takes an
explicit multiplier provider type, either `Rv32IterativeMultiplier` or
`Rv32DspMultiplier`. The type is selected during elaboration and adds no runtime
dispatch or unused multiplier.

For example, these constructor fragments select a base sequential core or a
machine pipeline with DSP multiplication:

```livt
core = new Rv32iSequentialCore(instructions, data)
```

```livt
core = new Rv32iZmmulPipelineMachineCore<
	Rv32DspMultiplier,
	0,
	MemoryStyle.Block
>(instructions, data)
```

For a custom ISA composition, use `Rv32SequentialCore` or `Rv32PipelineCore` with
constrained provider types. These thin specializations inherit `Rv32Core` and bind
the appropriate engine and register-port contract without adding hardware or
duplicating its implementation. Use `Rv32Core` directly when defining another
engine architecture. `IRv32CustomInstructionPort` supports bounded, result-only
custom instructions with variable latency and synchronous faults;
`Rv32XqdivInstruction` is the qualified example. See
[custom components](docs/custom-components.md).

The application owns memories, firmware provisioning, peripherals and clock/reset.
See [core selection](docs/cores.md) and [integration](docs/integration.md) before
wiring providers or controls.

## Compose a system

`RvMemorySystem<Rv32iSequentialCore>` owns a default 4 KiB fetch ROM and
4 KiB data RAM. For a custom address map, construct `RvSystem<TCORE>(fetch,
loadStore)` with your own providers. `Rv32FetchBus` and `Rv32LoadStoreBus`
route independent address windows; `RvUartDevice` adapts a buffered UART to
load/store registers. `RvPlatformInfo` exposes the selected composition and
implementation choices to software. See [system composition](docs/system.md)
for ownership, provisioning and interrupt wiring.

## Use the package

Add the release under `[dependencies]` in your application's `livt.toml`:

```toml
[dependencies]
"Eccelerators.RiscV" = "0.3.0"
```

For development against a local checkout, use this dependency instead:

```toml
[dependencies]
"Eccelerators.RiscV" = { path = "../eccelerators-riscv" }
```

Run `livt sync` to resolve dependencies. The package uses `Livt.IO` 1.8.1 for
memory storage and the buffered UART adapter.

Software targets are `rv32i`, `rv32i_zmmul`, or `rv32i_zmmul_zicsr`, with the
`ilp32` ABI, according to the selected core. Zmmul includes multiplication but
not division. Machine cores implement a documented machine-mode subset with
MRET, direct traps, timer and external interrupts. Compressed instructions,
atomics, floating point, vectors, lower privilege modes, MMU, caches and
architectural debug are absent. These cores do not boot Linux.

## Documentation and tests

- [Documentation index](docs/README.md): architecture, contracts and customization.
- [Testing](docs/testing.md): run the functional suite with `livt test`.
- [Change history](CHANGELOG.md) and [license](LICENSE).

Run the functional suite against the resolved dependencies before publishing.
FPGA resources and timing depend on the complete composition, parameters and
target; validate them for your application.

This package contains reusable source, functional tests and user documentation.
