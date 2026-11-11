# Atomic memory contract

RV32A atomics cross `IRv32LoadStorePort` as explicit transactions. The core
provides an operation, operand, address and the architectural acquire/release
attributes. The memory system owns mutation and reservation state. A core must
never emulate an AMO as an externally visible load followed by a store.

`RvLoadStoreRam` is the qualified single-requester implementation. It supports
LR.W, SC.W and every RV32A word AMO. LR returns the loaded word and establishes a
reservation after a successful access. SC always clears that requester's
reservation; it returns zero and writes when the reservation matches, or returns
one without a write otherwise. AMOs return the original word and commit their
new word indivisibly. Address or operation errors complete before memory effects.

The reservation granule is currently one aligned 32-bit word. An implementation
may conservatively invalidate more reservations than strictly necessary. The RAM
clears its reservation on any successful store or AMO and on host provisioning.
Reset also clears reservation state while retaining memory payload.

## Ordering

Both engines are single-issue at the data-memory boundary. They admit one data
transaction at a time and retire it before issuing a younger one, so the current
RAM needs no extra fence state for `aq` or `rl`. The attributes remain present on
the port because a future cache, bridge or reordered fabric must enforce them:

- `release` orders earlier memory effects before the atomic transaction;
- `acquire` prevents later memory effects from becoming visible before it;
- completion still follows the normal held-request/held-response protocol.

## Multiple masters

A multi-hart or DMA-capable system must place all competing accesses behind one
atomicity owner. That owner identifies the requesting master, serializes AMO
read/modify/write operations against every other access, and keeps a reservation
per requester. A successful overlapping store or AMO from any hart, DMA engine or
debug/provisioning master invalidates affected reservations before a later SC is
decided.

An address router may forward atomic attributes, but routing alone does not make
separate load and store transactions atomic. A bridge may implement atomics in
the shared fabric or pass them to a downstream memory protocol with equivalent
guarantees. Devices without atomic support must return an error before effects.
The package must not claim SMP support until the future shared fabric is tested
with competing LR/SC, AMO counters, DMA invalidation and forward-progress cases.
