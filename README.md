# Eccelerators.RiscV

Composable RISC-V processors for FPGA applications written in Livt. Start with a
named core, or construct an engine and its providers explicitly. Both approaches
use the same reusable components; resource choices are compile-time parameters.

Version **0.2.1** adds separate instruction-fetch and load/store ports and a
system-level composition while retaining the sequential and pipeline core
presets. See the [release notes](CHANGELOG.md#021) for migration guidance.

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
`REGISTER_FILE_STYLE` defaults to `MemoryStyle.Block`. The non-machine Zmmul
presets and the pipeline machine preset also accept `DSP_MULTIPLY`, defaulting
to iterative multiplication. The sequential machine preset uses the iterative
multiplier; use explicit composition for a sequential DSP machine.

For example, these constructor fragments select a base sequential core or a
machine pipeline with DSP multiplication:

```livt
core = new Rv32iSequentialCore(instructions, data)
```

```livt
core = new Rv32iZmmulPipelineMachineCore<0, MemoryStyle.Block, true>(instructions, data)
```

The application owns memories, firmware provisioning, peripherals and clock/reset.
See [core selection](docs/cores.md) and [integration](docs/integration.md) before
wiring providers or controls.

## Use the package

Add the release under `[dependencies]` in your application's `livt.toml`:

```toml
[dependencies]
"Eccelerators.RiscV" = "0.2.1"
```

For development against a local checkout, use this dependency instead:

```toml
[dependencies]
"Eccelerators.RiscV" = { path = "../eccelerators-riscv" }
```

Run `livt sync` to resolve dependencies. The package uses `Livt.IO` 1.8.1 for
memory storage and its reference UART platform.

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
