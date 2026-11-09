# System composition

Choose a named core for a tested instruction set and execution engine. Construct
its providers explicitly when the default address map does not fit. These choices
are elaborated into hardware; there is no runtime factory or plugin registry.

## Default memories

```livt
system = new RvMemorySystem<Rv32iSequentialCore>()
```

`Eccelerators.RiscV.System.RvMemorySystem` owns separate 1024-word instruction
and data memories at address zero. Both request block RAM. Its provisioning
inputs are `fetchProgramWrite/Index/Data` and `dataProgramWrite/Index/Data`.
Keep `run` low, wait for `idle`, provision the image, then assert `run`.
RAM contents are not initialized by reset. Restart resets the core, not memories.

## Explicit address maps

The composition root declares and owns these fields; the following constructor
fragment connects an instruction ROM, RAM and UART:

```livt
fetch = new RvFetchRom()
ram = new RvLoadStoreRam()
uart = new BufferedUart<64, 16>(rx, tx)
uartDevice = new RvUartDevice(uart)
data = new Rv32LoadStoreBus<0, 4096, 0x40000000, 12, false>(ram, uartDevice)
system = new RvSystem<Rv32iPipelineCore>(fetch, data)
```

Import `Eccelerators.RiscV.System`, `.Storage`, `.Platform`, `.Presets` and
`Livt.IO`. The root provisions `fetch` and `ram` directly while the system is
paused and drained. The system owns only its core. Providers are borrowed
exclusively in one clock/reset domain; sharing needs an explicit arbiter.

`Rv32FetchBus` provides the same two-window routing on the fetch side. Routers
forward absolute addresses, so provider bases must match their windows. Windows
are half-open, nonempty and must not wrap. With `HAS_DEFAULT=false`, windows
must not overlap and an unmapped request completes with an error and no effects.
With `HAS_DEFAULT=true`, A wins and B receives every other address; B's configured
window is ignored. Its provider must reject unsupported addresses itself.
Cascading routers builds larger maps without changing the core.

`Port` names describe signal contracts. The concrete `Bus` components here are
combinational routers implementing those contracts, not scheduled method buses.
These are package protocols, not bus standards mandated by the RISC-V ISA.

## Control and machine inputs

All system wrappers forward execution control without adding a pipeline stage.
For a machine preset with platform interrupts use
`RvMachineSystem<Rv32iZmmulPipelineMachineCore>(fetch, data)` instead of `RvSystem`.
It requires `IRv32MachineControlPort` and exposes timer/external pending inputs:

```livt
system.timerPending = timer.timerPending
system.externalPending = interrupts.externalPending
```

Wire these synchronous persistent levels in the root's combinational process.
Tie unused pending inputs low. The core remains private so controls have exactly
one writer. `RvMemorySystem` is a convenience for systems without external
interrupt connections; machine platforms should construct their providers explicitly.

## UART registers

`RvUartDevice<BASE=0x40000000>` borrows `Livt.IO.IBufferedUart`; UART pins,
capacities and baud rate remain choices of the composition root.

| Offset | Access | Meaning |
|---|---|---|
| 0 | Write lane 0 | Enqueue the low byte; wait when TX is full |
| 4 | Read | Bit 0: TX space; bit 1: RX available; bit 2: receive error |
| 8 | Read | Consume one RX byte; zero when empty |

Check status to distinguish an empty RX FIFO from a received zero byte. Reads
ignore byte enables. Unsupported addresses/directions and TX writes enabling
other lanes fault before effects. A zero-mask TX write has no effect. Completion
is held until request falls, without repeating a FIFO operation. Hardware reset
must reset the adapter and UART together. Supervisor access to the borrowed UART
must be serialized with CPU access; the adapter is not an arbiter.

## Extending further

Compose a new root component around `RvSystem` for a custom map or peripheral.
Changing a similarly named inherited field does not reconnect a core already
constructed by a base component. Explicit construction makes ownership and
routing reviewable. For custom instructions or CSR behavior, assemble the engine's
typed providers as described in [custom components](custom-components.md).
