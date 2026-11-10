# Architecture

A core is an execution engine wired to concrete providers. A named preset owns
that assembly; an explicit composition owns and wires the same units itself.
The platform supplies instruction/data ports and owns its peripherals. All
borrowed providers must outlive the core and share its clock/reset domain.

| Namespace | Responsibility |
|---|---|
| `Presets` | Named sequential and pipeline assemblies |
| `Core` | Engine-facing signal contracts and generic composition helpers |
| `Isa` | Standard encodings, operation vocabularies, semantics, decoders and execution providers |
| `Sequential` | Sequential instruction ordering and architectural commit |
| `Pipeline` | Pipeline ordering and physical timing checks |
| `Storage` | Synchronous register banks and fetch/data memories |
| `Machine` | Zicsr composition, machine CSR state, trap vocabulary and machine instruction decoding |
| `Platform` | Timer, external interrupt helpers and buffered UART adapter |
| `Contracts` | Static capability/timing checks and composition contracts |
| `System` | Constructor-bound systems and fetch/load-store routers |

The engine owns instruction identity, PC, scheduling, dependency handling and the
ordered architectural decision. The register bank owns integer storage. The CSR
provider owns CSR mutation, trap state and counters. Arithmetic providers compute
results; they do not modify architectural registers, memory or peripherals.

```mermaid
classDiagram
    class NamedCore
    class Engine
    class RegisterBank
    class Decoder
    class IntegerUnit
    class Multiplier
    class CustomInstruction
    class ZicsrComposition
    class FetchPort {
        <<interface>>
    }
    class LoadStorePort {
        <<interface>>
    }
    NamedCore *-- Engine
    NamedCore *-- RegisterBank
    NamedCore *-- Decoder
    NamedCore *-- IntegerUnit
    NamedCore *-- Multiplier
    NamedCore *-- CustomInstruction
    NamedCore *-- ZicsrComposition
    Engine --> RegisterBank : borrows
    Engine --> Decoder : borrows
    Engine --> IntegerUnit : borrows
    Engine --> Multiplier : borrows
    Engine --> CustomInstruction : borrows
    Engine --> ZicsrComposition : borrows
    Engine --> FetchPort : instructions
    Engine --> LoadStorePort : data
```

The diagram summarizes a machine composition; base presets substitute stateless
terminations for unsupported multiplier/CSR ports. Compile-time selection removes
unselected hardware. A facade forwards signal interfaces combinationally rather
than introducing a scheduled adapter.

The engines share ISA semantics and providers where timing permits. They have
separate controllers because a sequential single-port register bank and an
overlapping pipeline need different scheduling and hazards. The pipeline uses
`IRv32DualReadRegisterPort`; the sequential engine uses `IRv32RegisterPort`.
Neither interface implies arbitrary interchangeability.

Both engines borrow `IRv32IntegerPort`. Its operation, operand and
result signals form a zero-state combinational path sampled at the engine's
execution edge. A provider may replace `Rv32iIntegerUnit` only when it preserves
that timing and implements every operation declared by the composition. A unit
that needs acceptance or completion cycles requires a separate protocol.

`RvOperationCoverage`, `RvTimingContract` and `RvPipelineContract` check declared
operation coverage and timing requirements during elaboration. They add no runtime
registry. A passing assertion cannot prove provider behavior or arbitrary wiring;
functional tests and implementation reports are still required.

The scheduled reference cores and the unused method-style decoder/execution
contracts have been removed. Supported extension points are the signal interfaces
used by the engines and systems. `Rv32Core` owns providers selected through
constrained generic types. `Rv32SequentialCore` and `Rv32PipelineCore` inherit it
as zero-body specializations that bind the appropriate engine and register-port
contract. They preserve the distinct single-read sequential and dual-read pipeline
interfaces without duplicating ownership or forwarding logic. Named presets bind
qualified ISA combinations and retain their coverage and timing checks.
Applications control execution through run/step/restart handshakes; see
[system composition](system.md) for complete device ownership and routing.
