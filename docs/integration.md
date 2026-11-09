# Integration contracts

## Memory ports

Both engines borrow separate instruction and data providers through
[`IRv32FetchPort`](../src/Sequential/IRv32FetchPort.lvt) and
[`IRv32LoadStorePort`](../src/Sequential/IRv32LoadStorePort.lvt). Each port carries
one outstanding aligned 32-bit word transaction in one clock domain. Fetch has
no write signals; write direction, byte enables and write data apply only to load/store.

1. Hold request, address, write direction, byte enable and write data stable until
   an edge with `ready = 1`.
2. Sample read data and error on that completion edge.
3. Deassert request for at least one edge before another transaction.

The provider holds completion values until request falls and performs an accepted
transaction exactly once. Reads ignore the byte enable; stores use little-endian
lanes, with lane zero selecting bits 7..0. A zero store mask has no effect.
Providers must reject errors before irreversible effects. There is no transaction
cancellation, retry or rollback protocol.

Use distinct providers for instruction and data, or supply explicit arbitration.
Passing one unarbitrated single-port memory to both ports is unsupported. Pipeline
instruction fetch must be side-effect-free; consuming device reads belong on the
data path. Clock-domain crossing also needs an explicit adapter.

## Memory and register storage

`RvFetchRom<WORDS, ADDRESS_BITS, STYLE, BASE>` provides instruction storage.
`RvLoadStoreRam<WORDS, ADDRESS_BITS, STYLE, BASE>` provides bounded data storage
and a separate provisioning channel. Full-word writes use one RAM operation;
partial writes use read/modify/write. Payload RAM survives reset and has no
promised initial contents. Initialize every location read, including untouched
bytes before a partial write.

Provision only while execution is disabled, the CPU is idle and requests have
drained. The provisioning channel does not arbitrate concurrent CPU access.
Restart resets CPU state; it does not reload firmware or clear platform memories.

`Rv32RegisterBank` supplies sequential register access.
`Rv32DualReadRegisterBank` supplies pipeline operand reads and an independent
write. Both enforce x0 and synchronous read timing. CPU initialization clears the
integer registers through their ports. Storage style requests mapping; inspect
implementation reports to determine the physical resources actually used.

## Run and monitor controls

[`IRv32ControlPort`](../src/Sequential/IRv32ControlPort.lvt) exposes run, step,
restart, status and retirement observation.

- After reset, wait for `idle`; register initialization must finish first.
- Hold `run` high for execution. Lower it and wait for `idle` before provisioning.
- With run low and the core idle and not halted, toggle `stepRequest`. Hold it
  until `stepAck` matches. One instruction attempt or accepted interrupt completes.
- Toggle `restartRequest` and hold it until `restartAck` matches. Restart drains
  work, clears CPU registers/CSR state and restores RESET_PC. It discards a pending
  step. Lower run first to remain paused after restart.

A provider that never responds can prevent pause, restart or interrupt service
from completing. Hardware reset must reset both sides of outstanding transactions;
it cannot undo effects already performed. These controls are an application monitor
interface, not the RISC-V architectural debug protocol.

`idle` means the core is paused and drained; `halted` indicates a diagnostic fault
stop. `retired` is a successful instruction event, with original PC/instruction and
destination/value. A zero destination denotes no integer write. Faults do not
retire. Machine trap events use `trapped` and its payload; payload values alone do
not identify an event. Sample event payloads with their pulses.

Machine interrupt inputs must be synchronous persistent levels. The application
owns device acknowledgement and synchronization. CPU restart clears CPU enables
but does not clear platform pending sources; reinitialize them before enabling
interrupt delivery. See [peripherals](peripherals.md).
