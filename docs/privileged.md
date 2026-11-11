# Privileged architecture

`Rv32PrivilegedArchitecture<HART_ID, INSTRUCTION_ALIGNMENT>` is the cohesive
state provider for the implemented M/S/U privileged subset. It owns privilege
mode, status stacks, delegation, machine and supervisor trap banks, interrupt
enables and pending views, cycle/time/retirement counters and eight PMP entries.
One clocked process owns those fields; combinational ports publish CSR legality,
trap redirects, interrupt selection, effective data privilege and PMP decisions.

The provider implements `IRv32SupervisorCsrPort`, which aggregates narrow
contracts rather than exposing implementation fields:

- `IRv32CsrPort` carries Zicsr query and commit.
- `IRv32TrapPort` carries precise entry/return commands, redirects and interrupt
  selection.
- `IRv32PrivilegeStatePort` publishes current mode, MPRV-selected data mode, SUM
  and MXR for future translation.
- `IRv32InstructionProtectionPort` and `IRv32DataProtectionPort` provide
  combinational physical-access policy.

`Rv32PrivilegedCore` owns one provider and shares it with the decoder chain,
engine and protection adapters. `Rv32PipelinePrivilegedCore` and
`Rv32SequentialPrivilegedCore` bind the engine-specific register contract.
`Rv32imacPipelinePrivilegedCore` and `Rv32imacSequentialPrivilegedCore` are the
qualified named compositions. They select RV32IMAC, halfword alignment, iterative
multiply/divide and block-oriented register storage by default.

Trap entry maps ECALL to its U, S or M architectural cause, applies `medeleg` or
`mideleg`, saves the aligned PC and updates the selected status stack atomically.
MRET and SRET restore mode and interrupt state. WFI waits until an enabled pending
interrupt appears; privilege and TW/TSR restrictions remain with the provider,
so the engines do not duplicate mode policy.

PMP implements eight priority-ordered OFF, TOR and NAPOT entries. Locked entries
cannot change, and a locked TOR entry also locks its predecessor address as the
lower bound. Atomics require read and write permission. M-mode bypasses an
unlocked matching entry and unmatched M-mode accesses; S/U accesses require a
matching permitted entry. The adapters reject denied requests before RAM, MMIO
or an external fabric observes them.

The platform supplies synchronous machine and supervisor interrupt levels and
the architectural time value. The provider exposes writable SSIP state while
also accepting an external SSIP level. Interrupt controllers, acknowledgement,
clock-domain crossing and memory arbitration remain platform responsibilities.

This implementation provides physical protection and privilege transitions. It
does not implement `satp`, Sv32 translation, page faults, `SFENCE.VMA`, caches or
standard platform interrupt-controller register maps. Those are separate
compositions in the operating-system roadmap so small machine-only and
privileged physical-address cores do not acquire unused hardware.
