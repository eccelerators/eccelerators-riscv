# Changelog

All notable changes to `Eccelerators.RiscV` are recorded here.

## Unreleased

### Added

- Add the read-only `RvPlatformInfo` device and stable value vocabulary for
  software-visible composition identity, ISA capabilities, execution engine,
  multiplier, register-file implementation and platform clock frequency.
- Add `IRv32IntegerPort` as the supported zero-state integer
  datapath boundary used by both sequential and pipeline engines.
- Add the general owned-provider `Rv32Core` composition, thin inherited sequential
  and pipeline specializations, a variable-latency custom-instruction port,
  recursive provider pairing, and the `Rv32XqdivInstruction` example.
- Add typed retirement-trace core and system wrappers as the custom-control
  composition example.
- Add `Rv32MachineCore` with sequential and pipeline specializations so qualified
  machine presets share one Zicsr/CSR owner and one interrupt/control topology.
- Add full RV32M decode, a compact iterative divider, structural multiplier/divider
  composition and named sequential and pipeline M presets.
- Add independently composable Zba, Zbb and Zbs decoder/integer overlays and named
  presets for the combined scalar bit-manipulation set.
- Add RV32E decoders, sixteen-entry register banks and named sequential and pipeline
  presets with reserved-register enforcement.
- Add Zifencei decoding and an ordered fetch-synchronization handshake, including
  pipeline invalidation of prefetched instructions.
- Add the `IRv32InstructionPort` framing boundary, RV32C integer decompression,
  cached cross-word instruction assembly and named RV32IC sequential and pipeline
  presets.
- Add complete RV32A word decode and AMO semantics, memory-owned LR/SC
  reservations, atomic RAM transactions and named RV32IA sequential and pipeline
  presets.

### Changed

- Move engine-facing signal contracts to `Core` and standard instruction decode,
  semantics and providers to the new `Isa` namespace. `Sequential` and `Pipeline`
  contain their controllers and general owned-provider compositions.
- Make both engines consume the integer interface and qualify an independent
  implementation through explicit sequential and pipeline compositions.
- Bind sequential or pipeline scheduling and its register-port contract through
  thin `Rv32Core` specializations instead of duplicating composition logic.
- Replace the Zmmul `DSP_MULTIPLY` Boolean with an explicit constrained multiplier
  provider type, and widen decoded operations to a five-bit family plus eight-bit
  provider-local operation.
- Generalize the engine multiplication boundary to `IRv32MPort`, preserving typed
  Zmmul providers while allowing full-M compositions. Make architectural register
  count an explicit engine specialization restricted to RV32I or RV32E.
- Make instruction framing and architectural alignment engine specializations;
  fixed-width cores retain the default word front end while RV32IC cores select
  halfword alignment and the compressed front end.
- Extend `IRv32LoadStorePort` with explicit atomic operation and acquire/release
  attributes. RAM implements atomics; MMIO devices reject them before effects.

### Removed

- Remove the unused scheduled-call `IRvDecoder` and `IRvExecutionUnit` contracts;
  supported extension paths now correspond to signal interfaces with consumers.

## [0.3.0] - 2026-11-08

### Added

- Explicit-provider `RvSystem<TCORE>` and default-memory `RvMemorySystem<TCORE>`.
- Combinational fetch and load/store window routers, and an independent buffered
  UART load/store adapter.

### Removed

- Remove the scheduled reference API from the package: the `Isa`, `Core` and
  `Bus` namespaces — `Rv32iWord`, `Rv32iConstants` (relocated to `Sequential`),
  `Rv32iInstructionFields`, `Rv32iImmediateDecoder`, the scheduled register
  files and storage, `Rv32iAlu`, `Rv32iBranchUnit`, `Rv32iLoadStoreUnit`,
  `Rv32iControlDecoder`, `Rv32iTrapController`, the `Step()`/`Run()` reference
  cores and their `IRv32InstructionBus`/`IRv32DataBus` fixtures, and the
  `Rv32iMinimalSystem` and `Rv32iUartMmioSystem` platform wrappers. The
  corresponding scheduled-layer tests are replaced by unit tests for the
  register bank, the signal-level decoder and RV32I semantics.

### Migration

- Use `RvMemorySystem<TCORE>()` for the former default-memory `RvSystem()`
  construction, or `RvSystem<TCORE>(fetch, loadStore)` for caller-owned devices.
- Engine parameters are now `<RESET_PC, MACHINE_TRAPS>`; typed decoders and
  execution/CSR providers determine supported features. Presets still select
  qualified compositions.
- Consumers of scheduled wrappers must migrate to signal-level run/step/restart
  handshakes. There is no drop-in replacement for `Step()`/`Run()`.

## [0.2.1] - 2026-11-08

### Changed

- Split the former `IRv32MemoryPort` into independent `IRv32FetchPort` and
  `IRv32LoadStorePort` providers; update sequential and pipeline engines and
  presets to use separate instruction and data connections.
- Replace `Rv32WordMemory` with `RvFetchRom` and `RvLoadStoreRam`; add
  `RvSystem<TCORE>` to compose a constructor-bound core with default fetch and
  load/store devices.
- Update the Livt.IO dependency to 1.8.1 and include package discovery
  metadata, README, changelog and license in the publication.

### Migration

- Existing consumers of `IRv32MemoryPort` and `Rv32WordMemory` must migrate
  their providers and wiring to the separate fetch and load/store contracts.
  The split changes the public API despite the patch-version release.

## [0.2.0] - 2026-11-07

This release adds signal-level, composable FPGA cores alongside the scheduled
RV32I reference API from 0.1.x.

### Added

- `Rv32SequentialEngine` and `Rv32PipelineEngine`, with explicit decoder,
  register-file, arithmetic, multiplier, CSR and instruction/data providers.
- Six named presets covering RV32I, RV32I + Zmmul, and machine-mode compositions
  for both execution engines. Applications can also assemble the same units
  explicitly through their signal interfaces.
- Synchronous single-port and dual-read register banks, with
  `REGISTER_FILE_STYLE` defaulting to `MemoryStyle.Block`, and bounded word RAM
  with a separate provisioning channel.
- Iterative and DSP-oriented providers for MUL, MULH, MULHSU and MULHU. The
  non-machine Zmmul presets and pipeline machine preset expose `DSP_MULTIPLY`;
  sequential DSP machine cores use explicit composition.
- Shared `Rv32ZicsrComposition` and access helpers, the six CSR instruction forms,
  machine CSR state, cycle/retirement counters, direct exception entry and MRET.
- Timer and external interrupt delivery at precise architectural boundaries,
  plus application-owned timer, interrupt aggregation, event-latch and
  synchronization components.
- Run/pause, single-step and restart controls, retirement/trap observation,
  ordered memory effects and pipeline hazard/drain handling.
- Elaboration checks for declared operation coverage and provider timing, plus
  functional tests for execution, storage, controls, multiplication, CSRs,
  traps and interrupts.

### Migration and scope

- New FPGA integrations should select a named preset or explicitly compose an
  engine. The existing scheduled reference cores remain available, but their
  `Step()`/`Run()` calls and blocking buses are separate from the new signal-level
  control and memory protocols. They are not interchangeable interfaces.
- The older reference core's `Rv32iRegisterStorage` selection remains distinct
  from `REGISTER_FILE_STYLE`. Storage hints preserve each interface's timing
  contract; physical RAM mapping must be checked for the target FPGA.
- Applications own firmware provisioning, memory maps, peripherals, clock/reset
  and interrupt acknowledgement. CPU restart does not reset platform devices.
- Use `rv32i`, `rv32i_zmmul` or `rv32i_zmmul_zicsr` with the `ilp32` ABI according
  to the selected core. Zmmul does not include division/remainder. Machine support
  is a documented subset; lower privilege modes, MMU, caches, architectural debug
  and Linux boot support are absent.
- The registry dependency remains `Livt.IO 1.2.0`. After publication, select
  `"Eccelerators.RiscV" = "0.2.0"` and run `livt sync`.

### Repository layout

- Retain `src`, `tests` and current user documentation under `docs`, together
  with package metadata, the README, license and changelog.
- Exclude development tools, generated output and benchmark material from the
  reusable package.
- Document public interfaces, storage choices, software targets and integration
  requirements.

### Validation

- A clean build of the retained source and functional suite passed 293 Livt tests,
  with zero failures or skips, during pre-release validation.
- Resource use and routed timing remain specific to the selected providers,
  parameters, tools and FPGA target; validate the complete application.

## [0.1.2] - 2026-10-20

### Added

- Compile-time `Rv32iRegisterStorage.Array`, `DistributedRam`, and `BlockRam`
  configuration on `Rv32iInjectedBusCore`.
- `IRv32iRegisterFile` and `Rv32iRamRegisterFile<STYLE>` with explicit runtime
  clearing and the same x0, bounds, and read/write completion contract.
- Register-storage tests across all three configurations and CPU execution/reset
  tests with both RAM styles. All 67 package tests pass.

### Compatibility

- Existing core constructors and wrappers retain array storage by default.
- Select `Rv32iInjectedBusCore<Rv32iRegisterStorage.DistributedRam>` in a parent
  application to request the RAM-backed implementation without patching sources.
- Register storage may change execution latency; no fixed-cycle guarantee is
  introduced. Synthesis determines actual RAM mapping from the requested style.
- The dependency remains registry `Livt.IO 1.2.0`.

## [0.1.1] - 2026-10-20

### Changed

- Require registry dependency `Livt.IO 1.2.0` instead of `0.2.0`.
- Migrate the UART MMIO fixture to `LoopbackUart<64, 64>` and the buffered
  `TryTransmit`, `TryReceive`, `GetReceiveCount`, and `ClearErrors` operations.
  Existing RISC-V bus/system helper signatures and the MMIO map are unchanged.
- Align README examples with the Livt Design Guide: tab indentation, documented
  ownership and functions, and explicit runtime program loading.
- Document scheduled call completion, CPU reset/provisioning, UART acceptance
  versus wire completion, queue/capture limits, and memory-mapping boundaries.

### Added

- Serial-loopback regression coverage for ordered delivery, a zero byte,
  receive occupancy, and empty receive behavior.

### Validation And Upgrade

- All 62 package tests passed with `Livt.IO 1.2.0`; none failed or were skipped.
- All three README examples compiled and passed behavior checks in an isolated
  consumer project against this source tree.
- Set the package dependency to `Eccelerators.RiscV = "0.1.1"` and run
  `livt sync` after publication. Consumers that explicitly pin `Livt.IO 0.2.0`
  must update that dependency to `1.2.0` and migrate any direct UART calls.
- This release retains the array-backed register file and memory fixtures.
  It does not include the application-specific RAM-backed register-file
  adaptation or claim FPGA fit/timing for a consuming application.

## [0.1.0] - 2026-08-03

- Add RV32I ISA helpers, execution primitives, and full local-memory reference
  core coverage.
- Add `Rv32iMinimalSystem` as the stable zero-based local-memory wrapper for
  tests, examples, and first integrations.
- Keep `Rv32iMinimalSystem` thin by delegating directly to the reference core's
  local memories instead of maintaining mirrored fixture storage.
- Add synchronous instruction/data bus contracts and simple ROM/RAM
  fixtures.
- Add `Rv32iBusCore` as the simple ROM/RAM wrapper around the canonical
  bus-injected execution engine.
- Add `Rv32iInjectedBusCore` for parent-owned instruction and data bus
  implementations, with simulation coverage for a caller-owned data bus.
- Add mapped RAM byte helper methods for the UART-MMIO demo bus/system.
- Remove the unused and unsupported `Rv32iUartMmioCore`; the supported UART path
  is `Rv32iUartMmioSystem` composed from `Rv32iInjectedBusCore` and mapped bus
  fixtures.
- Report misaligned `JAL`, `JALR`, and taken-branch targets on the originating
  instruction before committing PC or link-register side effects in all full
  core paths.
- Add firmware, memory-map, architecture, support-matrix, and testing
  documentation.
- Align the counter firmware linker layout with the packaged 256-byte ROM/RAM,
  reject unsupported initialized data and region overflow, and keep the UART
  address as a compile-time constant.
- Align core-maturity documentation around the full RV32I bus-core surface and
  clarify that the UART demonstration is compact only in platform scope.
- Reject data-bus widths other than byte, halfword, and word before address
  arithmetic, with regression coverage for simple and mapped RAM buses.
- Remove the unused `IsReady()` bus API and document same-call completion
  explicitly before publishing the initial interface contracts.
- Route all core variants through `Rv32iControlDecoder`, remove duplicated
  per-core decode helpers, and add an injected-bus instruction parity matrix.
- Consolidate architectural execution in `Rv32iInjectedBusCore`; make
  `Rv32iBusCore`, `Rv32iReferenceCore`, and `Rv32iUartMmioSystem` thin
  composition wrappers, and report misaligned data accesses consistently before
  issuing bus requests.
- Rename `Rv32iMultiCycleCore` to `Rv32iReferenceCore` because `Step()` executes
  one complete instruction rather than exposing a multi-cycle state machine.
- Add mnemonic annotations to the instruction matrices and full-core execution
  coverage for all signed and unsigned RV32I branch instructions.
- Remove the test-only `StoreForTest` core/platform API and unused immediate-kind
  and register-write state from `Rv32iControlDecoder` before the initial public
  release.
- Refresh the package overview and links to supporting guides.
- Use `Livt.IO` 0.2.0 for the UART MMIO demo.
