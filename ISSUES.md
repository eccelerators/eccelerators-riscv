# Architecture and composition roadmap

## Dashboard

`[ ]` means open; `[x]` means completed with the acceptance evidence recorded.
Open items describe planned work; completed items state their implemented support.
Within each phase, work from top to bottom unless measurements expose a different
dependency.

### Completed foundation

- [x] A01 — Replace the concrete integer-unit dependency with a timing-specific interface.
- [x] A07 — Align public contracts and namespaces with the implemented architecture.

### Phase 1 — Composition foundation

- [x] A08 — Separate ISA implementations from generic core infrastructure.
- [x] A05 — Define architectural extension boundaries beyond the current RV32 shape.
- [x] A02 — Add a supported custom instruction execution boundary.
- [x] A06 — Make custom core controls straightforward to expose in systems.

### Phase 2 — Machine composition and compact ISA improvements

- [ ] A09 — Factor shared machine-mode ownership into `Rv32MachineCore`.
- [ ] I01 — Complete the standard M integer multiply/divide extension.
- [x] I02 — Add the Zba, Zbb and Zbs bit-manipulation extensions.
- [ ] I08 — Add an RV32E reduced-register base option.
- [x] I03 — Add the Zifencei instruction-fetch fence extension.

### Phase 3 — Initial multicore and shared state

- [ ] M01 — Compose and qualify two independently controlled cores.
- [ ] A04 — Define progress, timeout and recovery behavior for stalled providers.
- [ ] M02 — Add arbitration for shared memory and peripherals.
- [ ] M03 — Add interprocessor communication and interrupt delivery.
- [ ] M04 — Establish shared-memory synchronization and ordering guarantees.
- [ ] I05 — Add the standard A atomic-instruction extension.

### Phase 4 — Larger architectural changes

- [ ] I04 — Add the standard C compressed-instruction extension.
- [ ] A03 — Introduce an optional memory protocol for higher throughput.
- [ ] I06 — Add the standard F single-precision floating-point extension.
- [ ] I07 — Add the standard D double-precision floating-point extension.

### Phase 5 — Operating-system-capable systems

- [ ] M05 — Define the path to cached and operating-system-capable SMP.

## Direction and order

The goal is to compose useful FPGA processors from cohesive components: qualified
named presets for common configurations and explicit composition for custom cores
and systems. Follow the Livt design guide, keep ownership explicit, and document
acceptance, completion, clock/reset, timing and side-effect contracts. Resource
choices remain compile-time parameters where they preserve those contracts.

The dashboard defines the implementation phases. With A07 and A01 complete, establish
the ISA source and composition boundaries through A08 and the first concrete A05
extension map. Then prove custom extension and control composition with A02 and A06.
Factor shared machine-mode ownership through A09 before extending that composition
with the full M extension. Add the remaining compact ISA improvements before changing
fetch framing or architectural state.

Begin multicore with independent systems in M01. Define stalled-provider behavior in
A04 before qualifying shared devices, then add arbitration, communication and memory
ordering through M02, M03 and M04. Standard atomics in I05 depend on that shared-memory
foundation. I03 must precede instruction caches, while I04 changes fetch framing and
I06/I07 introduce separate architectural state. A03 remains driven by measured
bandwidth needs and is not a prerequisite for a small multicore system. M05 is the
long-term integration path after the required ISA, memory and multicore contracts are
qualified.

Keep small cores economical. New capabilities must not impose unused hardware on
base presets. Separate sequential and pipeline controllers where their scheduling
differs; share semantics and providers where their contracts permit it. Backward
compatibility is not a requirement, but changes must migrate affected presets,
tests, examples and documentation together.

## Core and system flexibility

### A01 — Integer-unit substitution

**Status:** Completed. `IRv32IntegerPort` now states the zero-state,
same-cycle operation/operand/result contract. `Rv32iIntegerUnit` implements it and
both engines borrow it through the interface. `Rv32IntegerSubstitutionTest` uses
an independently implemented direct-match datapath in explicit sequential and
pipeline compositions; both pass a 30-instruction vector covering every integer
operation, dependencies, x0 suppression, PC-relative arithmetic and retirement.

The Tang Primer 25K showcase was synthesized with each datapath using Gowin EDA
1.9.12.03 for GW5A-LV25MG121NC1/I0 at a 50 MHz target. The qualified preset and
the alternate explicit composition both used 5,125 registers, 7,128 LUTs and
15 BSRAMs, and both routed at 61.093 MHz. The interface therefore introduced no
resource or timing regression in this comparison. These numbers apply to this
complete composition and tool run, not to arbitrary providers.

**Original constraint:** Both engines borrowed the concrete `Rv32iIntegerUnit`, preventing
independent implementations from substituting through a common interface.

**Work:** Introduce a signal interface for the existing combinational operation,
operand and result contract. Make the existing unit implement it and both engines
consume it. Keep multicycle execution separate rather than hiding extra latency.

**Acceptance:** Demonstrate a second implementation in explicit composition;
verify arithmetic, hazards and retirement in both engines. Compare synthesized
resources and timing against the existing presets and explain any regression.

### A02 — Custom instruction execution

**Status:** Completed. `IRv32CustomInstructionPort` defines one variable-latency,
result-only transaction with recognition, request/ready completion and synchronous
fault reporting. `Rv32NoCustomInstruction` removes the feature without runtime
selection, while `Rv32CustomInstructionPair` composes providers recursively and
rejects decode collisions. `Rv32XqdivInstruction` qualifies the boundary with a
32-cycle unsigned quotient operation in the RISC-V custom-0 encoding space.

Both engines now admit, stall, complete and retire custom operations through the
same port while retaining architectural commit, PC, register and fault ownership.
Tests cover sequential and pipeline dependency chains, x0 suppression, divide by
zero, provider conflicts, restart and precise interrupt delivery. The complete
279-test suite passes. A Tang Primer 25K showcase using the no-custom named preset
uses 5,125 registers, 7,142 LUTs and 15 BSRAMs and routes at 59.269 MHz for a
50 MHz target; the Phase 1 changes add 14 LUTs relative to the preceding qualified
showcase and leave its register and BSRAM counts unchanged. The resulting bitstream
passes physical SRAM boot, firmware UART, interrupt, workload and FPGA-supervision
checks on the board.

**Constraint:** Decoder outputs use a shared operation vocabulary, and engines
explicitly dispatch known instruction families. Adding a decoder does not add
execution, hazard handling or architectural commit behavior.

**Work:** Use a real custom instruction to define a bounded execution extension:
two integer operands, one integer result, variable latency and fault reporting.
Specify operation allocation, illegal encodings, request acceptance, completion,
dependencies, pause/restart and interrupt behavior. The engine retains register,
PC and retirement ownership. Define how multiple extensions compose without
decode conflicts. Side-effecting accelerators require an explicit additional
contract rather than silently extending this one.

**Acceptance:** Compose the extension into sequential and pipeline cores without
instruction-specific edits to their controllers after the extension boundary is
introduced. Test dependency chains, stalls, faults, x0, restart and interrupts.
Show that presets without the extension retain their resource efficiency.

### A03 — Higher-throughput memory transactions

**Constraint:** Current fetch/load-store ports allow one outstanding transaction
per port and require a low-request edge between transactions. A bus adapter alone
cannot remove this throughput ceiling.

**Work:** Measure the bottleneck and design an optional protocol separating
request acceptance from response completion. Specify ordering, backpressure,
errors and response ownership. Add multiple outstanding requests, identifiers or
bursts only when justified. Define adapters and the engine changes necessary to
benefit from the new protocol. Preserve a compact option for small cores.

**Acceptance:** Verify delayed and consecutive responses, saturation and error
handling. Measure sustained bandwidth, workload CPI, resources and routed timing;
do not claim throughput improvement from interface changes alone.

### A04 — Stalled-provider progress and recovery

**Constraint:** Transactions cannot be cancelled; restart drains outstanding
work. A provider that never responds can prevent progress indefinitely.

**Work:** Specify liveness obligations and optional platform watchdog/recovery
policies. Distinguish CPU pause, architectural restart, bus recovery and hardware
reset. Never turn a timeout into a retry or reported clean fault when a store may
already have taken effect. Any recovery adapter must isolate late responses and
define when the device can safely accept another transaction.

**Acceptance:** Exercise nonresponding devices, late completions and stores with
side effects. Document which operations have bounded completion and which require
platform intervention, including effects on other cores sharing that platform.

### A05 — Architectural extension boundaries

**Status:** Completed for the planned boundary definition. `RvDecoded` now carries
a five-bit provider family and an eight-bit provider-local operation. The extension
map in `docs/isa-extensions.md` identifies reusable contracts and required new work
for M division/remainder, Zba/Zbb/Zbs, RV32E, Zifencei, A, C, F/D, RV64 and
result-only custom instructions. The XQDIV implementation is the concrete consumer
that qualifies the expanded decode representation and variable-latency custom
boundary. Later ISA issues remain responsible for their architectural state and
integration tests; this issue does not claim those extensions are implemented.

**Constraint:** Current interfaces and controllers assume RV32 operands, integer
registers and fixed-width instruction handling. Compressed instructions, RV64,
floating point and vectors are not selectable implementation variations today.

**Work:** Document which components can be reused and which need new contracts
for each extension. Start implementation with a selected concrete use case;
compressed instructions would require instruction assembly, length tracking,
cross-boundary fetch and precise fault/PC handling. Update decode representations
and capability checks alongside any new ISA support. Use separate engine or port
families when fundamentally different timing or architectural state warrants it.

**Acceptance:** Publish an extension map, then qualify each implemented extension
with architectural and integration tests. Do not advertise unimplemented families
or introduce universal width/configuration parameters without a working consumer.

### A06 — Custom system controls

**Status:** Completed. `IRv32RetirementTracePort` defines a typed observation port,
`Rv32RetirementTraceCore` exposes it while forwarding the normal core contract, and
`RvRetirementTraceSystem` shows the corresponding system wrapper. The direct and
wrapped compositions in `RvCustomControlSystemTest` exercise independent run,
single-step and restart control and compare retirement trace signals in the same
cycle, proving that the wrapper adds no state or latency.

**Constraint:** Generic system wrappers expose specific control interfaces; they
cannot automatically forward arbitrary extra core ports.

**Work:** Establish a documented pattern for typed wrappers and direct composition
that exposes custom controls, observation and interrupt sources. Preserve one
writer per input and explicit ownership; avoid a universal wrapper full of optional
signals. Keep forwarding combinational where no additional latency is intended.

**Acceptance:** Provide an example with a custom core interface and independent
run/step/restart control, showing both explicit assembly and an appropriate wrapper.
Verify that the wrapper introduces no unintended state or timing changes.

### A07 — Public contract and namespace clarity

**Status:** Completed. Reusable core ports, decode/semantic helpers and execution
providers now live in `Eccelerators.RiscV.Core`; `Sequential` and `Pipeline`
contain their respective controllers. The unused scheduled-call `IRvDecoder` and
`IRvExecutionUnit` contracts were removed. Public documentation now identifies
the signal interfaces actually consumed by engines and systems. The complete
functional suite passes with the migrated namespaces.

**Original constraint:** Method-style `IRvExecutionUnit` and `IRvDecoder` were not
consumed by the signal-based engines. Shared components under `Sequential` were
also used by the pipeline, which made their scope harder to discover.

**Work:** Remove unused contracts or document and test their distinct supported
purpose. Organize shared contracts and units by responsibility. Update imports,
examples and documentation; make supported extension interfaces unambiguous.

**Acceptance:** Every advertised extension interface has a working consumer or
example. Existing tests pass, and documentation describes the actual composition
path without implying that scheduled calls preserve signal-level timing.

### A08 — ISA source boundary

**Status:** Completed. Standard encodings, operation vocabularies, pure semantics,
decoders and execution providers now live under `src/Isa` and
`Eccelerators.RiscV.Isa`. Engine-facing ports remain in `Core`; sequencing remains
in `Sequential` and `Pipeline`; CSR state and trap policy remain in `Machine`.
Compatibility aliases were not retained.

`Rv32Core` owns interface-constrained provider types for explicit composition.
`Rv32SequentialCore` and `Rv32PipelineCore` inherit it as zero-body specializations
that bind scheduling to the matching register-file contract without duplicating
implementation. Named presets bind qualified RV32I and RV32I+Zmmul combinations,
and Zmmul presets select an iterative or DSP multiplier through a constrained
provider type instead of a Boolean. Generic choices are elaborated to concrete
components with no runtime provider dispatch. Public docs, tests and the Tang
Primer application use the new namespaces and provider syntax. Package validation
passes all 233 files; the preceding Phase 1 functional qualification passed all
279 tests. The current Tang Primer 25K showcase routes at 59.269 MHz with the
resource figures recorded under A02.

**Constraint:** `Core` currently contains reusable ports together with RV32I and
Zmmul encodings, decode logic, semantics and execution providers. As more standard
extensions are added, this makes the public source layout obscure which components
define an instruction set and which components provide generic engine infrastructure.

**Work:** Introduce `Eccelerators.RiscV.Isa` and a matching `src/Isa` source area for
standard instruction encodings, operation vocabularies, pure semantics, decoders and
execution providers. Keep engine-facing contracts in `Core`; keep sequencing in
`Sequential` and `Pipeline`, privilege state and trap policy in `Machine`, and retain
the responsibility-based `Storage`, `System` and `Platform` namespaces. Use names such
as `Rv32iDecoder`, `Rv32IterativeMultiplier` and `Rv32DspMultiplier` to expose both the
implemented ISA family and implementation choice without adding a directory for every
extension.

Make the source hierarchy reflect specialization. Use `IRv32...` for stable, narrow
RV32 hardware contracts and `Rv32...` for components that work across multiple RV32
ISA compositions. Use `Rv32i...` and combined names such as `Rv32iZmmul...` only when
the component implements or requires those instruction sets. Do not introduce a
general component that merely forwards to one specialized implementation.

Use constrained generic component types when a composition owns a provider and the
choice is structural at elaboration time. Use interface-typed constructor parameters
when the parent owns or shares the provider, or when wiring must remain explicit. A
general composition may select decoder, integer, multiplier, CSR and storage providers
through interface-constrained types with useful defaults; named qualified presets bind
the supported ISA combination while leaving meaningful implementation choices, such
as iterative versus DSP multiplication or register-file style, configurable.

Keep interfaces timing-specific and cohesive. Do not create one universal ISA-extension
interface: compressed instructions, atomics and floating point change different
architectural boundaries. Do not represent an ISA as a collection of Boolean feature
flags. Compose typed providers and publish named presets instead, so unused extensions
do not require runtime selection hardware. Document these rules and migrate imports,
presets, examples and tests together.

**Acceptance:** A user can locate standard instruction support under `Isa`, distinguish
contracts from implementations, and compose existing presets without behavior,
resource or timing regression. All public examples and architecture documentation use
the new layout, and no compatibility aliases remain. Demonstrate both supported paths:
a named qualified preset and an explicit composition that substitutes at least one
provider through an interface-constrained generic type. Verify that the generic choice
is specialized during compilation and introduces no runtime dispatch or unused-provider
hardware.

### A09 — Shared machine-core composition

**Status:** Implementation and functional regression are complete; FPGA
qualification remains open. `Rv32MachineCore` owns the shared machine topology,
and thin sequential and pipeline specializations bind their native register ports
and engines. Both qualified machine presets inherit this structure. The one
`Rv32ZicsrComposition` instance supplies decode and CSR access, and the shared core
owns interrupt/control forwarding. Existing machine, CSR, trap and interrupt tests
pass for both engines. Close this item after recording the Tang Primer 25K resource
and routed-timing comparison required by acceptance.

**Constraint:** `Rv32iZmmulSequentialMachineCore` and
`Rv32iZmmulPipelineMachineCore` independently own and connect the same machine-mode
structure: a base decoder, shared Zicsr decode/CSR composition, MRET overlay,
integer and multiplier providers, custom-instruction provider, execution engine,
interrupt inputs and control forwarding. The ordinary `Rv32Core` cannot represent
this topology directly because its decoder and CSR providers are independently
constructed, while machine mode requires one `Rv32ZicsrComposition` instance to
serve both roles and to sit inside the decoder chain.

**Work:** Introduce `Rv32MachineCore` as the single owner of the shared machine-mode
topology. Correlate its register-port interface and engine type in the same way as
`Rv32Core`, while preserving one Zicsr state owner, explicit decoder layering and
direct timer/external interrupt wiring. Add zero-body sequential and pipeline
specializations that bind their native register-file contracts and machine-trap
engine configurations. Keep ISA-qualified presets responsible for provider choices,
coverage witnesses and timing checks. Do not add runtime feature selection or force
diagnostic-only cores through the machine interface.

**Acceptance:** Both machine presets use the shared machine core and contain no
duplicated provider ownership, engine construction or control forwarding. Prove that
decode and CSR access use the same Zicsr instance, interrupt inputs retain one writer,
and sequential and pipeline register contracts remain distinct. Run existing machine,
CSR, trap and interrupt tests for both engines, then compare complete Tang Primer 25K
resources and routed timing with the preceding qualified presets and explain any
regression.

## Standard ISA extensions

These issues cover the next standard extensions useful to the current FPGA cores.
They are deliberately staged: an extension is not complete until decode, architectural
state, execution, faults, software-visible capability reporting and both engine
integrations are qualified. The list is not a claim to support every ratified RISC-V
extension; add further extensions when a concrete core or workload requires them.

### I01 — Full M multiplication and division

**Status:** Implementation and functional regression are complete; synthesis and
performance qualification remain open. `IRv32MPort`, `IRv32DividerPort`,
`Rv32IterativeDivider`, `Rv32MUnit`, the full-M decoder and named sequential and
pipeline presets cover all eight M operations while Zmmul remains multiply-only.
Architectural edge vectors and dependency/stall programs pass in both engines.
Close this item after recording resource, CPI and routed-timing comparisons.

**Constraint:** Zmmul implements multiplication only. Standard M additionally requires
DIV, DIVU, REM and REMU with specified division-by-zero and signed-overflow results.

**Work:** Add a substitutable divider provider and extend the M decoder without making
division hardware part of Zmmul presets. Reuse the ordered variable-latency completion
path where its contract fits, and provide a compact iterative implementation first.

**Acceptance:** Run architectural edge vectors and dependency/stall tests in both
engines. Qualify separate Zmmul and M presets and compare resources, CPI and timing.

### I02 — Zba, Zbb and Zbs bit manipulation

**Status:** Completed. Typed decoder and combinational integer overlays implement
Zba, Zbb and Zbs independently, and no-argument compositions plus named presets
provide the useful combined set. Decode and semantic vectors cover every supported
operation and reserved patterns fall through as illegal. Dependent Zba/Zbb/Zbs
programs pass through both sequential and pipeline presets.

**Constraint:** The current integer operation vocabulary covers RV32I only; address
generation, basic bit operations and single-bit operations require additional decode
and execution semantics.

**Work:** Implement the ratified Zba, Zbb and Zbs subsets independently so compositions
pay only for selected subsets. Prefer combinational integer providers where timing
remains acceptable, with a staged provider when an operation would compromise the
clock target.

**Acceptance:** Verify every RV32 encoding and corner case against reference vectors,
reject reserved encodings, and qualify useful subset combinations in both engines.

### I03 — Zifencei instruction-fetch fence

**Status:** Completed. `IRv32FetchPort` now defines an ordered synchronization
handshake. Both engines wait for its completion; the pipeline also discards younger
prefetched instructions and redirects fetch. Mutable-instruction-memory tests prove
visibility after a delayed store and catch stale prefetched execution. The cacheless,
buffered and cached provider obligations are documented in the integration guide.

**Constraint:** FENCE.I is not an RV32I instruction. Treating instruction and data
memory as permanently coherent is only valid for current cacheless immutable-code
compositions.

**Work:** Decode FENCE.I and define an instruction-side synchronization contract. A
cacheless implementation may complete it as an ordered no-op only when the platform
contract guarantees visibility; future buffered or cached fetch providers must flush
or invalidate before completion.

**Acceptance:** Test self-modifying-code visibility with a mutable instruction memory,
ordering across delayed stores, and the documented cacheless implementation.

### I04 — C compressed instructions

**Constraint:** Fetch, PC progression, alignment faults and decode currently assume a
32-bit instruction at a four-byte boundary. C permits mixed 16-bit and 32-bit
instructions on two-byte boundaries.

**Work:** Add instruction assembly across fetch-word boundaries, instruction-length
metadata and RV32C decompression into the existing semantic vocabulary. Update branch,
trap, retirement and restart PCs to use the decoded length and enforce RV32C reserved
and hint encodings.

**Acceptance:** Run mixed-width streams at every halfword alignment, including branches,
faults and boundary-spanning 32-bit instructions. Measure code-size, CPI, resources and
routed timing in both engines.

### I05 — A atomic instructions

**Constraint:** The current load/store protocol cannot express an indivisible
read-modify-write transaction or an LR/SC reservation, especially with multiple cores
and shared devices.

**Work:** Define atomic memory ownership, ordering and reservation invalidation before
adding LR/SC and AMO decode/execution. Integrate arbitration from M02 and the memory
ordering model from M04; do not emulate atomicity inside a core while another bus
master can intervene.

**Acceptance:** Verify all RV32A operations, reservation success/failure, competing
cores, interrupts and memory errors. Run multicore lock and atomic-counter workloads.

### I06 — F single-precision floating point

**Constraint:** F adds a 32-register floating-point register file, `fcsr` state,
IEEE-754 rounding and exception flags, and floating-point load/store and execution
paths that do not fit the integer-result-only extension boundary.

**Work:** Define floating-point register, execution and commit contracts; implement F
decode, state, loads/stores, conversions and arithmetic with selectable resource and
latency providers. Integrate `fcsr` through the machine CSR owner.

**Acceptance:** Pass architectural IEEE-754 vectors for all rounding modes and flags,
then qualify sequential and pipeline presets with software and synthesis measurements.

### I07 — D double-precision floating point

**Constraint:** D depends on F and widens floating-point registers and datapaths to 64
bits, while the current core and memory ports are optimized for 32-bit transfers.

**Work:** Generalize the F contracts only where D proves the need, add paired memory
transactions or a wider optional memory path, and implement D decode and semantics
without imposing 64-bit hardware on F-only cores.

**Acceptance:** Pass double-precision architectural vectors and mixed F/D state tests;
measure the cost of F-only and FD compositions independently.

### I08 — RV32E reduced-register base

**Status:** Implementation and functional regression are complete; ABI and FPGA
qualification remain open. Dedicated RV32E decoders, sixteen-entry sequential and
dual-read register banks, and named presets retain the shared engine architecture
while reserving every instruction encoding that names x16 through x31. Both engines
prove legal x15 retirement and precise illegal-instruction handling. Close this item
after an `ilp32e` program and the RV32E/RV32I resource and timing comparison pass.

**Constraint:** RV32E uses sixteen integer registers and reserves encodings that name
x16 through x31. Existing decode and storage assume the full RV32I register set.

**Work:** Make the architectural register count an explicit base-ISA choice, reject
out-of-range register encodings, and provide named RV32E presets. Keep this separate
from physical register-file style and from arbitrary register-count parameters.

**Acceptance:** Run RV32E architectural and ABI-oriented programs, prove illegal
register encodings trap, and compare register-file, LUT and timing savings with RV32I.

## Multicore systems

Composing multiple core instances is the starting point. Shared resources also
need arbitration, interrupt routing and explicit memory-ordering guarantees.
Operating-system SMP is a later qualification target, not an automatic property
of instantiating two cores.

### M01 — Independent cores

**Work:** Compose two cores with private memories and independent control,
observation and firmware provisioning. Support distinct hart IDs for machine
cores. Allow different presets in the same system and define boot ownership.
Start in one clock domain; other clock domains require explicit CDC components.

**Acceptance:** Run two distinct workloads concurrently in simulation and on the
Tang Primer 25K where resources permit. Pause, step and restart each independently
without affecting the other. Record per-core results and whole-system resources.

### M02 — Shared memory and peripheral arbitration

**Constraint:** Current device routers serve one master; they are not arbiters.

**Work:** Add reusable arbitration with explicit master identity, transaction
ownership and fairness. Route each response only to its requesting core and hold
ownership through the device protocol's release phase. Define per-core restart
and shared-device reset behavior. Address fetch/data contention and measure router
depth before selecting cascaded routing, a balanced decoder or a crossbar.

**Acceptance:** Test simultaneous requests, delayed devices, errors, contention,
starvation bounds for responsive devices and exactly-once peripheral effects.
Demonstrate two cores using shared RAM without lost or misrouted transactions.

### M03 — Interprocessor communication and interrupts

**Work:** Add a reusable mailbox or doorbell device and per-hart interrupt routing.
Define ownership, acknowledgement, pending-state persistence and restart behavior.
Keep an external-interrupt mailbox distinct from architectural machine software
interrupt support; implementing the latter also requires CSR and trap integration.

**Acceptance:** Demonstrate bidirectional messages, simultaneous notification,
masked interrupts, acknowledgement races and restarting one participant. Document
the firmware protocol and how it avoids lost messages.

### M04 — Shared-memory synchronization and ordering

**Work:** Specify observable ordering across cores, device accesses and any DMA.
Define FENCE behavior for the actual fabric. Provide a qualified synchronization
mechanism, initially a hardware semaphore or mailbox if appropriate. Add standard
atomic operations when required by software, including indivisibility at shared
memory and reservation invalidation if LR/SC is selected. Bus arbitration alone
does not make a load followed by a store atomic.

**Acceptance:** Test producer/consumer communication, mutual exclusion and memory
ordering under contention. For implemented atomic instructions, test competing
masters and failure paths. State the supported ISA and software assumptions.

### M05 — Cached and operating-system-capable SMP

**Work:** Define a staged architecture for private/shared caches, coherence or
explicitly managed noncoherent regions, DMA visibility and instruction visibility.
Specify privileged memory metadata, MMU/TLB behavior, interprocessor invalidation,
interrupts, timers, hart startup and firmware/OS interfaces for a chosen target.
Identify which existing components remain reusable and which need replacement.

**Acceptance:** First produce a concrete target and dependency plan. Qualify cache
and memory-consistency behavior before claiming coherent SMP. Claim OS support
only after repeatable boot and concurrent workload tests on that target. Keep
uncached bare-metal multicore usable independently of this work.

## Completion evidence

Close an implementation item only when its acceptance criteria are met. Record
relevant tests and FPGA measurements, including toolchain, clock target, resources
and workload where applicable. Keep generated builds and benchmark logs outside
this package; link to maintained evidence rather than checking large artifacts in.
Compile-time capability declarations complement behavioral tests and physical
qualification; they do not prove arbitrary compositions correct.
