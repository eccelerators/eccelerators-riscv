# Architecture and composition roadmap

## Dashboard

`[ ]` means open; `[x]` means the implementation is complete and its functional
simulation passes. Open items describe planned work; completed items state their
implemented support. Board, resource, timing and software-stack qualification may
follow later without keeping an implementation issue open; each completed issue
records any such deferred evidence. Within each phase, work from top to bottom unless
measurements expose a different dependency.

### Completed foundation

- [x] A01 — Replace the concrete integer-unit dependency with a timing-specific interface.
- [x] A07 — Align public contracts and namespaces with the implemented architecture.

### Phase 1 — Composition foundation

- [x] A08 — Separate ISA implementations from generic core infrastructure.
- [x] A05 — Define architectural extension boundaries beyond the current RV32 shape.
- [x] A02 — Add a supported custom instruction execution boundary.
- [x] A06 — Make custom core controls straightforward to expose in systems.

### Phase 2 — Machine composition and compact ISA improvements

- [x] A09 — Factor shared machine-mode ownership into `Rv32MachineCore`.
- [x] I01 — Complete the standard M integer multiply/divide extension.
- [x] I02 — Add the Zba, Zbb and Zbs bit-manipulation extensions.
- [x] I08 — Add an RV32E reduced-register base option.
- [x] I03 — Add the Zifencei instruction-fetch fence extension.

### Phase 3 — Single-core operating-system path

- [x] OS01 — Define the first concrete OS target and its resource budget.
- [x] I04 — Add the standard C compressed-instruction extension.
- [x] I05 — Add the standard A atomic-instruction extension.
- [ ] OS02 — Add user and supervisor privilege modes.
- [ ] OS03 — Add Sv32 virtual memory and precise page faults.
- [ ] A03 — Introduce an optional memory protocol for higher throughput.
- [ ] A04 — Define progress, timeout and recovery behavior for stalled providers.
- [ ] OS04 — Compose an OS platform with external memory and standard devices.
- [ ] OS05 — Add SBI firmware and boot single-core Linux.

### Phase 4 — Performance and optional architectural state

- [ ] OS06 — Add and qualify caches for useful single-core OS performance.
- [ ] I06 — Add the standard F single-precision floating-point extension.
- [ ] I07 — Add the standard D double-precision floating-point extension.

### Phase 5 — Multicore and operating-system SMP

- [ ] M01 — Compose and qualify two independently controlled cores.
- [ ] M02 — Add arbitration for shared memory and peripherals.
- [ ] M03 — Add interprocessor communication and interrupt delivery.
- [ ] M04 — Establish shared-memory synchronization and ordering guarantees.
- [ ] OS07 — Add SBI multicore services and coherent execution mechanisms.
- [ ] OS08 — Qualify repeatable Linux SMP boot and concurrent workloads.

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

Define one measurable single-core OS target in OS01 before adding architecture for an
unspecified software stack. Add C and A, then introduce U/S privilege and Sv32 through
OS02 and OS03. Use measured external-memory and workload needs to drive A03 rather
than replacing the compact ports unconditionally. Resolve provider liveness in A04
before OS04 qualifies a platform whose external devices can stall. OS05 is the first
OS milestone: a repeatable single-core Linux boot through SBI, without waiting for
caches or multicore.

I03 must precede instruction caches. OS06 adds caches only after the uncached platform
is correct and measures whether they make the OS practically useful. F and D add
separate architectural state and are optional for the first integer Linux target.
Begin multicore independently in M01, then establish arbitration, communication and
memory ordering through M02, M03 and M04. OS07 adds the firmware, remote-fence and
cache-coherence mechanisms needed by an OS, and OS08 is the final Linux SMP
qualification. Keep uncached bare-metal multicore and single-core OS configurations
usable independently of the SMP result.

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

**Status:** Completed. `Rv32MachineCore` owns the shared machine topology,
and thin sequential and pipeline specializations bind their native register ports
and engines. Both qualified machine presets inherit this structure. The one
`Rv32ZicsrComposition` instance supplies decode and CSR access, and the shared core
owns interrupt/control forwarding. Existing machine, CSR, trap and interrupt tests
pass for both engines. Tang Primer 25K resource and routed-timing comparisons are
deferred to later board qualification.

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
They are deliberately staged: implementation covers decode, architectural state,
execution, faults and both engine integrations where applicable. Functional simulation
closes the implementation issue. Software-visible capability reporting, board results
and broader platform qualification can follow in the issue that integrates or qualifies
that system. The list is not a claim to support every ratified RISC-V extension; add
further extensions when a concrete core or workload requires them.

### I01 — Full M multiplication and division

**Status:** Completed. `IRv32MPort`, `IRv32DividerPort`,
`Rv32IterativeDivider`, `Rv32MUnit`, the full-M decoder and named sequential and
pipeline presets cover all eight M operations while Zmmul remains multiply-only.
Architectural edge vectors and dependency/stall programs pass in both engines.
Resource, CPI and routed-timing comparisons are deferred to later board
qualification.

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

**Status:** Completed. Functional simulation covers the implementation; FPGA
qualification is deferred.
`IRv32InstructionPort` separates architectural instruction framing from the
aligned physical-word fetch contract. Both engines own a generic front end and
default to the zero-state `Rv32WordInstructionFetch`, preserving existing core
constructors. `Rv32cInstructionFetch` caches one word, frames both halfword
positions, assembles cross-word 32-bit instructions, preserves raw encodings and
invalidates buffered state for FENCE.I. `Rv32cDecode` expands the RV32C integer
forms into the existing RV32I semantic vocabulary and rejects reserved or
unsupported floating-point encodings.

Named `Rv32icSequentialCore` and `Rv32icPipelineCore` presets select
`RvInstructionAlignment.Halfword`; ordinary presets retain word alignment.
Directed decompression vectors and a mixed-width program pass in both engines,
covering dependencies, raw retirement, a boundary-spanning instruction, a taken
compressed branch, compressed link-address generation and an illegal compressed
fault. Existing 34-test sequential and 34-test pipeline suites also pass through
the fixed-width adapter. Resource, CPI and routed timing measurements remain as
later qualification work.

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

**Status:** Completed for the single-port memory path. `Rv32aDecoder` accepts every
standard RV32A word operation and preserves `aq`/`rl`. Both engines issue atomic
requests only at their ordered memory/commit boundary. `RvLoadStoreRam` owns one
reservation, performs indivisible AMOs and returns architectural LR/SC results.
Ordinary stores, AMOs and host provisioning invalidate the reservation. Named
`Rv32iaSequentialCore` and `Rv32iaPipelineCore` presets expose the composition.

Directed decode and semantic vectors cover all eleven operations and reserved
encodings. A shared program passes on both engines, covering AMO results, LR/SC
success and failure, dependencies, `aqrl`, and invalidation by an ordinary store.
The existing 34-test sequential and 34-test pipeline suites also pass. Interrupt/trap
and access-fault vectors, a single-core lock workload, FPGA measurements and the OS
memory path remain as later system qualification work.

**Constraint:** The current load/store protocol cannot express an indivisible
read-modify-write transaction or an LR/SC reservation. A Linux-capable ISA needs
standard atomics before multicore is introduced, while a later shared fabric must
preserve the same atomicity against every hart and DMA-capable master.

**Work:** Define atomic memory ownership, ordering and reservation invalidation before
adding LR/SC and AMO decode/execution. Qualify the initial implementation on the
single-core OS memory path and expose the ownership/invalidation contract required by
future arbitration. M02 and M04 must enforce that contract when additional masters
are added; do not emulate atomicity inside a core while another bus master can
intervene.

**Acceptance:** Verify all RV32A operations, reservation success/failure, interrupts,
memory errors and single-core lock primitives. Document the multi-master contract.
M04 separately qualifies competing cores, invalidation and atomic-counter workloads
before any SMP claim.

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

**Status:** Completed. Dedicated RV32E decoders, sixteen-entry sequential and
dual-read register banks, and named presets retain the shared engine architecture
while reserving every instruction encoding that names x16 through x31. Both engines
prove legal x15 retirement and precise illegal-instruction handling. An `ilp32e`
program and the RV32E/RV32I resource and timing comparison remain as later software
and board qualification work.

**Constraint:** RV32E uses sixteen integer registers and reserves encodings that name
x16 through x31. Existing decode and storage assume the full RV32I register set.

**Work:** Make the architectural register count an explicit base-ISA choice, reject
out-of-range register encodings, and provide named RV32E presets. Keep this separate
from physical register-file style and from arbitrary register-count parameters.

**Acceptance:** Run RV32E architectural and ABI-oriented programs, prove illegal
register encodings trap, and compare register-file, LUT and timing savings with RV32I.

## Operating-system-capable systems

The first OS milestone is a repeatable single-core Linux boot. It does not depend on
cache coherence or multiple harts. The target definition fixes the exact ISA,
privilege, memory, firmware and board contract before implementation begins. Small
machine-mode and RTOS presets remain independent and do not acquire OS-only hardware.

### OS01 — Concrete OS target

**Status:** Completed. `docs/os-target.md` fixes one single-hart
`rv32imac_zicsr_zifencei_zicntr` Linux configuration, the `ilp32` ABI,
privileged architecture 1.12, Sv32, eight PMP entries, standard platform
devices and a 64 MiB physical map. It assigns boot responsibilities to the
FPGA CLI, OpenSBI and Linux and pins Linux v6.18, OpenSBI v1.9 and Buildroot
2026.08.1. The dependency matrix identifies the reusable component boundary
and owning roadmap item for every missing capability.

The target first qualifies on a Tang Primer 25K with its external SDRAM module.
Explicit timing, utilization, bandwidth and boot-time gates move qualification
to the Tang Mega 138K and its onboard DDR3 without changing the core, device
or software-visible memory contracts. A sparse simulation platform provides the
same addresses and variable-latency memory before either board is required.

**Work:** Define the first supported OS configuration, including RV32 ISA string,
privileged architecture version, ABI, Tang Primer 25K clock and resource budget,
external-memory capacity and bandwidth, physical address map, interrupt architecture,
console, boot payload and Linux/initramfs versions. Choose which responsibilities
belong to hardware, machine firmware and the FPGA CLI. Record the minimum usable
performance target and identify components that remain reusable from the small cores.

**Acceptance:** Publish one dependency matrix and boot contract with no unresolved
choice that changes the core interfaces. Include a resource-risk estimate and a
smaller simulation platform for architectural work before external-memory hardware
is available.

### OS02 — User and supervisor privilege modes

**Constraint:** Current machine cores implement a machine-only subset. Linux normally
runs in supervisor mode and requires user-mode isolation, delegated traps and
supervisor-visible interrupt and status state.

**Work:** Add U/S privilege tracking, M/S trap entry and return, `SRET`, `WFI`,
exception and interrupt delegation, supervisor CSR views and the required machine
CSR state. Define PMP behavior for resident machine firmware and make privilege a
cohesive provider contract rather than scattering mode checks through devices.

**Acceptance:** Run directed privilege-transition, delegation, CSR-access, interrupt,
PMP and precise-exception tests. Boot an S-mode payload through M-mode firmware and
prove that U-mode accesses cannot escape their configured permissions.

### OS03 — Sv32 virtual memory

**Constraint:** The current fetch and load/store addresses are physical. A protected
RV32 Linux system needs `satp`, Sv32 page-table translation, permission checks and
precise page-fault reporting.

**Work:** Add instruction and data translation contracts, TLBs, a page-table walker,
`SFENCE.VMA`, ASID handling and Sv32 permission, accessed and dirty-bit behavior.
Integrate translation with privilege state, fetch synchronization and architectural
fault ordering. Keep the cache and translation boundaries separate so an uncached
MMU can be qualified first.

**Acceptance:** Test page sizes, ASIDs, permissions, U/S access rules, global mappings,
TLB replacement and invalidation, malformed walks, access faults and instruction,
load and store page faults. Run an S-mode virtual-memory payload that switches address
spaces and handles copy-on-write-style faults.

### OS04 — Single-core OS platform

**Constraint:** BRAM-only examples lack the memory capacity and standard platform
devices needed for a useful Linux image.

**Work:** Compose the OS-qualified core with external memory, boot storage or host
provisioning, UART, timer, software-interrupt source and external-interrupt controller.
Define the physical memory map, device-tree description, reset ownership and firmware
reservation. Use A03 only where measurements show that the compact transaction ports
cannot meet the selected memory target.

**Acceptance:** Stress external memory and every interrupt path independently before
booting an OS. Validate the device tree against the implemented address map, prove
that reserved firmware memory is protected, and record board resources, bandwidth
and routed timing.

### OS05 — SBI firmware and single-core Linux boot

**Work:** Provide or port machine firmware implementing the SBI services required by
the selected Linux configuration. Load firmware, kernel, device tree and initramfs;
enter supervisor mode with the specified hart ID, device-tree pointer and disabled
address translation. Keep firmware sources and reproducible image-generation steps
separate from generated binaries.

**Acceptance:** Repeatedly boot the pinned Linux image to a UART shell on simulation
and the Tang Primer 25K. Exercise timer interrupts, user processes, virtual memory,
the initramfs and orderly shutdown or reset. Record boot time and workload behavior;
do not require caches or a second hart for completion.

### OS06 — Useful cached single-core performance

**Work:** Add optional instruction and data caches after the uncached OS path is
correct. Define cacheability metadata, write policy, eviction errors, DMA visibility,
FENCE and FENCE.I behavior, and cache maintenance needed by the selected platform.
Preserve uncached and small-core compositions through typed providers.

**Acceptance:** Verify replacement, aliases, self-modifying code, DMA visibility and
fault ordering. Compare Linux boot time and representative workloads against the
uncached core, together with FPGA resources and routed timing. Retain the caches only
when measured performance justifies their cost.

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
I05 atomic operations to the shared fabric, including indivisibility at memory and
reservation invalidation for LR/SC. Bus arbitration alone does not make a load
followed by a store atomic.

**Acceptance:** Test producer/consumer communication, mutual exclusion and memory
ordering under contention. For implemented atomic instructions, test competing
masters and failure paths. State the supported ISA and software assumptions.

### OS07 — Multicore OS mechanisms

**Constraint:** Independent harts and shared arbitration do not provide the firmware,
remote invalidation or cache behavior required by an SMP operating system.

**Work:** Add per-hart startup state, machine software interrupts and the SBI HSM,
IPI and remote-fence services required by the selected Linux target. Define coherent
private caches, a shared cache, or an explicitly qualified alternative; include
reservation invalidation, TLB shootdown, instruction visibility and DMA interaction.

**Acceptance:** Start, stop and restart secondary harts through SBI. Verify IPIs,
remote `FENCE.I`, remote `SFENCE.VMA`, TLB shootdowns, atomic contention and cache/DMA
visibility. Record whole-system resources and timing while keeping the uncached
bare-metal multicore configuration available.

### OS08 — Linux SMP qualification

**Work:** Extend the OS05 boot flow and device tree to the qualified hart topology.
Make boot-hart ownership, secondary-hart release, per-hart timers and interrupt
routing reproducible on the selected FPGA target.

**Acceptance:** Repeatedly boot Linux with all intended harts online in simulation
and on the Tang Primer 25K. Run concurrent process, locking, memory-pressure, IPI and
shared-I/O workloads without coherency failures. Claim SMP support only with the
pinned software versions, configuration, measurements and limitations recorded.

## Completion evidence

Close an implementation item only when its acceptance criteria are met. Record
relevant tests and FPGA measurements, including toolchain, clock target, resources
and workload where applicable. Keep generated builds and benchmark logs outside
this package; link to maintained evidence rather than checking large artifacts in.
Compile-time capability declarations complement behavioral tests and physical
qualification; they do not prove arbitrary compositions correct.
