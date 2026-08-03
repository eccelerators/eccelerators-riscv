# Changelog

All notable changes to `Eccelerators.RiscV` are recorded here.

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
- Refresh the release-facing README with the Livt package-family heading icons,
  context about the Livt and Livt Agents experiment, and verified links to all
  supporting guides.
- Use `Livt.IO` 0.2.0 for the UART MMIO demo.
