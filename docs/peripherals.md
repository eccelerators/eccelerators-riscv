# Timer and external interrupts

These components are owned by the application. They use the CPU's clock/reset
domain and the aligned word [memory protocol](integration.md). Their addresses
are platform choices, not a complete CLINT/ACLINT or PLIC implementation.

## Machine timer

`RvMachineTimer` exposes 64-bit mtime and mtimecmp. Its default MMIO base is
0x40000100 and must be 16-byte aligned.

| Offset | Read/write register |
|---:|---|
| 0 | mtime low |
| 4 | mtime high |
| 8 | mtimecmp low |
| 12 | mtimecmp high |

Time wraps modulo 2^64. `TICK_DIVISOR` selects clock edges per tick and `TICK_BITS`
bounds the divider. Hardware reset zeros time/divider and sets the deadline to
all ones. Time keeps advancing while the CPU is paused or restarted.

Writes honor byte enables. A nonzero-mask write to either time half suppresses
the whole time increment on that edge, preserving the other half; divider phase
continues. Comparison writes do not stop time. Read responses capture the pre-edge
value and hold it through completion. Invalid addresses fail before effects.

`timerPending` is the level `mtime >= mtimecmp`. Rearm by writing a future deadline;
there is no acknowledgement pulse. On RV32, write comparison low=0xffffffff, then
the new high word, then the new low word. Read time high/low/high and retry if the
high values differ. Account for an interrupt already accepted during rearming.

## External interrupt aggregation

`RvExternalInterrupts<SOURCES, BASE>` accepts 1..32 synchronous levels. Its default
16-byte window begins at 0x40000200.

| Offset | Access | Meaning |
|---:|---|---|
| 0 | Read | Raw pending bitmap |
| 4 | Read/write | Enable bitmap; reset zero |
| 8 | Read | Pending AND enable |
| 12 | Invalid | Reserved |

Enable writes honor byte lanes and mask unsupported bits. Writes to read-only or
invalid registers fail before effects. The external output remains asserted while
any enabled source is pending. There is no destructive claim read or aggregator
acknowledgement; the handler services the originating device. Persistent external
sources can starve timer service because external interrupts have CPU priority.

`RvInterruptEvent` retains a synchronous event until cleared. A simultaneous new
event wins over clear; repeated events coalesce. Use a FIFO/counter when every
occurrence matters. `RvInterruptSynchronizer` uses two registers for persistent
asynchronous levels, not narrow pulses or coherent multibit data. Preserve and
constrain the synchronizer in the target flow.

CPU restart clears CPU interrupt enables but leaves these platform components
unchanged. Whole-platform reset clears their state. Firmware should establish the
handler, device state and masks before enabling delivery.
