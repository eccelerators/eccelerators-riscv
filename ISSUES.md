# Issues

Tracking issues for the high-level "system layer" API discussed for
`Eccelerators.RiscV`. One line per issue in the dashboard; full details below.
Check the box when an issue is closed.

## Dashboard

- [x] [#1](#issue-1) Implement the generic system component `RvSystem<TCORE>` with a constructor-bound core.
- [x] [#2](#issue-2) Resolve the core-construction problem: constructor type-parameter bounds are expressible; typed parts replace boolean flags. (resolved by design)
- [x] [#3](#issue-3) Split `IRv32MemoryPort` into `IRv32FetchPort` and `IRv32LoadStorePort`; delete the merged interface.
- [ ] [#4](#issue-4) Treat UART as a user-composed example, not a system feature: `RvUartDevice` behind `Rv32AddressRouter`.
- [ ] [#5](#issue-5) Document the two-tier API: preset inheritance → hand composition; note the `Port` naming convention.
- [ ] [#6](#issue-6) Migrate `livt-riscv-app`'s `ProcessorDemo` to the new system layer.
- [x] [#7](#issue-7) Add parity tests: `RvSystem`-based core vs. hand-wired equivalent.

---

## Issue 1

**Implement the generic system component `RvSystem<TCORE>`.**

Add one parametric system component so users can build a turnkey RISC-V system
by instantiating a single component. The system is generic over the whole core,
selected as a type parameter with a *constructor bound* — a language feature
verified against the grammar (`Livt.xtext` `ELivtTypeParameter`) and existing
tests (`GenericConstraintsTest`, `new(flip Bus)` forms):

```livt
component RvSystem<TCORE : IRv32ControlPort
	& new(flip IRv32FetchPort, flip IRv32LoadStorePort)> : IRv32ControlPort
{
	fetchDevice: RvFetchRom
	dataDevice: RvLoadStoreRam
	core: TCORE

	new()
	{
		fetchDevice = new RvFetchRom()
		dataDevice = new RvLoadStoreRam()
		core = new TCORE(fetchDevice, dataDevice)
	}
	// Connect[] process passes every IRv32ControlPort signal through.
}
```

- The name is ISA-neutral (`RvSystem`, not `Rv32iSystem`): the ISA comes from
  `TCORE` and the typed parts, not from the system itself. Presets carry the
  ISA suffix (`Rv32iSequentialCore`, `Rv32iZmmulSequentialCore`, ...).
- The system owns the default signal-level devices: `RvFetchRom` (read-only
  instruction provider) and `RvLoadStoreRam` (byte-enabled data RAM). Both are
  the signal-level counterparts of the existing scheduled Bus fixtures.
- `core = new TCORE(fetchDevice, dataDevice)` enforces the two-port
  constructor convention at the type level; any core following it drops in
  unchanged.
- `RvSystem` itself implements `IRv32ControlPort` and forwards every signal
  (`run`, `stepRequest`, `restartRequest`, `stepAck`, `restartAck`, `idle`,
  `halted`, `pc`, `faultCause/faultValue`, trap and retirement observation)
  in a pure `Connect[]` process.
- Multi-device address maps are handled by inheritance, not by more `RvSystem`
  parameters: a subclass overrides `dataDevice` with a `Rv32AddressRouter`
  fan-out (issue #4). `RvSystem` only ever sees the two port interfaces.
- There is no named "minimal" preset to design: `RvSystem<default args>` with
  the 1-ROM + 1-RAM defaults *is* the minimal system.

## Issue 2

**Resolve the core-construction problem: constructor type-parameter bounds are
expressible; typed parts replace boolean flags. (resolved by design)**

Two earlier premises are now closed:

1. *Constructor convention.* A type parameter can carry a constructor bound
   (`D: new(flip Bus)`), including combined bounds (`M: Bus & new()`). So the
   design is a `TCORE` type parameter bounded by
   `IRv32ControlPort & new(flip IRv32FetchPort, flip IRv32LoadStorePort)`, not
   an enum-selected ladder and not an `IRv32CoreFactory` escape hatch.
2. *Feature flags.* The flags that actually mean "a component exists" are
   replaced by the typed constructor-borrowed parts that already exist —
   `decoder`, `integer`, `multiplier` (`Rv32NoMultiplier` when absent),
   `csrs` (`Rv32NoCsrs` when absent). `MULTIPLY`/`CSR` legality disappears
   from the engine: a plain decoder returns zero control for MUL/SYSTEM
   encodings, overlay decoders (`Rv32iZmmulDecoder`, `Rv32ZicsrDecoder`) make
   them legal; `INTERRUPTS` is deleted outright because `Rv32NoCsrs` ties
   `interruptEligible` low, so the engine's single condition
   `csrs.interruptEligible == 0b1` subsumes the flag.

   One boolean is kept honestly: `MACHINE_TRAPS`. The stop-vs-redirect
   exception *policy* is not a function of any part type —
   `Rv32TrapPolicyTest` wires the same `Rv32MachineCsrs` +
   `Rv32MachineDecoder` chain and must still stop with `halted`/`faultCause`
   instead of redirecting. Parts encode *which component exists*; this policy
   is orthogonal, so no typed part can carry it. The engine signature becomes:

   ```livt
   component Rv32SequentialEngine<RESET_PC: uint = 0, MACHINE_TRAPS: bool = false>
   ```

## Issue 3

**Split `IRv32MemoryPort` into `IRv32FetchPort` and `IRv32LoadStorePort`.**

The merged word-access interface lets an engine drive `write`/`byteEnable`/
`writeData` at the fetch port and lets fetch devices pretend to be writable.
Split it along the architectural lines the RISC-V privilege vocabulary already
draws (constant code fetch vs. `LW/SW`-style load/store with byte lane
enables):

```livt
interface IRv32FetchPort      // read-only: request, address in; ready, error, instruction out
interface IRv32LoadStorePort  // request, address, write, byteEnable, writeData in; ready, error, readData out
```

Transaction semantics per channel are unchanged from `IRv32MemoryPort`
(single outstanding transaction, hold stable until `ready`, error before
effects, no cancellation). Note: the RISC-V ISA spec standardizes no bus
protocol; the fetch/load-store *vocabulary* is ours, and the `Port` suffix is
package coinage (documented per issue #5).

`IRv32MemoryPort` is deleted outright (no alias): all 19 referencing files are
updated — both engines, all six presets, `Rv32WordMemory`,
`RvExternalInterrupts`, `RvMachineTimer`, and the test fixtures
(`DelayedWordDevice`, `PipelineFetchMemory`, `PipelineWordDevice`). Preset
core constructors retype from `(instructions, data: flip IRv32MemoryPort)` to
`(fetch: flip IRv32FetchPort, loadStore: flip IRv32LoadStorePort)`. The
scheduled `Bus/IRv32InstructionBus`/`IRv32DataBus` method-style fixtures are
unrelated to this split and stay as-is for the legacy reference cores.

## Issue 4

**Treat UART as a user-composed example, not a system feature.**

UART is not part of the system abstraction; it is just another load/store
device. Provide the pieces and a worked example instead of preset parameters:

```livt
component Rv32imUartExample : RvSystem</* IM core type */>
{
    // subclass overrides the data device with a router and attaches UART
    // router: Rv32AddressRouter (RAM + UART fan-out, signal-level)
    // uart:   RvUartDevice : IRv32LoadStorePort (rx/tx pins)
}
```

The fetch side stays 1:1 (the PC *is* the routing there); fan-out exists only
on the load/store side, which is exactly what `Rv32AddressRouter` consumes.

## Issue 5

**Document the two-tier API.**

Update `docs/` (likely a new `docs/system.md` plus README updates) to explain:

1. **System layer** — instantiate or subclass `RvSystem<...>`; defaults are one
   ROM + one RAM; extend by inheritance for extra devices.
2. **Hand composition** — construct a preset core and borrow your own port
   implementations when the defaults do not fit.

Also document the naming convention: `Port` suffixes (like `IRv32FetchPort`)
name signal-level protocol contracts; `Bus` names (like `IRv32InstructionBus`)
name the scheduled method-style contract. The RISC-V spec standardizes no bus
protocol — both vocabularies are package coinage.

## Issue 6

**Migrate `livt-riscv-app`'s `ProcessorDemo` to the new system layer.**

Rewrite `src/ProcessorDemo.lvt` so it instantiates one signal-level system
built on `RvSystem` instead of manually wiring `ProgramMemory`,
`ProcessorBus` and `Rv32iInjectedBusCore`. The scheduled reference-core demo
may remain behind a legacy example if still useful; the primary demo uses the
system layer.

## Issue 7

**Add parity tests: `RvSystem`-based core vs. hand-wired equivalent.**

Add tests that construct the same machine two ways — via `RvSystem`
defaults and by hand wiring the same preset core + signal-level devices —
and assert identical retirement, trap, PC and memory behaviour on the same
firmware image, including a UART-example variant for issue #4.
