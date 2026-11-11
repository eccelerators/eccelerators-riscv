# ISA extension boundaries

An ISA is the software-visible instruction set, architectural state and fault
behavior. The package composes hardware providers that implement parts of an ISA;
it does not model an ISA as Boolean feature switches. Named presets bind qualified
combinations, while `Rv32SequentialCore` and `Rv32PipelineCore` select providers
explicitly at elaboration. Both inherit the general `Rv32Core` composition.

`RvDecoded` carries a five-bit operation family and an eight-bit operation local
to that family. This gives decoders room to add cohesive execution providers
without making every engine understand one global flat operation enumeration.
Capabilities remain elaboration-time coverage checks, not a runtime registry.

| Extension family | Reusable boundary | Required new work |
|---|---|---|
| M division/remainder | `IRv32MPort`, `IRv32DividerPort` and existing commit ownership | Implemented by the full-M decoder, `Rv32MUnit` and named M presets |
| Zba/Zbb/Zbs | `IRv32IntegerPort`, typed decoder/execution overlays and engines | Implemented independently and as combined named presets |
| RV32E | RV32 execution engines and most semantics | Implemented with 16-register storage, legality checks and named presets |
| Zifencei | Ordered commit and `IRv32FetchPort` synchronization | Implemented by typed decoder overlays and named presets |
| A | Ordered commit and load/store addressing | Atomic memory transaction, reservation ownership and memory-order contract |
| C | `IRv32InstructionPort`, `Rv32cInstructionFetch` and existing RV32I semantics | Implemented for RV32C integer forms with named sequential and pipeline presets |
| F/D | Integer control and memory framework where compatible | Floating-point register state, rounding/status CSRs, execution and commit ports |
| RV64 | Composition ideas and some control structure | A width-specific contract family, 64-bit state and RV64 decode/semantics |
| Custom result-only instructions | `IRv32CustomInstructionPort` | Provider recognition, execution and qualification tests |

The custom boundary is intentionally narrow. It covers one outstanding operation
with two integer inputs, one integer result, variable latency and synchronous fault
reporting. It does not grant memory access or architectural side effects. Extensions
that alter fetch framing, add a register file or own shared memory need their own
cohesive interfaces so their timing and ordering remain explicit.

Use general `IRv32...` interfaces when multiple RV32 ISA compositions share the
same hardware contract. Use `Rv32...` names for components that work across those
compositions and `Rv32i...` or combined names when a component implements or
requires a specific instruction set. Standard instruction sources live under
`Eccelerators.RiscV.Isa`; engines, privilege state, storage and systems remain in
their responsibility-based namespaces.

The M transaction contract admits one request and holds it until its selected
provider completes. Zmmul providers implement only multiply operations; `Rv32MUnit`
combines a multiplier and divider without adding division hardware to Zmmul cores.
Zba, Zbb and Zbs use typed overlays so a custom composition can select each subset
independently. RV32E is a base-ISA choice represented by dedicated decoders,
register banks and presets rather than an arbitrary runtime register count.
RV32C is an instruction-front-end choice. It preserves the aligned physical-word
fetch contract, publishes instruction length and raw encoding to either engine,
and expands compressed integer forms before the normal decoder composition.

An extension is supported only after decode, execution, architectural state,
faults, software-visible reporting and both relevant engine integrations are
tested. Resource and timing claims apply to a synthesized complete composition,
not to an interface or capability declaration alone.
