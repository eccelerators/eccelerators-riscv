# Machine support

Machine presets combine RV32I, Zmmul, Zicsr, machine exceptions/MRET and timer and
external interrupts. This is a machine-only subset, not a complete privileged
platform. Lower privilege modes, delegation, PMP, software interrupts, WFI, PLIC,
MMU and architectural debug are absent from these compact presets. Select the
[privileged architecture](privileged.md) presets for implemented M/S/U,
delegation, software-interrupt state, WFI and PMP support.

## CSR instructions and ownership

`Rv32ZicsrComposition` owns a Zicsr decoder overlay and `Rv32MachineCsrs`, exposing
`IRv32DecodePort` and `IRv32CsrPort` directly. The engine owns the instruction's
register write and retirement; the CSR provider alone owns CSR state. Access
legality is checked before commit. An illegal access changes neither destination
nor CSR and does not retire.

All six CSR forms return the old value when a read is requested. CSRRW/I suppress
reading for rd=x0. CSRRS/RC suppress writing only for encoded rs1=x0; a different
register holding zero still requests a write. Immediate set/clear suppress writing
for zimm=0. Unknown addresses and writes to read-only addresses are illegal.

`commit` requests one access on its asserted edge. It is not a held ready/valid
transaction. The destination samples old CSR data on that same edge. Custom
providers must preserve this atomic contract.

## CSR map

Addresses below are hexadecimal. Unlisted addresses are illegal. WARL fields
normalize written values to supported settings.

| Address | CSR | Behavior |
|---|---|---|
| 300 | mstatus | MPP fixed M; MIE/MPIE writable, mask 0x88 |
| 301 | misa | Fixed WARL 0x40000100, RV32 and I; writes ignored |
| 304 / 344 | mie / mip | Enabled timer bit 7 and external bit 11; unsupported bits zero; pending bits hardware-owned |
| 305 | mtvec | Direct only, low two bits zero |
| 306 | mcounteren | Fixed zero |
| 310 | mstatush | Fixed zero |
| 320 | mcountinhibit | CY and IR writable, mask 5 |
| 340 | mscratch | Full 32-bit storage |
| 341 | mepc | Low two bits zero |
| 342 / 343 | mcause / mtval | Software storage and trap-entry payload |
| B00 / B80 | mcycle / mcycleh | Low/high halves of a 64-bit cycle counter |
| B02 / B82 | minstret / minstreth | Low/high halves of a 64-bit retirement counter |
| B03–B1F / B83–B9F | mhpmcounter3–31 and high halves | Legal, hardwired zero |
| 323–33F | mhpmevent3–31 | Legal, hardwired zero |
| F11–F13 | mvendorid / marchid / mimpid | Read-only zero |
| F14 | mhartid | Read-only HART_ID parameter; named presets use zero |
| F15 | mconfigptr | Read-only zero |

`Rv32MachineCsrs<HART_ID, TIMER_INTERRUPTS, EXTERNAL_INTERRUPTS>` defaults to hart
zero with interrupts disabled. Named machine presets enable both interrupt classes.
Zmmul does not set misa.M. User counter aliases are absent; this is not a Zicntr
claim. Time is provided by the platform timer, not by a time CSR.

`mcycle` counts clocks, including pauses, unless inhibited. `minstret` counts
successful commits, excluding traps. A counter-half write suppresses that counter's
increment on the writing edge and preserves the other half. An mcountinhibit write
uses the old mask on its own edge. Reset/restart clear CSR state and counters;
cycles may already have accumulated while the register file is initialized.

## Exceptions and return

Trap entry saves the original instruction PC in mepc, sets mcause/mtval, copies
MIE into MPIE, clears MIE, and redirects to direct mtvec. MRET restores MIE from
MPIE, sets MPIE and returns to mepc without adding four. A handler chooses whether
to retry or advance mepc. MRET retires; exception entry does not.

| Cause | Condition | mtval |
|---:|---|---|
| 0 | Misaligned taken branch/jump target | Bad target |
| 1 | Failed instruction fetch | Fetch address |
| 2 | Illegal instruction/CSR access | Instruction word |
| 3 | EBREAK | Instruction PC |
| 4 / 6 | Misaligned load/store | Effective address |
| 5 / 7 | Failed load/store | Effective address |
| 11 | ECALL | Zero |

Faulting instructions cannot commit register/CSR writes. Memory providers must
reject failures before effects. There is no hidden exception stack; a nested fault
overwrites saved state. Software must save it before fault-prone handler work.
CSR command priority is reset/synchronous clear, entry, return, then explicit write.

## Interrupts and control

Timer cause is 0x80000007; external cause is 0x8000000B. External has priority when
both are eligible. CPU delivery requires the class enable and mstatus.MIE. Pending
bits reflect hardware even while masked; writing mip does not acknowledge devices.

The engine accepts interrupts at a precise boundary after older work completes.
An older synchronous exception wins. Entry saves the architectural resume PC and
mtval zero. The pipeline discards younger work and drains speculative fetches;
no younger data or CSR effect may escape. A withdrawn level after acceptance does
not cancel the accepted trap. Unbounded provider latency means unbounded delivery
latency.

A step may complete at handler entry without retiring an instruction. Machine trap
entry reports `trapped`, not `halted`. Restart drains work, clears CPU/CSR state and
restores RESET_PC, but leaves platform devices running. See [integration](integration.md)
and [peripherals](peripherals.md) for the remaining platform obligations.
